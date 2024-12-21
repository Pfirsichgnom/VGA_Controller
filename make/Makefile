# vhdl files
FILES = ../vhdl/src/vga_timing_generator.vhd

# testbench
TESTBENCHENTITY = vga_timing_generator_tb
TESTBENCHFILE = ../vhdl/tb/vga_timing_generator_tb.vhd
TESTBENCHPATH = ../vhdl/tb/
WORKDIR = ../work
VCDFILE = ../work/sim.vcd


#GHDL CONFIG

GHDL_FLAGS  = -P../work  --ieee=synopsys --std=08 --warn-no-vital-generic --workdir=$(WORKDIR) 
STOP_TIME = 1000ms
# Simulation break condition
WAVEFORM_VIEWER = gtkwave
GHDL_SIM_OPT = --stop-time=$(STOP_TIME) --assert-level=error
.PHONY: clean

all: clean make run view

make:

	mkdir -p $(WORKDIR)
	ghdl -s $(GHDL_FLAGS) $(FILES) 
	ghdl -s $(GHDL_FLAGS) $(TESTBENCHFILE)
	#ghdl -c --workdir=$(WORKDIR) $(GHDL_FLAGS) $(FILES) $(TESTBENCHFILE)
	ghdl -a $(GHDL_FLAGS) $(FILES) 
	ghdl -a $(GHDL_FLAGS) $(TESTBENCHFILE) 
	ghdl -e $(GHDL_FLAGS) $(TESTBENCHENTITY)  

run:
	ghdl -r $(GHDL_FLAGS) $(TESTBENCHENTITY) --vcd=$(VCDFILE) $(GHDL_SIM_OPT)

view:
	$(WAVEFORM_VIEWER) --dump=$(VCDFILE)

clean:
	@rm -rf $(WORKDIR)