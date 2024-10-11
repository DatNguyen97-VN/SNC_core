//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dat Nguyen
// 
// Create Date: 10/03/2024
// Design Name: syn fifo
// Module Name: syn fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This synchronous FIFO with the configuration parameters
// 
// Dependencies: 
// 
// Revision:
//          0.1.0   - Oct 3rd 2024
//                  + Initial version.
//                  + added multilevel synchronous for a fifo_full/fifo_empty signal
//          0.2.0   - Oct 5th 2024
//                  + added pre-validation for FIFO_ENTRIES parameter
//                  + implemented Half-full and Almost-full/almost-empty flag
//          0.2.1   - Oct 6th 2024
//                  + additionally implement the fifo_full/fifo_empty status output is triggered by a synchronous signal
//                  + Modified Half-full flag
//          0.3.0   - Oct 8th 2024
//                  + additionally implement the data output with latch
//                  + Freezing Version
//          1.0.0   - Oct 11th 2024
//                  + Released Version
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef  _INCL_DEFINITIONS
  `define _INCL_DEFINITIONS
  // include file
`endif // _INCL_DEFINITIONS

module syn_fifo #(
  parameter FIFO_ENTRIES   = 1024,
  parameter DATA_WIDTH     = 18
) (
  input  logic                   rst_n_i,
  input  logic                   wr_i,
  input  logic                   rd_i,
  input  logic                   clk_rd_i,
  input  logic                   clk_wr_i,
  input  logic                   daf_i,
  input  logic                   oe_i,
  output logic                   fifo_empty_o,
  output logic                   fifo_full_o,
  output logic                   half_full_o,
  output logic                   af_ae_o,
  input  logic [DATA_WIDTH-1:0]  data_in_i,
  output logic [DATA_WIDTH-1:0]  data_out_o
);
  // internal signal
  logic [$clog2(FIFO_ENTRIES):0] w_pointer;
  logic [$clog2(FIFO_ENTRIES):0] r_pointer;
  logic [DATA_WIDTH-1:0] mem_array [FIFO_ENTRIES-1:0]; // data storage
  // status flag signals
  logic msb_diff;
  logic lsb_equal;
  logic fifo_re;
  logic fifo_we;
  logic fifo_full;
  logic fifo_empty;
  logic half_full;
  logic af_ae;
  // synchronization signals
  logic full_syn_stage1;
  logic full_syn_stage2;
  logic empty_syn_stage1;
  logic empty_syn_stage2;
  logic empty_syn_stage3;
  // Almost-full/almost-empty flag signals
  const int default_x = FIFO_ENTRIES >> 2;
  logic [$clog2(FIFO_ENTRIES)-2:0] offset;
  logic [$clog2(FIFO_ENTRIES)-2:0] x_reg;
  logic [$clog2(FIFO_ENTRIES):0]   data_filled;
  // Data latch signals
  logic [DATA_WIDTH-1:0] data_latch;
  
  /* Pre-validation */
  initial begin
  /* information about a range of X value */
    assert (0)
    else $info("SYN FIFO CONFIG NOTE: X value of valid range [1..%0d].", FIFO_ENTRIES/2 - 1);
  /*Check default value of X */
    assert (DATA_WIDTH >= ($clog2(FIFO_ENTRIES)-1))
    else $error("Size of data_in_i in <DATA_WIDTH> should be great than or equal: %0d to represent a value of Default X", $clog2(FIFO_ENTRIES)-1);
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
  assign fifo_we = wr_i & ((~fifo_full) & full_syn_stage2);
  //
  always_ff @( posedge clk_wr_i or negedge rst_n_i ) begin : write_pointer
    if (!rst_n_i) begin
      w_pointer <= '0;
    end else if (fifo_we) begin
      w_pointer <= w_pointer + 1'b1;
    end
  end : write_pointer

  // Multilevel synchronization for full signal
  always_ff @( posedge clk_wr_i or posedge fifo_full ) begin : multilevel_full_syn
    if (!rst_n_i) begin
      {full_syn_stage2, full_syn_stage1} <= {full_syn_stage1, 1'b0};
    end else if (fifo_full) begin
      {full_syn_stage2, full_syn_stage1} <= 2'b00;
    end else begin
      {full_syn_stage2, full_syn_stage1} <= {full_syn_stage1, 1'b1};
    end
  end : multilevel_full_syn

  /* ------------------------------ */
  /* READ POINTER AND CONTROL BLOCK */
  /* ------------------------------ */
  assign fifo_re = rd_i & (~fifo_empty) & empty_syn_stage3;
  //
  always_ff @( posedge clk_rd_i or negedge rst_n_i ) begin : read_pointer
    if (!rst_n_i) begin
      r_pointer <= '0;
    end else if (fifo_re) begin
      r_pointer <= r_pointer + 1'b1;
    end
  end : read_pointer

  // Multilevel synchronization for empty signal
  always_ff @( posedge clk_rd_i or posedge fifo_empty) begin : multilevel_empty_syn
    if (!rst_n_i) begin
      {empty_syn_stage3, empty_syn_stage2, empty_syn_stage1} <= {empty_syn_stage2, empty_syn_stage1, 1'b0};
    end else if (fifo_empty) begin
      {empty_syn_stage3, empty_syn_stage2, empty_syn_stage1} <= 3'b000;
    end else begin
      {empty_syn_stage3, empty_syn_stage2, empty_syn_stage1} <= {empty_syn_stage2, empty_syn_stage1, 1'b1};
    end
  end : multilevel_empty_syn

  /* -------------------- */
  /* DUAL-PORT SRAM BLOCK */
  /* -------------------- */
  always_ff @( posedge clk_wr_i ) begin : write_data
    if (fifo_we && rst_n_i) begin
      mem_array[w_pointer[$bits(w_pointer)-2:0]] <= data_in_i;
    end
  end : write_data
  //
  always_ff @( posedge clk_rd_i ) begin : read_data
    if (fifo_re) begin
      data_latch <= mem_array[r_pointer[$bits(r_pointer)-2:0]];
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
  // Full and Empty internal signal
  assign msb_diff   = w_pointer[$bits(w_pointer)-1] ^ r_pointer[$bits(r_pointer)-1];
  assign lsb_equal  = (w_pointer[$bits(w_pointer)-2:0] == r_pointer[$bits(r_pointer)-2:0]);
  assign fifo_full  = msb_diff & lsb_equal;
  assign fifo_empty = (~msb_diff) & lsb_equal;

  // Half-full compute
  assign half_full  =  (((w_pointer[$bits(w_pointer)-2] ^ r_pointer[$bits(w_pointer)-2]) & 
                         (w_pointer[$bits(w_pointer)-3:0] >= r_pointer[$bits(w_pointer)-3:0])) 
                       |
                        ((w_pointer[$bits(w_pointer)-1] ^ r_pointer[$bits(w_pointer)-1]) & 
                         (w_pointer[$bits(w_pointer)-2] ~^ r_pointer[$bits(w_pointer)-2])));

  // Almost-full/almost-empty flag compute
  always_ff @( negedge daf_i ) begin : compute_offset
    if (!rst_n_i) begin
      offset <= data_in_i;
    end else begin
      offset <= '0;
    end
  end : compute_offset
  //
  always_ff @( posedge rst_n_i ) begin : select_X_value
    if (daf_i) begin
      x_reg <= default_x;
    end else begin
      x_reg <= offset;
    end
  end : select_X_value
  //
  assign data_filled = w_pointer[$bits(w_pointer)-1:0] + (~r_pointer[$bits(r_pointer)-1:0]) + 1;

  // compare AF/AE boundary
  always_comb begin : compare_bound
    if ((data_filled >= x_reg + 2) && (data_filled <= FIFO_ENTRIES - x_reg)) begin
      af_ae = 1'b0;
    end else begin
      af_ae = 1'b1;
    end
  end : compare_bound
  //
  // Status outputs
  assign fifo_full_o  = full_syn_stage2;
  assign fifo_empty_o = empty_syn_stage3;
  assign half_full_o  = half_full;
  assign af_ae_o      = af_ae;

endmodule