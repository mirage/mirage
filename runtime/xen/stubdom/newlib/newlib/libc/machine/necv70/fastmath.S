	.globl	_fast_sin
_fast_sin:
	fsin.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_sinf
_fast_sinf:
	fsin.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_cos
_fast_cos:
	fcos.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_cosf
_fast_cosf:
	fcos.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_tan
_fast_tan:
	ftan.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_tanf
_fast_tanf:
	ftan.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0



	.globl	_fast_fabs
_fast_fabs:
	fabs.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_fabsf
_fast_fabsf:
	fabs.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_sqrt
_fast_sqrt:
	fsqrt.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_sqrtf
_fast_sqrtf:
	fsqrt.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_acos
_fast_acos:
	facos.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_acosf
_fast_acosf:
	facos.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_asin
_fast_asin:
	fasin.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_asinf
_fast_asinf:
	fasin.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_atan
_fast_atan:
	fatan.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_atanf
_fast_atanf:
	fatan.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_cosh
_fast_cosh:
	fcosh.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_coshf
_fast_coshf:
	fcosh.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_sinh
_fast_sinh:
	fsin.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_sinhf
_fast_sinhf:
	fsin.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_tanh
_fast_tanh:
	ftanh.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_tanhf
_fast_tanhf:
	ftanh.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_atanh
_fast_atanh:
	fatanh.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_atanhf
_fast_atanhf:
	fatanh.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0

	.globl	_fast_exp2
_fast_exp2:
	fexp2.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_exp2f
_fast_exp2f:
	fexp2.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_exp10
_fast_exp10:
	fexp10.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_exp10f
_fast_exp10f:
	fexp10.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_expe
_fast_expe:
	fexpe.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_expef
_fast_expef:
	fexpe.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_log2
_fast_log2:
	flog2.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_log2f
_fast_log2f:
	flog2.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0

	.globl	_fast_log10
_fast_log10:
	flog10.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_log10f
_fast_log10f:
	flog10.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


	.globl	_fast_loge
_fast_loge:
	floge.l	[ap],[ap]
	mov.d	[ap],r0
	ret	#0


	.globl	_fast_logef
_fast_logef:
	floge.s	[ap],[ap]
	mov.w	[ap],r0
	ret	#0


