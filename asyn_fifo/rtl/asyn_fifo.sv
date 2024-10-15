//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dat Nguyen
// 
// Create Date: 10/15/2024
// Design Name: asyn fifo
// Module Name: asyn fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This asynchronous FIFO with the configuration parameters
// 
// Dependencies: 
// 
// Revision:
//          0.1.0   - Oct 15th 2024
//                  + Initial version.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef  _INCL_DEFINITIONS
  `define _INCL_DEFINITIONS
  // include file
`endif // _INCL_DEFINITIONS

module asyn_fifo #(
    parameter FIFO_ENTRIES = 65536,
    parameter DATA_WIDTH   = 18
) (
    input  logic                   wrst_n_i,
    input  logic                   rrst_n_i,
    input  logic                   wr_i,
    input  logic                   rd_i,
    input  logic                   clk_wr_i,
    input  logic                   clk_rd_i,
    input  logic                   daf_i,
    input  logic                   oe_i,
    output logic                   fifo_empty_o,
    output logic                   fifo_full_o,
    output logic                   half_full_o,
    output logic                   af_ae_o,
    input  logic [DATA_WIDTH-1:0]  data_in_i,
    output logic [DATA_WIDTH-1:0]  data_out_o
);
    // Internal Variable -------------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    // pointer
    logic [$clog2(FIFO_ENTRIES): 0] wprt;
    logic [$clog2(FIFO_ENTRIES): 0] wbin;
    logic [$clog2(FIFO_ENTRIES): 0] wbin_next;
    logic [$clog2(FIFO_ENTRIES): 0] syn_wprt1;
    logic [$clog2(FIFO_ENTRIES): 0] syn_wprt2;
    logic [$clog2(FIFO_ENTRIES): 0] rprt;
    logic [$clog2(FIFO_ENTRIES): 0] rbin;
    logic [$clog2(FIFO_ENTRIES): 0] rbin_next;
    logic [$clog2(FIFO_ENTRIES): 0] syn_rprt1;
    logic [$clog2(FIFO_ENTRIES): 0] syn_rprt2;
    // memory
    logic [DATA_WIDTH-1:0] mem_array [FIFO_ENTRIES-1:0]; // data storage
    // enable pointer
    logic fifo_re;
    logic fifo_we;
    // status flag signals
    logic fifo_full;
    logic fifo_empty;
    logic half_full;
    logic af_ae;
    // register buffer
    logic empty_buffer1;
    logic empty_buffer2;
    logic empty_buffer3;
    logic full_buffer1;
    logic full_buffer2;
    // reset signal og buffer
    logic empty_buff_rst_n;
    logic full_buff_rst_n;
    // Almost-full/almost-empty flag signals
    const int default_offset = FIFO_ENTRIES >> 2;
    logic [$clog2(FIFO_ENTRIES)-2:0] offset;
    logic [$clog2(FIFO_ENTRIES)-2:0] user_offset;
    logic [$clog2(FIFO_ENTRIES):0]   data_filled;
    // Data latch signals
    logic [DATA_WIDTH-1:0] data_latch;


    // Pre-validation ----------------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    initial begin
    /* information about a range of X value */
      assert (0)
      else $info("SYN FIFO CONFIG NOTE: X value of valid range [1..%0d].", FIFO_ENTRIES/2 - 1);
    /*Check default value of Offset */
      assert (DATA_WIDTH >= ($clog2(FIFO_ENTRIES)-1))
      else $error("Size of data_in_i in <DATA_WIDTH> should be great than or equal: %0d to represent a default value of Offset(x)", $clog2(FIFO_ENTRIES)-1);
    /* 2^n fifo entries check */
      if (((FIFO_ENTRIES & (FIFO_ENTRIES-1)) == 0) && (FIFO_ENTRIES >= 4)) begin
        $info("SYN FIFO CONFIG NOTE: Number of fifo entries is %0d and data width is %0d", FIFO_ENTRIES, DATA_WIDTH);
      end else begin
        $error("SYN FIFO CONFIG ERROR! Number of fifo entries in <FIFO_ENTRIES> has to be a power of two, min is 4.");
      end
    end

    /* ------------------------------- */
    /* WRITE POINTER AND CONTROL BLOCK */
    /* ------------------------------- */
    assign fifo_we = wr_i & fifo_full & full_buffer2;
    //
    always_ff @( posedge clk_wr_i or negedge wrst_n_i ) begin : write_pointer
      if (!wrst_n_i) begin
        {wbin, wprt} <= '0;
      end else if (fifo_we) begin
        {wbin, wprt} <= {wbin_next, (wbin_next >> 1) ^ wbin_next}; // wbin_next >> 1: keeps MSB, LSB is XOR
      end
    end : write_pointer

    // increate wbin_next by 1
    assign wbin_next = wbin + 1'b1;
  
    // Read domain to Write domain synchronizer
    always_ff @( posedge clk_wr_i or negedge wrst_n_i ) begin : r2w_synchronizer
      if (!wrst_n_i) begin
        {syn_wprt2, syn_wprt1} <= '0;
      end else begin
        {syn_wprt2, syn_wprt1} <= {syn_wprt1, rprt};
      end
    end : r2w_synchronizer

    /* ------------------------------- */
    /*  READ POINTER AND CONTROL BLOCK */
    /* ------------------------------- */
    assign fifo_re = rd_i & fifo_empty & empty_buffer3;
    //
    always_ff @( posedge clk_rd_i or negedge rrst_n_i ) begin : read_pointer
      if (!rrst_n_i) begin
        {rbin, rprt} <= '0;
      end else if (fifo_re) begin
        {rbin, rprt} <= {rbin_next, (rbin_next >> 1) ^ rbin_next}; // rbin_next >> 1: keeps MSB, LSB is XOR
      end
    end : read_pointer

    // increate rbin_next by 1
    assign rbin_next = rbin + 1'b1;
  
    // Write domain to Read domain synchronizer
    always_ff @( posedge clk_rd_i or negedge rrst_n_i ) begin : w2r_synchronizer
      if (!rrst_n_i) begin
        {syn_rprt2, syn_rprt1} <= '0;
      end else begin
        {syn_rprt2, syn_rprt1} <= {syn_rprt1, wprt};
      end
    end : w2r_synchronizer

    /* -------------------- */
    /* DUAL-PORT SRAM BLOCK */
    /* -------------------- */
    always_ff @( posedge clk_wr_i or negedge wrst_n_i ) begin : write_data
    if (fifo_we && wrst_n_i) begin
      mem_array[wbin[$bits(wbin)-2:0]] <= data_in_i;
    end
    end : write_data
    //
    always_ff @( posedge clk_rd_i or negedge rrst_n_i ) begin : read_data
      if (fifo_re && rrst_n_i) begin
        data_latch <= mem_array[rbin[$bits(rbin)-2:0]];
      end
    end : read_data

    /* ------------------ */
    /* DATA LATCH OUTPUT  */
    /*------------------- */
    always_latch begin
      if (oe_i) begin
        data_out_o = data_latch;
      end else begin
        data_out_o = 'z;
      end
    end

    /*------------------- */
    /* STATUS FLAGS LOGIC */
    /*------------------- */
    // internal empty signal
    assign fifo_empty = ~(rprt == syn_rprt2);
    //
    assign empty_buff_rst_n = rrst_n_i & fifo_empty;
    //
    always_ff @( posedge clk_rd_i or negedge empty_buff_rst_n) begin : empty_buffer
        if (!empty_buff_rst_n) begin
            {empty_buffer3, empty_buffer2, empty_buffer1} <= '0;
        end else begin
            {empty_buffer3, empty_buffer2, empty_buffer1} <= {empty_buffer2, empty_buffer1, 1'b1};
        end
    end

    // internal full signal
    assign fifo_full = ~(wprt == {~syn_wprt2[$bits(syn_wprt2)-1:$bits(syn_wprt2)-2], syn_wprt2[$bits(syn_wprt2)-3:0]});
    //
    assign full_buff_rst_n = wrst_n_i & fifo_full;
    //
    always_ff @( posedge clk_wr_i or negedge full_buff_rst_n ) begin : full_buffer
      if (!full_buff_rst_n) begin
        {full_buffer2 , full_buffer1} <= '0;
      end else begin
        {full_buffer2 , full_buffer1} <= {full_buffer1 , 1'b1};
      end
    end : full_buffer

    // Half-full compute

endmodule