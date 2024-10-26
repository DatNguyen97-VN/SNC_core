# The Asynchronous FIFO Module
![Document](https://img.shields.io/badge/100%25-brightgreen?style=plastic&logo=readthedocs&label=Doc&labelColor=Doc) ![RTL Design](https://img.shields.io/badge/100%25-brightgreen?style=plastic&logo=codecrafters&label=RTL&labelColor=Doc
) ![Verfication](https://img.shields.io/badge/0%25-%23e1251b?style=plastic&logo=cachet&label=Verification&labelColor=Doc) ![Coverage](https://img.shields.io/badge/0%25-%23FF0000?style=plastic&logo=moleculer&label=Coverage)
1. [Overview](#1-Overview)
   * [Key Features](#Key-Features)
   * [I/O Ports](#IO-Ports)
2. [Theory of Operation](#2-Theory-of-Operation)
   * [Write and Read Data](#Write-and-Read-Data)
   * [Inputs](#Inputs)
   * [Outputs](#Outputs)
   * [Functional Description](#Functional-Description)
3. [CDC Techniques](#3-CDC-Techniques)
   * [Double Flopping](#Double-Flopping)
   * [Synchronize Gray Code](#Synchronize-Gray-Code)
4. [FIFO Verification](#4-FIFO-Verification)
5. [Getting Started](#5-Getting-Started)
6. [References](#6-References)

## 1. Overview  
![fifo overview](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/asyn_fifo.png)

An asynchronous FIFO refers to a FIFO design where data values are written sequentially into a FIFO buffer using
one clock domain, and the data values are sequentially read from the same FIFO buffer using another clock domain,
where the two clock domains are asynchronous to each other.  

It is organized as `<FIFO_ENTRIES> × <DATA_WIDTH>` bits. Expansion is accomplished easily in both word width and word entries.
The FIFO has normal input-bus to output-bus asynchronous operation.  

### Key Features  
- [X] User-Selectable Input and Output Port Bus Size  
- [X] Big-Endian/Little-Endian User-Selectable Byte Represent  
- [X] Master Reset Clears Entries FIFO  
- [X] Partial Reset Clears Data, but Retains Programmable settings  
- [X] Empty, Full, and Half-Full Flags Signal FIFO status  
- [X] Programmable Almost-Empty and Almost-Full Flags; Each Flag Can Default to One of Eight Offsets  
- [X] Selectable Synchronous/Asynchronous Timing Modes for Almost-Empty and Almost-Full Flags  
- [X] Program Programmable Flags by Either Serial or Parallel    
- [X] Output Enable Puts Data Outputs in High-Impedance State  
- [X] Easily Expandable in Depth and Width  
- [X] Independent Read and Write Clocks Permit Reading and Writing simultaneously  
- [ ] Zero-Latency Retransmit   
- [ ] Fixed, Low First-Word Latency  

### IO Ports  
**Top Diagram**  
![fifo ports](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/ports.png)  

**Port Table**
| PORTNAME     | I/O    |   BIT WIDTH   | DESCRIPTION |
|--------------|--------|:-------------:|-------------|
| mrst_n_i     | input  |       1       | Master reset |
| prst_n_i     | input  |       1       | Partial reset |
| wr_i         | input  |       1       | Write enable |
| rd_i         | input  |       1       | Read Enable |
| clk_wr_i     | input  |       1       | Write clock |
| clk_rd_i     | input  |       1       | Read clock |
| oe_i         | input  |       1       | Output enable |
| re_trans_i   | input  |       1       | Retransmit |
| LD_i         | input  |       1       | Load       |
| FSEL_i       | input  |       2       | Flag-select bit |
| big_en_i     | input  |       1       | Big endian/little endian |
| iw_ow_i      | input  |       1       | Input and Output width   |
| PFM_i        | input  |       1       | Programmable-flag mode   |
| SEN_i        | input  |       1       | Serial enable            |
| SI_i         | input  |       1       | Serial input             |
| fifo_empty_o | output |       1       | Programmable almost-empty flag |
| fifo_full_o  | output |       1       | Full flag            |
| half_full_o  | output |       1       | Half-full flag       |
| almost_full_flag_o  | output  |       1       | Programmable almost-full flag           |
| almost_empty_flag_o | output  |       1       | Programmable almost-empty flag          |
| data_in_i           | input   |     **Programmable**       | Input data                 |
| data_out_o          | output  |     **Programmable**       | Output data                |

## 2. Theory of Operation  

### 2.1 Write and Read Data  
This fifo uses a `gray code counter` for the write/read pointer and `double flopping` are used to synchronize into the opposite clock domain, the memory address of the incoming data is in the write pointer. The address of the first data word in the FIFO that is to be read out is in the read pointer. After reset, both pointers indicate the same memory location. After each write operation, the write pointer is set to the next memory location. The reading of a data word sets the read pointer to the next data word that is to be read out. The read pointer constantly follows the write pointer. When the read pointer reaches the write pointer, the FIFO is empty. If the write pointer catches up with the read pointer, the FIFO is full.  

**Write Data**  
When wr_i is high, data can be loaded into the FIFO SRAM array on the rising edge of every clk_wr_i cycle if the
device is not full. Data is stored in the SRAM array sequentially and independently of any ongoing read operation.
When wr_i is low, no new data is written in the RAM array on each clk_wr_i cycle.  

**Read Data**  
When rd_i is high, data is loaded from the SRAM array into the output register on the rising edge of every clk_rd_i cycle, if the device is not empty. When rd_i is low, the output register holds the previous data and no new data is loaded into the output register.
The data outputs data_out_o maintain the previous data value.  

### 2.2 Inputs 
**master reset**  
A master reset is accomplished when the mrst_i is taken to a low state. This operation sets the internal read
and write pointers to the first location of the SRAM array. All flags, offset registers and output are set to a reset state.  

All control settings, such as OW, IW, BE and PFM are defined during the master reset cycle.  

> [!NOTE]
> The length of master reset cycle is least 4 write/read clock cycle.    

**partial reset**  
A partial reset is accomplished when the prst_i input is taken to a low state. As in the case of the master reset,
the internal read and write pointers are set to the first location of the SRAM array, but only flags are set to a reset state.  

All values held in the offset registers remain unchanged. The output register is initialized to all zero.  

**retransmit**   
The retransmit operation allows previously read data to be accessed again. There are two stages to retransmit. The first stage is a setup procedure that resets the read pointer to the first location of physical memory. The second stage is the actual retransmit,
which consists of reading out the memory contents, starting at the beginning of the memory.  

Retransmit setup is initiated by holding re_trans_i high during a rising clk_rd_i edge. rd_i and wr_i must be low before
clk_rd_i rises when re_trans_i is high.  

If this feature is triggered, the FIFO marks the beginning of the retransmit setup by setting empty flag low. The
change in level is noticeable only if empty flag was high before setup. During this period, the internal read pointer is
initialized to the first location of the SRAM array.  

When empty flag goes high, retransmit setup is complete and read operations can begin, starting with the first location
in memory. Since standard mode is selected, every word read, including the first word following retransmit
setup, requires a high on rd_i to enable the rising edge of clk_rd_i.   

![retransmit](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/retransmit_timing.png) 

> [!NOTE]
> Note: must be at least two words written to and two words read from the FIFO before a retransmit operation can be invoked. No more  > than (FIFO_ENTRIES – 2) words may be written to the FIFO between reset (master or partial) and retransmit setup. Therefore, Full-Flag is
> high throughout the retransmit setup procedure.  

**serial enable**  
The SEN_i input is an enable used only for serial programming of the offset registers. The serial programming
method must be selected during master reset. SEN_i always is used with LD_i pin. When these lines are both high, data
at the SI_i input can be loaded into the program register, with one bit for each low-to-high transition of clk_wr_i.  

**output enable**  
When oe_i is asserted (high), the parallel output buffers receive data from the output register. When oe_i is low,
the output data bus goes into the high-impedance state.  

**load**    
During master reset, the state of the LD_i input, along with 2-bit FSEL_i input,
determines one of eight default offset values for the almost-full and almost-empty flags, along with the method by which these
offset registers can be programmed, parallel or serial . After master reset, LD enables write
operations to and read operations from the offset registers. Only the offset loading method currently selected
can be used to write to the registers. Offset registers can be read only in parallel.  

| LD     | FSEL1  |   FSEL0   | (n,m) |
|:------:|:------:|:---------:|:-----:|
| H      | L      |    L      | 1023  |
| L      | L      |    H      | 511   |
| L      | H      |    L      | 255   |
| L      | L      |    L      | 127   |
| L      | H      |    H      | 63    |
| H      | L      |    H      | 31    |
| H      | H      |    L      | 15    |
| H      | H      |    H      | 7     |  

**input width (IW)/output width (OW) bus matching**  
iw_ow_i define the input and output bus widths. During master reset, the state of pin is used to
configure the device bus sizes (see Table 1 for control settings). All flags operate based on the word/byte size
boundary, as defined by the selection of the widest input or output bus width.  

| IW     | IO     | Write Port Width | Read Port Width |
|:------:|:------:|:---------:|:-----:|
| L      | L      | `DATA_WIDTH` | `DATA_WIDTH` |
| L      | H      | `DATA_WIDTH` | `DATA_WIDTH/2` |
| H      | L      | `DATA_WIDTH/2` | `DATA_WIDTH` |
| H      | H      | `DATA_WIDTH` | `DATA_WIDTH` |  

**big endian/little endian**    
During master reset, a high on big_en_i selects big-endian operation. A low on big_en_i during master reset selects
little-endian format. If big-endian mode is selected, the MSB of the word written into the FIFO is read out of the FIFO first, followed by the LSB. If little-endian format is selected, the LSB of the word written into the FIFO is read out first, followed by the MSB. The desired mode is configured during master reset by the state of the big_en_i.  

**programmable-flag mode**  
During master reset, a low on PFM_i selects asynchronous programmable-flag timing mode. A high on PFM_i
selects synchronous programmable-flag timing mode. If asynchronous almost-empty/almost-full configuration is selected
, almost_empty_flag_o is asserted low on the low-to-high transition of clk_rd_i. almost_empty_flag_o is reset to high on the
low-to-high transition of clk_wr_i. Similarly, almost_full_flag_o is asserted low on the low-to-high transition of clk_wr_i, and
is reset to high on the low-to-high transition of clk_rd_i.  

If the synchronous configuration is selected , almost_empty_flag_o is asserted and updated
on the rising edge of clk_rd_i only, and not clk_wr_i. Similarly, almost_full_flag_o is asserted and updated on the rising edge of
clk_wr_i only, and not clk_rd_i. The mode desired is configured during master reset by the state of PFM_i.   

### 2.3 Outputs  

**full flag**    
When the FIFO is full, fifo_full_o goes low, inhibiting further write
operations. When fifo_full_o is high, the FIFO is not full. If no reads are performed after a reset,
fifo_full_o goes low after FIFO_ENTRIES writes to the FIFO.  

fifo_full_o is synchronous and updated on the rising edge of clk_wr_i and is double register-buffered outputs.  

![full flag](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/full_flag_timing.png)

**empty flag**    
When the FIFO is empty, fifo_empty_o goes low, inhibiting further read operations. When fifo_empty_o is high, the FIFO is not empty.
It is synchronous and updated on the rising edge of clk_rd_i and is a double register-buffered output.  

![empty flag](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/empty_flag_timing.png)

**programmable almost-full flag**  
if no reads are performed after reset, almost_full_flag_o goes low after (FIFO_ENTRIES – m) words are written to the
FIFO. The offset m is the full offset value.  

If asynchronous almost_full_flag_o configuration is selected, the almost_full_flag_o is asserted low on the low-to-high transition of clk_wr_i.
almost_full_flag_o is reset to high on the low-to-high transition of clk_rd_i. If synchronous almost_full_flag_o configuration is selected and
is updated on the rising edge of clk_wr_i.  

![paf](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/paf_timing.png)

**programmable almost-empty flag**  
It goes low when the FIFO reaches the almost-empty condition when there are n words, or fewer, in the FIFO. The offset n is the empty offset value.  

If asynchronous almost-empty flag configuration is selected and is asserted low on the low-to-high transition of the read clock.
It is reset to high on the low-to-high transition of the write clock. If synchronous
configuration is selected and is updated on the rising edge of read clock.  

![pef](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/pef_timing.png)

**half-full flag**    
The half_full_o output indicates a half-full FIFO. The rising clk_wr_i edge that fills the FIFO beyond half-full sets half_full_o low.
The flag remains low until the difference between the write and read pointers becomes less than or equal to half
of the total depth of the device. The rising clk_rd_i edge that accomplishes this condition sets half_full_o high.  

if no reads are performed after reset, HF goes low after (FIFO_ENTRIES/2) + 1 writes to the FIFO.    

### 2.4 Functional Description    

**programming flag offsets**    
Full and empty flag offset values are user programmable. Eight default offset values are selectable during master
reset. Offset values also can be programmed into the FIFO by serial
or parallel loading. The loading method is selected using LD_i. During master reset, the state of the LD_i input
determines whether serial or parallel flag offset programming is enabled. A high on LD_i during master reset
selects serial loading of offset values. A low on LD_i during master reset selects parallel loading of offset values.  

In addition to loading offset values into the FIFO, it also is possible to read the current offset values. Offset values
can be read via the parallel output ports data_out_o, regardless of the programming mode selected (serial or
parallel). It is not possible to read the offset values in serial fashion.  

![pfm](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/programmable_offset_register.PNG)

**synchronous vs asynchronous programmable-flag timing selection**  
The FIFO can be configured during the master reset cycle with
either synchronous or asynchronous timing for almost-empty/almost-full flags by use of the PFM_i pin.  

If synchronous almost-empty/almost-full configuration is selected, almost_full_flag_o is asserted and updated on the
rising edge of clk_wr_i only and not clk_rd_i. Similarly, almost_empty_flag_o is asserted and updated on the rising edge of clk_rd_i
only and not clk_wr_i.  

If asynchronous almost-empty/almost-full configuration is selected, almost_full_flag_o is asserted low on the
low-to-high transition of clk_wr_i and is reset to high on the low-to-high transition of clk_rd_i. Similarly, almost_empty_flag_o
is asserted low on the low-to-high transition of clk_rd_i. PAE is reset to high on the low-to-high transition of clk_wr_i.  

**serial programming mode**    
If the serial programming mode has been selected as described previously, programming of almost-empty/almost-full
values can be achieved by using a combination of the LD_i, SEN_i, clk_wr_i, and SI_i inputs. Programming 
almost-empty/almost-full proceeds as follows; when LD_i and SEN_i are set low, data on the SI_i input are written, one bit for each clk_wr_i
rising edge, starting with the empty offset LSB and ending with the full offset MSB with a total of 32 bits.  

Using the serial method, individual registers cannot be programmed selectively. almost-empty/almost-full can shows a valid
status only after the complete set of bits for all offset registers has been entered. The registers can be
reprogrammed as long as the complete set of new offset bits is entered. When LD_i is low and SEN is high, no
serial write to the registers can occur.  

![serial loading](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/serial_loading_timing.png)

> [!WARNING] 
> Write operations to the FIFO are not allowed before and during the serial programming sequence.  

**parallel programming mode**  
If the parallel programming mode has been selected as described previously, programming of almost-empty/almost-full
values can be achieved by using a combination of the LD_i, clk_wr_i, wr_i and data_in_i inputs.  

when LD_i and wr_i are set high, data on inputs data_in_i are written into the LSB of the empty offset register on the
first low-to-high transition of clk_wr_i. On the second low-to-high transition of clk_wr_i, data are written into the MSB
of the empty offset register. On the third low-to-high transition of clk_wr_i, data are written into the LSB of the full
offset register. On the fourth low-to-high transition of clk_wr_i, data are written into the MSB of the full offset
register and parallel programming mode is complete.  

![parallel loading](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/parallel_loading_timing.png)

> [!WARNING] 
> Write operations to the FIFO are not allowed before and during the parallel programming sequence.
> The status of a programmable-flag output is invalid during the programming process.  

Reading the offset registers employs a dedicated read offset register pointer. The contents of the offset registers
can be read on the data_out_o pins when LD_i is set low and rd_i is set high. The total number of read operations required to read the offset
registers is four, data are read via data_out_o from the empty offset register on the first and second low-to-high transition of
clk_rd_i. On the third and fourth low-to-high transitions of clk_rd_i, data are read from the full offset register and is complete.

![parallel loading](https://github.com/DatNguyen97-VN/SNC_core/blob/main/asyn_fifo/doc/figures/parallel_reading_timing.png)

## 3. CDC Techniques  
### Double Flopping  
In digital design has the constantly recurring problem of synchronizing two systems that work at different
frequencies result in the flip-flop can become metastable because setup or hold times must be not maintained.

To use an asynchronous signal in a design, a synchronization circuit is required. The synchronization circuit's function is to sample the asynchronous input signal and provide a synchronized output based on the clock signal used inside the design. The `classic synchronization circuit` is the one that uses two flip-flops (FF).

### Synchronize Gray Code  
This FIFO designs with the two pointers are generated from two different clock domains, the pointer values
need to be “safely” passed to the opposite clock domain. The `synchronize Gray Code` technique is used to
insure that only `one pointer bit` can change at a time.  

## 4. FIFO Verification  
## 5. Getting Started  
## 6. References  
1. Mr. Nguyen Quan, Multi-Clock Design lesson 1, https://nguyenquanicd.blogspot.com/2017/08/multi-clock-design-bai-1-ky-thuat-thiet.html,   
2. Mr. Nguyen Quan, Multi-Clock Design lesson 3, https://nguyenquanicd.blogspot.com/2020/02/multi-clock-design-bai-3-ky-thuat-ong.html  
2. FIFO Architecture, Functions, and Applications from Texas Instruments  
3. Mr. Clifford E. Cummings, Simulation and Synthesis Techniques for Asynchronous FIFO Design  
4. Mr. Clifford E. Cummings, Simulation and Synthesis Techniques for Asynchronous FIFO Design with Asynchronous Pointer Comparisons  
5. Texas Instruments's SN74V263  
