# The Synchronus FIFO Module
1. [Overview](#1-Overview)
   * [Key Features](#Key-Features)
   * [I/O Ports](#IO-Ports)
2. [Theory of Operation](#2-Theory-of-Operation)
3. [Timing Chart](#3-Timing-Chart)
4. [FIFO Verification](#4-FIFO-Verification)
5. [References](#5-References)

## 1. Overview
![fifo overview](https://github.com/DatNguyen97-VN/SNC_core/blob/main/fifo/doc/figures/syn_fifo.png)

A synchronus FIFO memory is a storage device that allows data to be written into and read from its array at independent data rates. It is organized as `<FIFO_ENTRIES> × <DATA_WIDTH>` bits. Expansion is accomplished easily in both word width and word entries.
The FIFO has normal input-bus to output-bus asynchronous operation. 
### Key Features

- [x] Independent Asynchronous Inputs and Outputs
- [x] Programmable Almost-Full/Almost-Empty Flag
- [X] Fifo-Full, Fifo-Empty and Half-Full Flags
- [x] Expandable in Word Width and/or Word Entries
- [X] Fifo-Full and Fifo-Empty Flags are Multilevel-Synchronized

### IO Ports

| PORTNAME     | I/O    |   BIT WIDTH   | DESCRIPTION |
|--------------|--------|:-------------:|-------------|
| rst_n_i      | input  |       1       | Reset. A reset is accomplished by taking rst_n_i low |
| wr_i         | input  |       1       | Write enable. It must be high before a rising edge on clk_wr_i |
| rd_i         | input  |       1       | Read enable. It must be high before a rising edge on clk_rd_i |
| clk_rd_i     | input  |       1       | Read clock, clk_rd_i is a free-running clock |
| clk_wr_i     | input  |       1       | Write clock, clk_wr_i is a free-running clock |
| daf_i        | input  |       1       | Define-almost-full |
| oe_i         | input  |       1       | Output enable |
| fifo_empty_o | output |       1       | Output empty flag |
| fifo_full_o  | output |       1       | Output full flag |
| half_full_o  | output |       1       | Half full flag |
| af_ae_o      | output |       1       | Almost-full/almost-empty flag |
| data_in_i    | input  | **Programmable**  | Data inputs for data to be stored in the memory |
| data_out_o   | output | **Programmable**  | Data outputs for data to be read from the memory |

## 2. Theory of Operation

### Write and Read Data
This fifo uses a ring counter for the write/read pointer, the memory address of the incoming data is in the write pointer. The address of the first data word in the FIFO that is to be read out is in the read pointer. After reset, both pointers indicate the same memory location. After each write operation, the write pointer is set to the next memory location. The reading of a data word sets the read pointer to the next data word that is to be read out. The read pointer constantly follows the write pointer. When the read pointer reaches the write pointer, the FIFO is empty. If the write pointer catches up with the read pointer, the FIFO is full.

The data_out_o is in the high-impedance state when oe_i is low. It must be high before the rising edge of clk_rd_i to read a word from memory.

### Full, Empty and Half-Full Flags
**Full-Flag** is high when the FIFO is not full and low when the device is full. During reset and is driven low on the rising edge of the second clk_wr_i pulse and is driven high on the rising edge of the second clk_wr_i pulse after rst_n_i goes high. After the FIFO is filled and is driven low, full-flag is driven high on the second clk_wr_i pulse after the first valid read.

**Empty-Flag** is high when the FIFO is not empty and low when the FIFO is empty. During reset, is set low on the rising edge of the third clk_rd_i pulse. It is set high on the rising edge of the third clk_rd_i pulse to occur after the first word is written into the FIFO and is set low on the rising edge of the first clk_rd_i pulse after the last word is read

**Half-Full-Flag** is high when the FIFO contains half or more words and is low when the number of words in memory is less than half the entries of the FIFO.

> [!NOTE]
> `Full/Empty-Flag is low at this time then is disable-write/read data. All them go through multilevel synchronization when the flags are reset
and are set without a delay because the status outputs are triggered by a synchronous signal.`

**Almost Full/Empty-Flag**  
The AF/AE boundary is defined by the AF/AE offset value (X). This
value can be programmed during reset, or the default value of FIFO_ENTRIES/4 can be used. AF/AE is high when
the FIFO contains (X + 1) or fewer words or (FIFO_ENTRIES – X +1) or more words. AF/AE is low when the FIFO
contains between (X + 2) and (FIFO_ENTRIES – X) words.  
Programming procedure for AF/AE – The AF/AE flag is programmed during each reset cycle. The
AF/AE offset value (X) is either a user-defined value or the default of X. Instructions to program
AF/AE using both methods are as follows:  

`User-defined X`  
Step 1: Take daf_i from high to low.  
Step 2: If rst_n_i is not already low, take rst_n_i low.  
Step 3: With daf_i held low, take rst_n_i high. This defines the AF/AE using X.  
Step 4: To retain the current offset for the next reset, keep daf_i low.  

`Default X`  
To redefine AF/AE using the default value of X = FIFO_ENTRIES/4, hold daf_i high during the reset cycle.  
## 3. Timing Chart  
**Reset Cycle: Define Almost-Full/Empty Flag Using a Programmed Value of X**  

![timing value](https://github.com/DatNguyen97-VN/SNC_core/blob/main/fifo/doc/figures/timing_value.png)

 `X*` is the binary value on `log2(FIFO_ENTRIES)-2`

 **Reset Cycle: Define Almost-Full/Empty Flag Using the Default Value of X**

 ![timing default](https://github.com/DatNguyen97-VN/SNC_core/blob/main/fifo/doc/figures/timing_default.png)
 
**Write Data**

![write data](https://github.com/DatNguyen97-VN/SNC_core/blob/main/fifo/doc/figures/timing_write.png)


Transition Word with `FIFO_ENTRIES` is 1024

| A    |  B   |  C  |
| :--- | :--- | :---|
| W512 | W(1024-X) |  W1024 | 


**Read Data**
![Read data](https://github.com/DatNguyen97-VN/SNC_core/blob/main/fifo/doc/figures/timing_read.png)

Transition Word with `FIFO_ENTRIES` is 1024

| A    |   B  |   C  |  D   | E    |  F   |
| :--- | :--- | :--- | :--- | :--- | :--- |
| W512 | W514 |  W(1024-X) | W(1025-X) | W1023 | W1024 |
## 4. FIFO Verification

## 5. References  

1. Synchronus FIFO, https://nguyenquanicd.blogspot.com/2017/08/ip-core-fifo-ong-bo-co-cau-hinh-uoc.html  
2. Texas Instruments's SN74ACT7881  
3. FIFO Architecture, Functions, and Applications from Texas Instruments  