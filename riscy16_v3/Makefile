PYTHON ?= python
VSIM ?= vsim
PROG ?= tests/basic.asm
PROGRAM ?= program.txt

.PHONY: sim iss cosim synth-check assemble disassemble

sim:
	$(VSIM) -c -do sim/run.do

iss:
	$(PYTHON) sim/iss/iss.py $(PROGRAM)

cosim:
	$(PYTHON) sim/iss/cosim.py $(PROGRAM)

synth-check:
	$(PYTHON) tools/synth_check.py

assemble:
	$(PYTHON) tools/assembler.py $(PROG) $(PROGRAM)

disassemble:
	$(PYTHON) tools/disassembler.py $(PROGRAM)
