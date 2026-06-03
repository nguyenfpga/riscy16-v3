# RISCY-16 v3 Change Log

## [2026-05-05] Stage 0 scaffold - no ISA changes.

The v3 directory tree has been created and v1 structural leaf modules have been
relocated as a starting point. The instruction word and existing opcode
semantics are unchanged at this stage.

## [2026-05-05] Stage 1 pipeline shell - no ISA changes.

The first five-stage pipeline shell preserves the v1 regression ISA semantics
for the legacy program while introducing pipeline registers, explicit register
file reads, branch flushing, and operand bypassing.

## [2026-05-05] Stage 2 hazard and forwarding units - no ISA changes.

Inline operand bypassing and load-use interlock logic have been factored into
the required `forward_unit.v` and `hazard_unit.v` modules without changing
instruction semantics.
