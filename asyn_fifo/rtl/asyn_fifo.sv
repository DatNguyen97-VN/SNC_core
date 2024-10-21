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
//          0.2.1   - Oct 16th 2024
//                  + Added Gray Code Comparison and full/empty-flags
//          0.2.2   - Oct 17th 2024
//                  + The reset signals change to master and partial reset signals
//                  + Added re-transmission feature
//          0.3.0   + Oct 21st 2024
//                  + big endian/little endian 
//                  + input/output width bus matching 
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
    input  logic                   mrst_n_i,
    input  logic                   prst_n_i,
    input  logic                   wr_i,
    input  logic                   rd_i,
    input  logic                   clk_wr_i,
    input  logic                   clk_rd_i,
    input  logic                   daf_i,
    input  logic                   oe_i,
    input  logic                   re_trans_i,
    input  logic                   big_en_i,
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
    logic [$clog2(FIFO_ENTRIES):0] wbin;
    logic [$clog2(FIFO_ENTRIES):0] wbin_next;
    logic [$clog2(FIFO_ENTRIES):0] rbin;
    logic [$clog2(FIFO_ENTRIES):0] rbin_next;
    // multi-level synchronation pointer
    logic [$clog2(FIFO_ENTRIES):0] wptr_syn1, wptr_syn2;
    logic [$clog2(FIFO_ENTRIES):0] rptr_syn1, rptr_syn2;
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
    // buffer register
    logic empty_buffer1;
    logic empty_buffer2;
    logic full_buffer1;
    logic full_buffer2;
    // asynchronous status signals
    logic msb_diff;
    logic lsb_equal;
    logic syn_full;
    logic syn_empty;
    // system reset
    logic reset;
    // normal retranmission signals
    logic       retrans_en;
    logic [2:0] state_sr;
    logic       retrans_empty;
    logic       msb_rbin;
    // big endian/little endian
    logic big_en_step;
    logic big_en_offset;
    // Almost-full/almost-empty flag signals
    const int default_offset = FIFO_ENTRIES >> 2;
    logic [$clog2(FIFO_ENTRIES)-2:0] offset;
    logic [$clog2(FIFO_ENTRIES)-2:0] user_offset;
    logic [$clog2(FIFO_ENTRIES):0]   data_filled_read;
    logic [$clog2(FIFO_ENTRIES):0]   data_filled_write;
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
    /*            RESET LOGIC          */
    /* ------------------------------- */
    assign reset = mrst_n_i & prst_n_i;

    /* ------------------------------- */
    /* WRITE POINTER AND CONTROL BLOCK */
    /* ------------------------------- */
    assign fifo_we = wr_i & full_buffer2;
    //
    always_ff @( posedge clk_wr_i or negedge reset ) begin : write_pointer
      if (!reset) begin
        wbin <= '0;
      end else if (big_en_offset) begin 
        wbin <= wbin + big_en_step;
      end else if (fifo_we) begin
        wbin <= wbin_next;
      end
    end : write_pointer

    // increate wbin_next by 1
    assign wbin_next = wbin + 1'b1;

    //
    always_ff @( posedge clk_wr_i or negedge reset ) begin : blockName
      if (!reset) begin
        big_en_step <= 0;
      end else begin
        big_en_step <= ~big_en_step;
      end
    end

    // Multilevel synchronization for write pointer
    always_ff @( posedge clk_rd_i or negedge reset) begin : wptr_syn_1
      if (!reset) begin
        wptr_syn1 <= '0;
      end else if (fifo_we) begin
        wptr_syn1 <= (wbin_next >> 1) ^ wbin_next;
      end
    end : wptr_syn_1
    //
    always_ff @( posedge clk_rd_i or negedge reset) begin : wptr_syn_2
      if (!reset) begin
        wptr_syn2 <= '0;
      end else begin
        wptr_syn2 <= wptr_syn1;
      end
    end : wptr_syn_2

    /* ------------------------------- */
    /*  READ POINTER AND CONTROL BLOCK */
    /* ------------------------------- */
    assign fifo_re = rd_i & fifo_empty;
    //
    always_ff @( posedge clk_rd_i or negedge reset) begin : read_pointer
      if (!reset) begin
        rbin <= '0;
      end else if (retrans_en) begin
        // set msb value into rbin at retransmission mode
        rbin <= {msb_rbin, {$bits(rbin)-1{1'b0}}};
      end else if (fifo_re) begin
        rbin <= rbin_next;
      end
    end : read_pointer

    // increate rbin_next by 1
    assign rbin_next = rbin + 1'b1;

    // Multilevel synchronization for read pointer
    always_ff @( posedge clk_wr_i or negedge reset) begin : rptr_syn_1
      if (!reset) begin
        rptr_syn1 <= '0;
      end else if (fifo_re) begin
        rptr_syn1 <= (rbin_next >> 1) ^ rbin_next;
      end
    end : rptr_syn_1
    //
    always_ff @( posedge clk_wr_i or negedge reset) begin : rptr_syn_2
      if (!reset) begin
        rptr_syn2 <= '0;
      end else begin
        rptr_syn2 <= rptr_syn1;
      end
    end : rptr_syn_2

    /* -------------------- */
    /* DUAL-PORT SRAM BLOCK */
    /* -------------------- */
    always_ff @( posedge clk_wr_i ) begin : write_data
    if (fifo_we && reset) begin
      mem_array[wbin[$bits(wbin)-2:0]] <= data_in_i;
    end
    end : write_data
    //
    always_ff @( posedge clk_rd_i or negedge reset ) begin : read_data
      if (!reset) begin
        data_latch <= '0;
      end else if (fifo_re) begin
        data_latch <= mem_array[rbin[$bits(rbin)-2:0]];
      end
    end : read_data

    /* --------------------------- */
    /*   CONFIGURATION REGISTERS   */
    /*---------------------------- */
    always_ff @(negedge mrst_n_i) begin : offset_registers
      if (!mrst_n_i) begin
        big_en_offset <= big_en_i;
      end
    end : offset_registers

    /* ------------------ */
    /* DATA LATCH OUTPUT  */
    /*------------------- */
    assign data_out_o = oe_i ? data_latch : 'z;

    /*------------------- */
    /* STATUS FLAGS LOGIC */
    /*------------------- */

    // Calculate the recorded capacity of FIFO ---------------------------------------------------
    // -------------------------------------------------------------------------------------------

    // Data is filled into FIFO from read clock domain
    // convert gray to binary
    logic [$bits(wptr_syn2)-1:0] bin_wptr_syn2;
    always_comb begin : wgray2bin
      bin_wptr_syn2[$bits(wptr_syn2)-1] = wptr_syn2[$bits(wptr_syn2)-1];
      //
      for (int i = $bits(wptr_syn2)-2; i >= 0; i--) begin
        bin_wptr_syn2[i] = bin_wptr_syn2[i+1] ^ wptr_syn2[i];
      end
    end : wgray2bin
    // compute data
    assign data_filled_read  = bin_wptr_syn2 + ~rbin + 1'b1;

    // Data is filled into FIFO from write clock domain
    // convert gray to binary
    logic [$bits(rptr_syn2)-1:0] bin_rptr_syn2;
    always_comb begin : rgray2bin
      bin_rptr_syn2[$bits(rptr_syn2)-1] = rptr_syn2[$bits(rptr_syn2)-1];
      //
      for (int i = $bits(rptr_syn2)-2; i >= 0; i--) begin
        bin_rptr_syn2[i] = bin_rptr_syn2[i+1] ^ rptr_syn2[i];
      end
    end : rgray2bin
    // compute data
    assign data_filled_write = wbin + ~(bin_rptr_syn2) + 1'b1;

    // Full/Empty-Signals ------------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    // check full/empty
    assign msb_diff = wbin[$bits(wbin)-1] ^ bin_rptr_syn2[$bits(bin_rptr_syn2)-1];
    assign lsb_equal = wbin[$bits(wbin)-2:0] == bin_rptr_syn2[$bits(bin_rptr_syn2)-2:0];
    //
    assign syn_full  = ~(msb_diff & lsb_equal);
    assign syn_empty = ~(rbin == bin_wptr_syn2);

    // buffer of full signal
    always_ff @(posedge clk_wr_i or negedge reset or negedge syn_full) begin : full_buffer
      if (!reset) begin
        {full_buffer2, full_buffer1} <= 2'b11;
      end else if (!syn_full) begin
        {full_buffer2, full_buffer1} <= 2'b00;
      end else begin
        {full_buffer2, full_buffer1} <= {full_buffer1, 1'b1};
      end
    end : full_buffer

    // buffer of empty signal
    always_ff @(posedge clk_rd_i or negedge reset or negedge syn_empty) begin : empty_buffer
      if (!reset) begin
        {empty_buffer2, empty_buffer1} <= 2'b00;
      end else if (!syn_empty) begin
        {empty_buffer2, empty_buffer1} <= 2'b00;
      end else begin
        {empty_buffer2, empty_buffer1} <= {empty_buffer1, 1'b1};
      end
    end : empty_buffer

    // Retransmit Operation ----------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    // Normal Retransmit
    always_ff @( posedge clk_rd_i or negedge reset ) begin : normal_retransmit
      if (!reset) begin
        retrans_en    <= 1'b0;
        state_sr      <= 3'b000;
        retrans_empty <= 1'b0;
        msb_rbin      <= 1'b0;
      end else begin
        // set-up state
        if (!(rd_i || wr_i || re_trans_i) && (data_filled_read < FIFO_ENTRIES-1) && !state_sr) begin
          retrans_en    <= 1'b1;
          state_sr      <= 3'b111;
          retrans_empty <= 1'b0;
          // read pointer is always stay behind write pointer
          msb_rbin      <=  empty_buffer2 ? rbin[$bits(rbin)-1] : 
                           (rbin[$bits(rbin)-2:0] == 0) ? ~rbin[$bits(rbin)-1] : rbin[$bits(rbin)-1];
        end else begin
          // re-transmission state
          case (state_sr)
            3'b111  : begin retrans_empty <= 1'b1; retrans_en <= 1'b0; end
            3'b110  : begin retrans_empty <= 1'b1; retrans_en <= 1'b0; end
            3'b100  : begin retrans_empty <= 1'b1; retrans_en <= 1'b0; end
            default : begin retrans_empty <= 1'b0; retrans_en <= 1'b0; end
          endcase
          //
          state_sr <= state_sr << 1;
        end
      end
    end : normal_retransmit

    // mode arbiter for full/empty-flags
    assign fifo_empty = |state_sr ? retrans_empty : empty_buffer2;

endmodule