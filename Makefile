
SYNOPSYS = /usr/caen/synopsys-synth-2023.12-SP5
SYNOPSYS_DW_SIM = $(SYNOPSYS)/dw/sim_ver
STD_CELLS = /afs/umich.edu/class/eecs627/ibm13/artisan/2005q3v1/aci/sc-x/verilog/ibm13_neg.v

TESTBENCH = adder_tb.sv

SIM_FILES = adder_inst.sv
SIM_SYN_FILES = standard.vh ../syn/adder_inst.syn.v
SIM_APR_FILES = standard.vh ../apr/adder_inst.syn.v

BUTTERFLY_SIM_FILES = butterfly.sv $(SYNOPSYS_DW_SIM)/DW_fp_add.v $(SYNOPSYS_DW_SIM)/DW_fp_sub.v $(SYNOPSYS_DW_SIM)/DW_fp_addsub.v ../standard.vh
BUTTERFLY_SYN_FILES = ../../syn/butterfly/butterfly.syn.v ../standard.vh
BUTTERFLY_TESTBENCH = butterfly_tb.sv

VV         = vcs
VVOPTS     = -o $@ +v2k +vc -sverilog -timescale=1ns/1ps +vcs+lic+wait +multisource_int_delays -debug_access+all -kdb \
	       	+neg_tchk +incdir+$(VERIF) +plusarg_save +overlap +warn=noSDFCOM_UHICD,noSDFCOM_IWSBA,noSDFCOM_IANE,noSDFCOM_PONF -full64 -cc gcc +libext+.v+.vlib+.vh 

ifdef WAVES
VVOPTS += +define+DUMP_VCD=1 +memcbk +vcs+dumparrays +sdfverbose
endif

ifdef GUI
VVOPTS += -gui
endif

MODULES = butterfly
all: clean sim models run_syn sim_syn run_apr sim_apr

clean:
	rm -f verilog/$(MODULES)/sim_$(MODULES)
	rm -f verilog/$(MODULES)/sim_syn_$(MODULES)
	rm -f verilog/$(MODULES)/ucli.key
	rm -f -r verilog/$(MODULES)/verdiLog
	rm -f -r verilog/$(MODULES)/*.daidir
	rm -fr verilog/$(MODULES)/csrc
	rm -f verilog/$(MODULES)/*.{txt,log,rc,fsdb}
	rm -f -r syn/dwsvf_*
	rm -fr syn/$(MODULES)/alib-52
	rm -f syn/$(MODULES)/*.syn.v
	rm -f syn/$(MODULES)/output.txt
	rm -f syn/$(MODULES)/*.{log,sdf,rpt,svf,sdc}
	rm -f apr/*.apr.v
	rm -f apr/output.txt
	rm -f apr/*.{log,sdf,rpt,svf,sdc}

sim_butterfly:
	python goldenbrick/butterfly_gb.py -b > verilog//butterfly/butterfly_gb.txt;
	cd verilog/butterfly; $(VV) $(VVOPTS) $(STD_CELLS) $(BUTTERFLY_SIM_FILES) $(BUTTERFLY_TESTBENCH); ./$@
	cp verilog/butterfly/butterfly_tb.txt verilog/butterfly/butterfly_behavioral.txt 
	diff verilog/butterfly/butterfly_gb.txt verilog//butterfly/butterfly_behavioral.txt | tee verilog/butterfly/diff_behavioral.txt

syn_butterfly: 
	cd syn/butterfly; dc_shell -tcl_mode -xg_mode -f butterfly.syn.tcl | tee output.txt

sim_syn_butterfly: syn_butterfly
	python goldenbrick/butterfly_gb.py -b > verilog//butterfly/butterfly_gb.txt;
	cd verilog/butterfly; $(VV) $(VVOPTS) +define+SYN=1 $(STD_CELLS) $(BUTTERFLY_SYN_FILES) $(BUTTERFLY_TESTBENCH); ./$@
	cp verilog/butterfly/butterfly_tb.txt verilog/butterfly/butterfly_structural.txt 
	diff verilog/butterfly/butterfly_gb.txt verilog//butterfly/butterfly_structural.txt | tee verilog/butterfly/diff_structural.txt

sim:
	cd verilog; $(VV) $(VVOPTS) $(STD_CELLS) $(SIM_FILES) $(TESTBENCH); ./$@

models:
	cd lib; pt_shell -f reset_driver.lib.tcl | tee reset_driver.log

run_syn:
	cd syn; dc_shell -tcl_mode -xg_mode -f adder.syn.tcl | tee output.txt

sim_syn:
	cd verilog; $(VV) $(VVOPTS) +define+SYN=1 $(STD_CELLS) $(SIM_SYN_FILES) $(TESTBENCH); ./$@

run_apr:
	cd apr; innovus -init mult_block.apr.tcl | tee output.txt 

sim_apr:
	cd verilog; $(VV) $(VVOPTS) +sdfverbose +define+APR=1 $(STD_CELLS) $(SIM_APR_FILES) $(TESTBENCH); ./$@
	cp verilog/signatures.txt verilog/signatures_apr.txt
	diff verilog/signatures_behavioral.txt verilog/signatures_apr.txt | tee verilog/diff_structural.txt
