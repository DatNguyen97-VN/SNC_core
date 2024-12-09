##################################################################################
## Company: 
## Engineer: 
## 
## Create Date: 10/08/2024 09:09:44 PM
## Design Name: 
## Module Name: Make file
## Project Name: 
## Target Devices: 
## Tool Versions: 
## Description:
## 
## Dependencies: 
## 
## Revision:
## Revision 0.01 - File Created
## Additional Comments:
## 
##################################################################################

TESTNAME ?= 
SEED ?= random
COMPARG ?= 
SIMARG ?=
#===========================================================
#===========================================================
all:	clean build run

build:
		mkdir -p log
		vlib.exe work
		vlog.exe -f compile.f -timescale 1ns/1ns ${COMPARG}
		
run:
		vsim.exe ${SIMARG} -voptargs=+acc -debugdb -l ${TESTNAME}.log work.${TESTNAME} -do "source addwave.tcl;run -all" -sv_seed ${SEED}
		mv ${TESTNAME}.log ./log
		ln -sf ./log/${TESTNAME}.log sim.log

clean:
		rm -rf *.log
		rm -rf log
		rm -rf work
		rm -rf *.wlf
		rm -rf *.transcript
		rm -rf coverage
		rm -rf *.ucdb
		rm -rf vsim.*

run_gov: clean build
		vsim.exe -c -coverage -l  ${TESTNAME}.log work.${TESTNAME} -voptargs="+cover=bcefsx" -do "coverage save -onexit ${TESTNAME}.ucdb; run -all; exit" -sv_seed ${SEED}
		mv ${TESTNAME}.log ./log
		ln -sf ./log/${TESTNAME}.log sim.log

gen_cov:
		mkdir -p coverage
		vcover.exe merge IP.ucdb *.ucdb
		vcover.exe report IP.ucdb -file coverage/summary_report.txt
		vcover.exe report -zeros -detail -code bcefsx -All -codeAll IP.ucdb -file coverage/detail_report.txt
		
run_all:
		make run_gov TESTNAME=syn_fifo_tc_01
		make run_gov TESTNAME=syn_fifo_tc_02
		make run_gov TESTNAME=syn_fifo_tc_03
		make run_gov TESTNAME=syn_fifo_tc_04
		make run_gov TESTNAME=syn_fifo_tc_05
		make run_gov TESTNAME=syn_fifo_tc_06
		make run_gov TESTNAME=syn_fifo_tc_07
		make run_gov TESTNAME=syn_fifo_tc_08
		make run_gov TESTNAME=syn_fifo_tc_09
		make run_gov TESTNAME=syn_fifo_tc_10
		make run_gov TESTNAME=syn_fifo_tc_11
		make run_gov TESTNAME=syn_fifo_tc_12
		make gen_cov

#===========================================================
#===========================================================