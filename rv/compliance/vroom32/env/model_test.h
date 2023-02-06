#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H
#define RVMODEL_DATA_SECTION \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;
//        .pushsection .tohost,"aw",@progbits;                            \
//        .align 8; .global tohost; tohost: .dword 0;                     \
//        .align 8; .global fromhost; fromhost: .dword 0;                 \
//        .popsection;                                                    \
//


#define TESTNUM x30
#undef XVTEST_PASS
#define XVTEST_PASS li a0, 1;  csrw 0x8f4, a0

#undef XVTEST_FAIL
#define XVTEST_FAIL sll a0, TESTNUM, 1; csrw 0x8f3, a0

#define RSIZE 8
// _SP = (volatile register)
#define LOCAL_IO_PUSH(_SP)                                              \
    la      _SP,  begin_regstate;                                       \
    sw      x1,   (1*RSIZE)(_SP);                                       \
    sw      x5,   (5*RSIZE)(_SP);                                       \
    sw      x6,   (6*RSIZE)(_SP);                                       \
    sw      x8,   (8*RSIZE)(_SP);                                       \
    sw      x10,  (10*RSIZE)(_SP);

// _SP = (volatile register)
#define LOCAL_IO_POP(_SP)                                               \
    la      _SP,   begin_regstate;                                      \
    lw      x1,   (1*RSIZE)(_SP);                                       \
    lw      x5,   (5*RSIZE)(_SP);                                       \
    lw      x6,   (6*RSIZE)(_SP);                                       \
    lw      x8,   (8*RSIZE)(_SP);                                       \
    lw      x10,  (10*RSIZE)(_SP);
#define LOCAL_IO_WRITE_GPR(_R)                                          \
    mv          a0, _R;                                                 \
    jal         FN_WriteA0;

#define LOCAL_IO_WRITE_FPR(_F)                                          \
    fmv.x.s     a0, _F;                                                 \
    jal         FN_WriteA0;

#define LOCAL_IO_WRITE_DFPR(_V1, _V2)                                   \
    mv          a0, _V1;                                                \
    jal         FN_WriteA0; \
    mv          a0, _V2; \
    jal         FN_WriteA0; \

#define LOCAL_IO_WRITE_DFPRX(_F)                                   \
    fmv.x.d     a0, _F;                                                 \
    jal         FN_WriteA0; 

#define LOCAL_IO_PUTC(_R)                                               \
    csrw       0x8f0,_R                                               \

// _SP = (volatile register)
#define LOCAL_IO_WRITE_STR(_STR) XVTEST_IO_WRITE_STR(x31, _STR)
#define XVTEST_IO_WRITE_STR(_SP, _STR)                                  \
    LOCAL_IO_PUSH(_SP)                                                  \
    .section .data.string;                                              \
20001:                                                                  \
    .string _STR;                                                       \
    .section .text.init;                                                \
    la a0, 20001b;                                                      \
    jal FN_WriteStr;                                                    \
    LOCAL_IO_POP(_SP)

