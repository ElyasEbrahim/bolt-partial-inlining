// Template for scripts/pool_loop.py: the output of
//   clang -O2 -g0 -S benchmarks/micro/pool/main.c
// (clang 23, AArch64) with the loop body replaced by the marker @LOOP@. The
// generator inserts hand-written variants of the loop there. The loop is
// entered at .LBB0_8 and left to .LBB0_10. Registers in the loop: x19 n,
// x20 window size, x21 acc, x22 window, x23 i, x24 RNG multiplier, x25 RNG
// state, x26 slot; the pool is at sp.
	.file	"main.c"
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0                          // -- Begin function main
.LCPI0_0:
	.xword	64                              // 0x40
	.xword	512                             // 0x200
	.text
	.globl	main
	.p2align	2
	.type	main,@function
main:                                   // @main
	.cfi_startproc
// %bb.0:
	sub	sp, sp, #128
	.cfi_def_cfa_offset 128
	stp	x29, x30, [sp, #48]             // 16-byte Folded Spill
	stp	x26, x25, [sp, #64]             // 16-byte Folded Spill
	stp	x24, x23, [sp, #80]             // 16-byte Folded Spill
	stp	x22, x21, [sp, #96]             // 16-byte Folded Spill
	stp	x20, x19, [sp, #112]            // 16-byte Folded Spill
	add	x29, sp, #48
	.cfi_def_cfa w29, 80
	.cfi_offset w19, -8
	.cfi_offset w20, -16
	.cfi_offset w21, -24
	.cfi_offset w22, -32
	.cfi_offset w23, -40
	.cfi_offset w24, -48
	.cfi_offset w25, -56
	.cfi_offset w26, -64
	.cfi_offset w30, -72
	.cfi_offset w29, -80
	cmp	w0, #2
	b.lt	.LBB0_3
// %bb.1:
	mov	w19, w0
	ldr	x0, [x1, #8]
	mov	x20, x1
	mov	x1, xzr
	mov	w2, wzr
	bl	strtol
	cmp	w19, #2
	mov	x19, x0
	b.ne	.LBB0_4
// %bb.2:
	mov	w20, #256                       // =0x100
	b	.LBB0_5
.LBB0_3:
	mov	w19, #57600                     // =0xe100
	mov	w20, #256                       // =0x100
	movk	w19, #1525, lsl #16
	b	.LBB0_5
.LBB0_4:
	ldr	x0, [x20, #16]
	mov	x1, xzr
	mov	w2, wzr
	bl	strtol
	mov	x20, x0
.LBB0_5:
	movi	v0.2d, #0000000000000000
	adrp	x8, .LCPI0_0
	mov	x0, x20
	ldr	q1, [x8, :lo12:.LCPI0_0]
	mov	w1, #8                          // =0x8
	str	xzr, [sp, #32]
	stp	q0, q0, [sp]
	stur	q1, [sp, #8]
	bl	calloc
	cmp	x19, #1
	b.lt	.LBB0_11
// %bb.6:
	mov	x24, #56605                     // =0xdd1d
	mov	x22, x0
	mov	x21, xzr
	movk	x24, #20332, lsl #16
	mov	x23, xzr
	mov	w25, #12345                     // =0x3039
	movk	x24, #62609, lsl #32
	movk	x24, #9541, lsl #48
	b	.LBB0_8
@LOOP@
.LBB0_10:
	ldp	x2, x3, [sp, #24]
	b	.LBB0_12
.LBB0_11:
	mov	x3, xzr
	mov	x2, xzr
	mov	x21, xzr
.LBB0_12:
	adrp	x0, .L.str
	add	x0, x0, :lo12:.L.str
	mov	x1, x19
	mov	x4, x21
	bl	printf
	mov	w0, wzr
	.cfi_def_cfa wsp, 128
	ldp	x20, x19, [sp, #112]            // 16-byte Folded Reload
	ldp	x22, x21, [sp, #96]             // 16-byte Folded Reload
	ldp	x24, x23, [sp, #80]             // 16-byte Folded Reload
	ldp	x26, x25, [sp, #64]             // 16-byte Folded Reload
	ldp	x29, x30, [sp, #48]             // 16-byte Folded Reload
	add	sp, sp, #128
	.cfi_def_cfa_offset 0
	.cfi_restore w19
	.cfi_restore w20
	.cfi_restore w21
	.cfi_restore w22
	.cfi_restore w23
	.cfi_restore w24
	.cfi_restore w25
	.cfi_restore w26
	.cfi_restore w30
	.cfi_restore w29
	ret
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        // -- End function
	.type	.L.str,@object                  // @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"pool n=%ld live=%zu slabs=%zu acc=%016llx\n"
	.size	.L.str, 43

	.ident	"Ubuntu clang version 23.1.6 (++20261103094202+2875c6073a7e-1~exp1~20261103214217.95)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
