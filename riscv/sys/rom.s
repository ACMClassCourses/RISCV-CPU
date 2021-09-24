	.section .rom,"ax"
	.globl main

	li sp, 0x00020000
	jal main
	li a0, 0xff
.L0:
	lui	a3, 0x30
	sb a0, 4(a3)
	j .L0