// Assertion violation: file file.c, line 1234: (expr)
// _SP = (volatile register)
// _R = GPR
// _I = Immediate
#define STRINGIFY(x) #x
#define TOSTRING(x)  STRINGIFY(x)
#define XVTEST_IO_ASSERT_GPR_EQ(_SP, _R, _I)                            \
    LOCAL_IO_PUSH(_SP)                                                  \
    mv          s0, _R;                                                 \
    li          t0, _I;                                                 \
    beq         s0, t0, 20002f;                                         \
    LOCAL_IO_WRITE_STR("Assertion violation: file ");                   \
    LOCAL_IO_WRITE_STR(__FILE__);                                       \
    LOCAL_IO_WRITE_STR(", line ");                                      \
    LOCAL_IO_WRITE_STR(TOSTRING(__LINE__));                             \
    LOCAL_IO_WRITE_STR(": ");                                           \
    LOCAL_IO_WRITE_STR(# _R);                                           \
    LOCAL_IO_WRITE_STR("(");                                            \
    LOCAL_IO_WRITE_GPR(s0);                                             \
    LOCAL_IO_WRITE_STR(") != ");                                        \
    LOCAL_IO_WRITE_STR(# _I);                                           \
    LOCAL_IO_WRITE_STR("\n");                                           \
    li TESTNUM, 100;                                                    \
    XVTEST_FAIL;                                                        \
20002:                                                                  \
    LOCAL_IO_POP(_SP)

// _F = FPR
// _C = GPR
// _I = Immediate
#define XVTEST_IO_ASSERT_SFPR_EQ(_F, _R, _I)                            \
    fmv.x.s     _R, _F;                                                 \
    li	     	a0, _I;                                                 \
    beq         _R, a0, 20003f;                                         \
    LOCAL_IO_WRITE_STR("Assertion violation: file ");                   \
    LOCAL_IO_WRITE_STR(__FILE__);                                       \
    LOCAL_IO_WRITE_STR(", line ");                                      \
    LOCAL_IO_WRITE_STR(TOSTRING(__LINE__));                             \
    LOCAL_IO_WRITE_STR(": ");                                           \
    LOCAL_IO_WRITE_STR(# _F);                                           \
    LOCAL_IO_WRITE_STR("(");                                            \
    LOCAL_IO_WRITE_FPR(_F);                                             \
    LOCAL_IO_WRITE_STR(") != ");                                        \
    LOCAL_IO_WRITE_STR(# _I);                                           \
    LOCAL_IO_WRITE_STR("\n");                                           \
    li TESTNUM, 100;                                                    \
    XVTEST_FAIL;                                                        \
20003:

// _D = DFPR
// _R = GPR
// _I = Immediate
#define XVTEST_IO_ASSERT_DFPR_EQ(_D, _R, _I)                            \
    fmv.x.d     _R, _D;                                                 \
    li          a0, _I;							\
    beq         _R, a0, 20005f;                                         \
    LOCAL_IO_WRITE_STR("Assertion violation: file ");                   \
    LOCAL_IO_WRITE_STR(__FILE__);                                       \
    LOCAL_IO_WRITE_STR(", line ");                                      \
    LOCAL_IO_WRITE_STR(TOSTRING(__LINE__));                             \
    LOCAL_IO_WRITE_STR(": ");                                           \
    LOCAL_IO_WRITE_STR(# _D);                                           \
    LOCAL_IO_WRITE_STR("(");                                            \
    LOCAL_IO_WRITE_DFPRX(_D);                                            \
    LOCAL_IO_WRITE_STR(") != ");                                        \
    LOCAL_IO_WRITE_STR(# _I);                                           \
    LOCAL_IO_WRITE_STR("\n");                                           \
    li TESTNUM, 100;                                                    \
    XVTEST_FAIL;                                                        \
20005:

//
// FN_WriteStr: Uses a0, t0
//
FN_WriteStr:
    mv          t0, a0;
10000:
    lbu         a0, (t0);
    addi        t0, t0, 1;
    beq         a0, zero, 10000f;
    LOCAL_IO_PUTC(a0);
    j           10000b;
10000:
    ret;

//
// FN_WriteA0: write register a0(x10) (destroys a0(x10), t0-t2(x5-x7))
//
FN_WriteA0:
        mv          t0, a0
        // determine architectural register width
        li          a0, -1
        srli        a0, a0, 31
        srli        a0, a0, 1
        bnez        a0, FN_WriteA0_64

FN_WriteA0_32:
        // reverse register when xlen is 32
        li          t1, 8
10000:  slli        t2, t2, 4
        andi        a0, t0, 0xf
        srli        t0, t0, 4
        or          t2, t2, a0
        addi        t1, t1, -1
        bnez        t1, 10000b
        li          t1, 8
        j           FN_WriteA0_common

FN_WriteA0_64:
        // reverse register when xlen is 64
        li          t1, 16
10000:  slli        t2, t2, 4
        andi        a0, t0, 0xf
        srli        t0, t0, 4
        or          t2, t2, a0
        addi        t1, t1, -1
        bnez        t1, 10000b
        li          t1, 16

FN_WriteA0_common:
        // write reversed characters
        li          t0, 10
10000:  andi        a0, t2, 0xf
        blt         a0, t0, 10001f
        addi        a0, a0, 'a'-10
        j           10002f
10001:  addi        a0, a0, '0'
10002:  LOCAL_IO_PUTC(a0)
        srli        t2, t2, 4
        addi        t1, t1, -1
        bnez        t1, 10000b
        ret

//RV_COMPLIANCE_HALT
#define RVMODEL_HALT                                              \
	la t5, begin_signature;	\
	la t6, end_signature;	\
2:	beq	t5, t6, 1f; \
		lw	t0, (t5);\
		jal	FN_WriteA0_32; \
		li a0, '\n';\
    		LOCAL_IO_PUTC(a0); \
		add	t5, t5, 4;\
		j	2b;\
1:	li a0, 0x10101010; \
	csrw 0x8f4, a0 ;

//  li x1, 1;                                                                   \
//  write_tohost:                                                               \
//    sw x1, tohost, t5;                                                        \
//    j write_tohost;

//
// go into 32-bit mode - thus needs to be 32-bit code that runs in 32-bit
#define RVMODEL_BOOT \
	csrr	a0, misa;\
	sll	a0, a0, 1;\
	srl	a0, a0, 1;\
	li	a1, 0x40000000;\
	sll	a1, a1, 16;\
	sll	a1, a1, 16;\
	or	a0, a0, a1;\
	csrw	misa, a0

//RV_COMPLIANCE_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                              \
  RVMODEL_DATA_SECTION                                                        \
  .align 4;\
  .global begin_signature; begin_signature:

//RV_COMPLIANCE_DATA_END
#define RVMODEL_DATA_END                                                      \
  .align 4;\
  .global end_signature; end_signature:  

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
// XVTEST_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//XVTEST_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//XVTEST_IO_ASSERT_SFPR_EQ(_R, _F, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)
//XVTEST_IO_ASSERT_DFPR_EQ(_R, _D, _I)

#define RVMODEL_SET_MSW_INT       \
 li t1, 1;                         \
 li t2, 0x2000000;                 \
 sw t1, 0(t2);

#define RVMODEL_CLEAR_MSW_INT     \
 li t2, 0x2000000;                 \
 sw x0, 0(t2);

#define RVMODEL_CLEAR_MTIMER_INT

#define RVMODEL_CLEAR_MEXT_INT


#endif // _COMPLIANCE_MODEL_H
