; RISCY-16 v3 regression program.
; Rebuild program.txt with:
;   python tools/assembler.py tests/basic.asm program.txt

    ldi   r1,  5
    ldi   r2,  10
    add   r1,  r2
    mov   r3,  r1
    sub   r3,  r2
    or    r4,  r1
    and   r4,  r2
    nor   r5,  r1

    ldi   r6,  0xABCD
    sts   r6,  100
    ldi   r6,  0
    lds   r6,  100

    jump  after_jump
    ldi   r7,  0xDEAD
after_jump:
    ldi   r7,  0xBEEF

    ldi   r8,  0
    breq  r8,  r0, breq_taken
    ldi   r9,  0xBAD1
breq_taken:
    ldi   r9,  0xC001

    ldi   r10, 5
    brne  r10, r0, brne_taken
    ldi   r11, 0xBAD2
brne_taken:
    ldi   r11, 0xCAFE

    ldi   r12, 0x00FF
    ldi   r13, 4
    shl   r12, r13
    ldi   r14, 2
    shr   r12, r14

    ldi   r15, 0xFF80
    sar   r15, r13

    ldi   r16, 0x8001
    rol   r16, r13

    ldi   r17, 0xFFFF
    ldi   r19, 0xFFFF
    mul   r17, r19

    ldi   r20, 0x80FF
    ldi   r21, 0x0102
    add.b r20, r21

    ldi   r22, 0x1010
    ldi   r23, 0x0820
    sub.b r22, r23

    ldi   r24, 0x0F0A
    ldi   r26, 0x0205
    mul.b r24, r26

    ldi   r27, 100
    ldi   r29, 7
    div   r27, r29

    ldi   r30, 123
    div   r30, r0

halt:
    jump  halt
