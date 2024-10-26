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
//          0.3.1   + Oct 22nd 2024
//                  + added almost empty/full-flags
//                  + added half full flag
//          0.4.0   + OCt 23rd 2024
//                  + added serial/parallel programming mode 
//          0.4.1   + fixed a bug of execution logic for serial/parallel programming mode
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef  _INCL_DEFINITIONS
  `define _INCL_DEFINITIONS
  `include "fifo_parameters.svh"
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
    input  logic                   oe_i,
    input  logic                   re_trans_i,
    input  logic                   LD_i,
    input  logic [1:0]             FSEL_i,
    input  logic                   big_en_i,
    input  logic [1:0]             iw_ow_i,
    input  logic                   PFM_i,
    input  logic                   SEN_i,
    input  logic                   SI_i,
    output logic                   fifo_empty_o,
    output logic                   fifo_full_o,
    output logic                   half_full_o,
    output logic                   almost_full_flag_o,
    output logic                   almost_empty_flag_o,
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
    logic fifo_empty;
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
    logic       big_en_wr_step;
    logic       big_en_rd_step;
    logic       big_en_offset;
    logic [1:0] iw_ow_offset;
    // Almost-full/almost-empty flag and half-full flag signals
    logic almost_full_flag_buf1;
    logic almost_full_flag_buf2;
    logic asyn_almost_full_flag;
    logic almost_empty_flag_buf1;
    logic almost_empty_flag_buf2;
    logic asyn_almost_empty_flag;
    logic LD_offset;
    logic PFM_offset;
    logic [01:00] FSEL_offset;
    logic [09:00] full_offset;
    logic [09:00] empty_offset;
    logic asyn_half_full_flag;
    logic [$clog2(FIFO_ENTRIES):0] asyn_data_filled;
    logic [$clog2(FIFO_ENTRIES):0] data_filled_read;
    logic [$clog2(FIFO_ENTRIES):0] data_filled_write;
    // programming mode offsets and offset registers
    logic SEN_offset;
    logic [31:00] serial_load_status;
    logic [03:00] parallel_read_status;
    logic [15:00] empty_offset_register;
    logic [15:00] full_offset_register;
    logic [DATA_WIDTH-1:0] parallel_read_offset;
    // Data latch signals
    logic [DATA_WIDTH-1:0] data_latch;


    // Pre-validation ----------------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    initial begin
    /* information about a range of X value */
      assert (0)
      else $info("ASYN FIFO CONFIG NOTE: X value of valid range [1..%0d].", FIFO_ENTRIES/2 - 1);
    /*Check default value of Offset */
      assert (DATA_WIDTH >= ($clog2(FIFO_ENTRIES)-1))
      else $error("ASYN FIFO CONFIG NOTE: Size of data_in_i in <DATA_WIDTH> should be great than or equal: %0d to represent a default value of Offset(x)", $clog2(FIFO_ENTRIES)-1);
    /* 2^n fifo entries check */
      if (((FIFO_ENTRIES & (FIFO_ENTRIES-1)) == 0) && (FIFO_ENTRIES >= 4)) begin
        $info("ASYN FIFO CONFIG NOTE: Number of fifo entries is %0d and data width is %0d", FIFO_ENTRIES, DATA_WIDTH);
      end else begin
        $error("ASYN FIFO CONFIG ERROR! Number of fifo entries in <FIFO_ENTRIES> has to be a power of two, min is 4.");
      end
    /* DATA WIDTH */
      assert (!DATA_WIDTH[0])
      else $error("ASYN FIFO CONFIG ERROR: Size of input data in <DATA_WIDTH> should be an even number");
    end

    /* ------------------------------- */
    /*            RESET LOGIC          */
    /* ------------------------------- */
    assign reset = mrst_n_i & prst_n_i;

    /* ------------------------------- */
    /* WRITE POINTER AND CONTROL BLOCK */
    /* ------------------------------- */
    assign fifo_we = wr_i & full_buffer2 & ~LD_i;
    //
    always_ff @( posedge clk_wr_i or negedge reset ) begin : write_pointer
      if (!reset) begin
        wbin <= '0;
      end else if (fifo_we) begin
        wbin <= (iw_ow_offset == 2'b10) ? (wbin + big_en_wr_step) : wbin_next;
      end
    end : write_pointer

    // increate wbin_next by 1
    assign wbin_next = wbin + 1'b1;

    // big endian write step
    always_ff @( posedge clk_wr_i or negedge reset ) begin
      if (!reset) begin
        big_en_wr_step <= 0;
      end else if (fifo_we) begin
        big_en_wr_step <= ~big_en_wr_step;
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
    assign fifo_re = rd_i & fifo_empty & ~LD_i;
    //
    always_ff @( posedge clk_rd_i or negedge reset) begin : read_pointer
      if (!reset) begin
        rbin <= '0;
      end else if (retrans_en) begin
        // set msb value into rbin at retransmission mode
        rbin <= {msb_rbin, {$bits(rbin)-1{1'b0}}};
      end else if (fifo_re) begin
        rbin <= (iw_ow_offset == 2'b01) ? (rbin + big_en_rd_step) : rbin_next;
      end
    end : read_pointer

    // increate rbin_next by 1
    assign rbin_next = rbin + 1'b1;

    // big endian read step
    always_ff @( posedge clk_rd_i or negedge reset ) begin
      if (!reset) begin
        big_en_rd_step <= 0;
      end else if (fifo_re) begin
        big_en_rd_step <= ~big_en_rd_step;
      end
    end

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
    always_ff @( posedge clk_wr_i or negedge reset ) begin : write_data
      if (!reset) begin
        mem_array <= '{default : '0};
      end else if (fifo_we) begin
        // mode selection of write data
        case ({big_en_offset, iw_ow_offset, big_en_wr_step})
          // little endian
          4'b0_10_0 : mem_array[wbin[$bits(wbin)-2:0]][DATA_WIDTH-1:DATA_WIDTH/2] <= data_in_i[DATA_WIDTH/2-1:0];          // LSB
          4'b0_10_1 : mem_array[wbin[$bits(wbin)-2:0]][DATA_WIDTH/2-1:0]          <= data_in_i[DATA_WIDTH-1:DATA_WIDTH/2]; // MSB
          // big endian
          4'b1_10_0 : mem_array[wbin[$bits(wbin)-2:0]][DATA_WIDTH-1:DATA_WIDTH/2] <= data_in_i[DATA_WIDTH-1:DATA_WIDTH/2]; // MSB
          4'b1_10_1 : mem_array[wbin[$bits(wbin)-2:0]][DATA_WIDTH/2-1:0]          <= data_in_i[DATA_WIDTH/2-1:0];          // LSB
          default: begin
                      mem_array[wbin[$bits(wbin)-2:0]] <= big_en_offset ? data_in_i : 
                                                                         {data_in_i[DATA_WIDTH/2-1:0], data_in_i[DATA_WIDTH-1:DATA_WIDTH/2]};
          end
        endcase
      end
    end : write_data
    //
    always_ff @( posedge clk_rd_i or negedge reset ) begin : read_data
      if (!reset) begin
        data_latch <= '0;
      end else if (fifo_re) begin
        // mode selection of write data
        case ({big_en_offset, iw_ow_offset, big_en_rd_step})
          // MSB
          4'b0_01_0, 4'b1_01_0 : data_latch[DATA_WIDTH/2-1:0] <= mem_array[rbin[$bits(rbin)-2:0]][DATA_WIDTH-1:DATA_WIDTH/2];
          // LSB
          4'b1_01_1, 4'b1_01_1 : data_latch[DATA_WIDTH/2-1:0] <= mem_array[rbin[$bits(rbin)-2:0]][DATA_WIDTH/2-1:0];
          default: begin
                                 data_latch                   <= mem_array[rbin[$bits(rbin)-2:0]];
          end
        endcase
      end
    end : read_data

    /* --------------------------- */
    /*       OFFSET REGISTERS      */
    /*---------------------------- */
    always_ff @(negedge mrst_n_i) begin : offset_registers
      if (!mrst_n_i) begin
        big_en_offset <= big_en_i;
        iw_ow_offset  <= iw_ow_i;
        PFM_offset    <= PFM_i;
        LD_offset     <= LD_i;
        FSEL_offset   <= FSEL_i;
        SEN_offset    <= SEN_i;
      end
    end : offset_registers

    /* ------------------ */
    /* DATA LATCH OUTPUT  */
    /*------------------- */
    assign data_out_o = oe_i ? LD_i ? parallel_read_offset : data_latch 
                             : 'z;

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

    // Calculate the asynchronous capacity of FIFO -----------------------------------------------
    // -------------------------------------------------------------------------------------------
    assign asyn_data_filled = wbin + ~rbin + 1'b1;

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
    assign fifo_empty_o = fifo_empty;
    assign fifo_full_o = full_buffer2;

    // Almost-Full-Flag Operation ----------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_ff @( posedge clk_wr_i or negedge reset ) begin : full_offset_selection
      if (!reset) begin
        full_offset <= '0;
      end else begin
        // offset selection
        case ({LD_offset, FSEL_offset})
          3'b1_00 : full_offset <= m8;
          3'b0_01 : full_offset <= m7;
          3'b0_10 : full_offset <= m6;
          3'b0_00 : full_offset <= m5;
          3'b0_11 : full_offset <= m4;
          3'b1_01 : full_offset <= m3;
          3'b1_10 : full_offset <= m2;
          3'b1_11 : full_offset <= m1;
          default: begin
            full_offset <= '0;
          end
        endcase
      end
    end : full_offset_selection
    //
    always_ff @( posedge clk_wr_i or negedge reset ) begin : compare_full_offset_bound
      if (!reset) begin
        {almost_full_flag_buf2, almost_full_flag_buf1} <= 2'b11;
      end else if (((data_filled_write >= FIFO_ENTRIES-full_offset) && !LD_i) || // normal mode
                   ((data_filled_write >= FIFO_ENTRIES-full_offset_register) && LD_i)) begin // programmable mode
        {almost_full_flag_buf2, almost_full_flag_buf1} <= {almost_full_flag_buf1, 1'b0};
      end else begin
        {almost_full_flag_buf2, almost_full_flag_buf1} <= {almost_full_flag_buf1, 1'b1};
      end
    end : compare_full_offset_bound

    // Asyn Almost-Full-Flag Operation -----------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_comb begin : compute_asyn_full_flag
      if (asyn_data_filled >= FIFO_ENTRIES-full_offset) begin
        asyn_almost_full_flag = 1'b0;
      end else begin
        asyn_almost_full_flag = 1'b1;
      end
    end : compute_asyn_full_flag

    // almost full flag selection
    assign almost_full_flag_o = PFM_offset ? almost_full_flag_buf2 : asyn_almost_full_flag;

    // Almost-Empty-Flag Operation ---------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_ff @( posedge clk_rd_i or negedge reset ) begin : empty_offset_selection
      if (!reset) begin
        empty_offset <= '0;
      end else begin
        // offset selection
        case ({LD_offset, FSEL_offset})
          3'b1_00 : empty_offset <= n8;
          3'b0_01 : empty_offset <= n7;
          3'b0_10 : empty_offset <= n6;
          3'b0_00 : empty_offset <= n5;
          3'b0_11 : empty_offset <= n4;
          3'b1_01 : empty_offset <= n3;
          3'b1_10 : empty_offset <= n2;
          3'b1_11 : empty_offset <= n1;
          default: begin
            empty_offset <= '0;
          end
        endcase
      end
    end : empty_offset_selection
    //
    always_ff @( posedge clk_rd_i or negedge reset ) begin : compare_empty_offset_bound
      if (!reset) begin
        {almost_empty_flag_buf2, almost_empty_flag_buf1} <= 2'b00;
      end else if (((data_filled_read <= empty_offset) && !LD_i) || // normal mode
                   ((data_filled_read <= empty_offset_register) && LD_i)) begin // programmable mode
        {almost_empty_flag_buf2, almost_empty_flag_buf1} <= {almost_empty_flag_buf1, 1'b0};
      end else begin
        {almost_empty_flag_buf2, almost_empty_flag_buf1} <= {almost_empty_flag_buf1, 1'b1};
      end
    end : compare_empty_offset_bound

    // Asyn Almost-Empty-Flag Operation ----------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_comb begin : compute_asyn_empty_flag
      if (asyn_data_filled <= empty_offset) begin
        asyn_almost_empty_flag = 1'b0;
      end else begin
        asyn_almost_empty_flag = 1'b1;
      end
    end : compute_asyn_empty_flag

    // almost full flag selection
    assign almost_empty_flag_o = PFM_offset ? almost_empty_flag_buf2 : asyn_almost_empty_flag;

    // Asyn Half-Full Flag Operation ------------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_comb begin : comptute_half_full
      if (asyn_data_filled >= FIFO_ENTRIES/2+1) begin
        asyn_half_full_flag = 1'b0;
      end else begin
        asyn_half_full_flag = 1'b1;
      end
    end : comptute_half_full
    //
    assign half_full_o = asyn_half_full_flag;

    // Programmable Flag Registers ---------------------------------------------------------------
    // -------------------------------------------------------------------------------------------
    always_ff @( posedge clk_wr_i or negedge reset ) begin : programmable_offset_registers
      if (!reset) begin
        empty_offset_register <= '0;
        full_offset_register  <= '0;
        serial_load_status    <= 32'h1;
      end else begin
        // ========================================
        // Serial shift into registers
        // ========================================
        if (LD_offset && !wr_i && !rd_i && SEN_offset) begin : serial_loading
          if (|serial_load_status[15:00]) begin
            empty_offset_register <= {SI_i, empty_offset_register[15:01]};
          end
          //
          if (|serial_load_status[31:16]) begin
            full_offset_register <= {SI_i, full_offset_register[15:01]};
          end
        // ========================================
        // Parallel write to registers
        // ========================================
        end else if (LD_offset && wr_i && !rd_i && !SEN_offset) begin : parallel_write
          // LSB --> MSB empty offset
          if (|serial_load_status[01:00]) begin
            empty_offset_register[08*serial_load_status[01] +: 08] <= data_in_i;
          end
          // LSB --> MSB full offset
          if (|serial_load_status[03:02]) begin
            full_offset_register[08*serial_load_status[02] +: 08] <= data_in_i;
          end
        end
        //
        serial_load_status <= serial_load_status << 1;
      end
    end : programmable_offset_registers
    
    // ========================================
    // Parallel read to registers
    // ========================================
    always_ff @( posedge clk_rd_i or negedge reset ) begin
      if (!reset) begin
        parallel_read_offset <= '0;
        parallel_read_status <= 4'h1;
      end else if (LD_offset && !wr_i && rd_i && !SEN_offset) begin
        // LSB --> MSB empty offset
        if (|parallel_read_status[01:00]) begin
          parallel_read_offset <= empty_offset_register[08*parallel_read_status[1] +: 08];
        end
        // LSB --> MSB full offset
        if (|parallel_read_status[03:02]) begin
          parallel_read_offset <= full_offset_register[08*parallel_read_status[3] +: 08];
        end
        //
        parallel_read_status <= parallel_read_status << 1;
      end
    end

endmodule