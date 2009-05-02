/*
    Based on code of J.T. Conklin <jtc@netbsd.org> and drepper@cygnus.com
    Public domain.
    Adapted for "C" and for asmutils by Nick Kurshev <nickols_k@mail.ru>.
    I tried to collect the best snippets from other free GPL'ed projects:
    - DJGPP for DOS <www.delorie.com>
    - EMX for OS2 by Eberhard Mattes

    $Id: libm.c,v 1.6 2002/03/03 07:57:27 konst Exp $

 Why C but not asm?
 1. Although today gcc does not handle floating point as well as commercial
    compilers do, I believe that in the future versions gcc will be able to
    handle floating point better.
 2. Such function declaraton allows us to be independent from calling
    convention and build universal models.

 ChangeLog:
 0.13  -  initial implementation
 0.14  -  implementated basic function set and test suite
 0.15  -  fixed minor bugs, minor optimization and support for 80687
*/

/*
  Missing: erf(l,f), erfc(l,f), gamma(l,f), infnan,
          j0(l,f),  j1(l,f), jn(l,f), lgamma(l,f) lgamma(l,f)_r,
          llround(l,f), lround(l,f), mod(f,l), nan(l,f),
          nextafter(l,f),  nexttoward(l,f), remquo,  round(l,f), scalb(l,f),
          signbit, tgamma(l,f), y0(l,f),  y1(l,f),  yn(l,f)
*/

/*              
   ffreep is documented instruction for K7/Athlon processors, but all fpus
   since 387 undocumentedly support it and I have no reasons to not use it.
   Note: It should be used when top of fpu stack should be destroyed.
*/

# define __NO_MATH_INLINES	1
# define __USE_ISOC9X 1
# define __USE_MISC 1
# define __USE_XOPEN_EXTENDED 1
# define __USE_GNU 1
# define __USE_BSD 1
# define __USE_XOPEN 1
# define __USE_SVID 1
#include <math.h>

#if 1 /*__ATHLON__*/
#define FFREEP "ffreep"
#else
#define FFREEP "fstp"
#endif

typedef unsigned int uint32_t;

/*
  Brief description of FXAM:
Class               C3  C2  C1  C0
Unsupported          0   0   S   0
NaN                  0   0   S   1
Normal finite number 0   1   S   0
Infinity             0   1   S   1
Zero                 1   0   S   0
Empty                1   0   S   1
Denormal number      1   1   S   0
???                  1   1   S   1
Note: S means SIGN of st(0)
*/

#define FXAM_SW(sw, x)\
   asm("fxam\n"\
      "	fnstsw":"=a"(sw):"t"(x))

#define __SW_ISNAN(sw) ((sw&0x4500)==0x0100)
#define ISNAN(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISNAN(sw);\
}

#define __SW_ISSIGN(sw) (sw&0x0200)
#define ISSIGN(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISSIGN(sw);\
}

#define __SW_ISINF(sw) ((sw&0x4500)==0x0500)
#define ISINF(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISINF(sw);\
  if(__SW_ISSIGN(sw)) retval =- retval;\
}

#define __SW_ISZERO(sw) ((sw&0x4500)==0x4000)
#define ISZERO(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISZERO(sw);\
}

#define __SW_ISDENORM(sw) ((sw&0x4500)==0x4500)
#define ISDENORM(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISDENORM(sw);\
}

#define __SW_ISNORMAL(sw) ((sw&0x4500)==0x0400)
#define ISNORMAL(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISNORMAL(sw);\
}

#define ISFINITE(retval, x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  retval=__SW_ISNORMAL(sw)||__SW_ISZERO(sw);\
}

int (isnanf)(float x)
{
  register int retval;
  ISNAN(retval, x);
  return retval;
}

int (isnan)(double x)
{
  register int retval;
  ISNAN(retval, x);
  return retval;
}

int (isnanl)(long double x)
{
  register int retval;
  ISNAN(retval, x);
  return retval;
}

int (isfinitef)(float x)
{
  register int retval;
  ISFINITE(retval, x);
  return retval;
}

int (isfinite)(double x)
{
  register int retval;
  ISFINITE(retval, x);
  return retval;
}

int (isfinitel)(long double x)
{
  register int retval;
  ISFINITE(retval, x);
  return retval;
}

int (isnormalf)(float x)
{
  register int retval;
  ISNORMAL(retval, x);
  return retval;
}

int (isnormal)(double x)
{
  register int retval;
  ISNORMAL(retval, x);
  return retval;
}

int (isnormall)(long double x)
{
  register int retval;
  ISNORMAL(retval, x);
  return retval;
}

int (isinff)(float x)
{
  register int retval;
  ISINF(retval, x);
  return retval;
}

int (isinf)(double x)
{
  register int retval;
  ISINF(retval, x);
  return retval;
}

int (isinfl)(long double x)
{
  register int retval;
  ISINF(retval, x);
  return retval;
}

#ifndef FP_NAN
#define FP_NAN 0
#endif
#ifndef FP_INFINITE
#define FP_INFINITE 1
#endif
#ifndef FP_ZERO
#define FP_ZERO 2
#endif
#ifndef FP_SUBNORMAL
#define FP_SUBNORMAL 3
#endif
#ifndef FP_NORMAL
#define FP_NORMAL 4
#endif

int (__fpclassifyf)(float x)
{
  register int sw, retval;
  const uint32_t *xp;
  xp = (const uint32_t *)&x;
  FXAM_SW(sw, x);
  if(__SW_ISNAN(sw)) retval = FP_NAN;
  else
  if(__SW_ISINF(sw)) retval = FP_INFINITE;
  else
  if(__SW_ISZERO(sw)) retval = FP_ZERO;
  else
  if((xp[0] & ~0x80000000UL) < 0x01000000UL) retval = FP_SUBNORMAL;
  else
  retval = FP_NORMAL;
  return retval;
}

int (__fpclassify)(double x)
{
  register int sw, retval;
  const uint32_t *xp;
  xp = (const uint32_t *)&x;
  FXAM_SW(sw, x);
  if(__SW_ISNAN(sw)) retval = FP_NAN;
  else
  if(__SW_ISINF(sw)) retval = FP_INFINITE;
  else
  if(__SW_ISZERO(sw)) retval = FP_ZERO;
  else
  if(!xp[1]) retval = FP_SUBNORMAL;
  else
  retval = FP_NORMAL;
  return retval;
}

int (__fpclassifyl)(long double x)
{
  register int sw, retval;
  const uint32_t *xp;
  xp = (const uint32_t *)&x;
  FXAM_SW(sw, x);
  if(__SW_ISNAN(sw)) retval = FP_NAN;
  else
  if(__SW_ISINF(sw)) retval = FP_INFINITE;
  else
  if(__SW_ISZERO(sw)) retval = FP_ZERO;
  else
  if(!xp[2] && (xp[1] & 0x80000000UL) == 0) retval = FP_SUBNORMAL;
  else
  retval = FP_NORMAL;
  return retval;
}

#if __CPU__ > 586
#define __ISGREATER(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	seta	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st")
#else
#define __ISGREATER(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	testb	$0x45, %h0\n"\
      "	setz	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st","st(1)")
#endif

int (isgreaterf)(float x, float y)
{
  register int retval;
  __ISGREATER(retval, x, y);
  return retval;
}

int (isgreater)(double x, double y)
{
  register int retval;
  __ISGREATER(retval, x, y);
  return retval;
}

int (isgreaterl)(long double x, long double y)
{
  register int retval;
  __ISGREATER(retval, x, y);
  return retval;
}

#if __CPU__ > 586
#define __ISGREATEREQUAL(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	setae	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st")
#else
#define __ISGREATEREQUAL(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	testb	$0x05, %h0\n"\
      "	setz	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st","st(1)")
#endif

int (isgreaterequalf)(float x, float y)
{
  register int retval;
  __ISGREATEREQUAL(retval, x, y);
  return retval;
}

int (isgreaterequal)(double x, double y)
{
  register int retval;
  __ISGREATEREQUAL(retval, x, y);
  return retval;
}

int (isgreaterequall)(long double x, long double y)
{
  register int retval;
  __ISGREATEREQUAL(retval, x, y);
  return retval;
}

#if __CPU__ > 586
#define __ISLESS(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	seta	%b0"\
      :"=a"(retval)\
      :"u"(x),"t"(y)\
      :"st")
#else
#define __ISLESS(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	testb	$0x45, %h0\n"\
      "	setz	%b0"\
      :"=a"(retval)\
      :"u"(x),"t"(y)\
      :"st","st(1)")
#endif

int (islessf)(float x, float y)
{
  register int retval;
  __ISLESS(retval, x, y);
  return retval;
}

int (isless)(double x, double y)
{
  register int retval;
  __ISLESS(retval, x, y);
  return retval;
}

int (islessl)(long double x, long double y)
{
  register int retval;
  __ISLESS(retval, x, y);
  return retval;
}

#if __CPU__ > 586
#define __ISLESSEQUAL(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	setae	%b0"\
      :"=a"(retval)\
      :"u"(x),"t"(y)\
      :"st")
#else
#define __ISLESSEQUAL(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	testb	$0x05, %h0\n"\
      "	setz	%b0"\
      :"=a"(retval)\
      :"u"(x),"t"(y)\
      :"st","st(1)")
#endif

int (islessequalf)(float x, float y)
{
  register int retval;
  __ISLESSEQUAL(retval, x, y);
  return retval;
}

int (islessequal)(double x, double y)
{
  register int retval;
  __ISLESSEQUAL(retval, x, y);
  return retval;
}

int (islessequall)(long double x, long double y)
{
  register int retval;
  __ISLESSEQUAL(retval, x, y);
  return retval;
}

#if __CPU__ > 586
#define __ISLESSGREATER(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	setne	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st")
#else
#define __ISLESSGREATER(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	testb	$0x44, %h0\n"\
      "	setz	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st","st(1)")
#endif

int (islessgreaterf)(float x, float y)
{
  register int retval;
  __ISLESSGREATER(retval, x, y);
  return retval;
}

int (islessgreater)(double x, double y)
{
  register int retval;
  __ISLESSGREATER(retval, x, y);
  return retval;
}

int (islessgreaterl)(long double x, long double y)
{
  register int retval;
  __ISLESSGREATER(retval, x, y);
  return retval;
}

#if __CPU__ > 586
#define __ISUNORDERED(retval, x, y)\
   asm("fucomip	%1, %2\n"\
      "	setp	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st")
#else
#define __ISUNORDERED(retval, x, y)\
   asm("fucompp\n"\
      "	fnstsw\n"\
      "	sahf\n"\
      "	setp	%b0"\
      :"=a"(retval)\
      :"u"(y),"t"(x)\
      :"st","st(1)")
#endif

int (isunorderedf)(float x, float y)
{
  register int retval;
  __ISUNORDERED(retval, x, y);
  return retval;
}

int (isunordered)(double x, double y)
{
  register int retval;
  __ISUNORDERED(retval, x, y);
  return retval;
}

int (isunorderedl)(long double x, long double y)
{
  register int retval;
  __ISUNORDERED(retval, x, y);
  return retval;
}

/* acos = atan (sqrt(1 - x^2) / x) */

#define IEEE754_ACOS(ret,x)\
   asm("fld	%0\n"\
      "	fmul	%0\n"\
      "	fld1\n"\
      "	fsubp\n"\
      "	fsqrt\n"\
      "	fxch	%%st(1)\n"\
      "	fpatan"   :\
      "=t"(ret)   :\
      "0"(x)      :\
      "st(1)")

float (acosf)(float x)
{
  register float ret;
  IEEE754_ACOS(ret,x);
  return ret;
}

double (acos)(double x)
{
  register double ret;
  IEEE754_ACOS(ret,x);
  return ret;
}

long double (acosl)(long double x)
{
  register long double ret;
  IEEE754_ACOS(ret,x);
  return ret;
}

/* asin = atan (x / sqrt(1 - x^2)) */

#define IEEE754_ASIN(ret,x)\
   asm("fld	%0\n"\
      "	fmul	%0\n"\
      "	fld1\n"\
      "	fsubp\n"\
      "	fsqrt\n"\
      "	fpatan"   :\
      "=t"(ret)   :\
      "0"(x)      :\
      "st(1)")

float (asinf)(float x)
{
  register float ret;
  IEEE754_ASIN(ret,x);
  return ret;
}

double (asin)(double x)
{
  register double ret;
  IEEE754_ASIN(ret,x);
  return ret;
}

long double (asinl)(long double x)
{
  register long double ret;
  IEEE754_ASIN(ret,x);
  return ret;
}

#define IEEE754_ATAN2(ret,y,x)\
   asm("fpatan" :\
       "=t"(ret):\
       "u"(y),\
       "0"(x)   :\
       "st(1)")

float (atan2f)(float y,float x)
{
  register float ret;
  IEEE754_ATAN2(ret,y,x);
  return ret;
}

double (atan2)(double y,double x)
{
  register double ret;
  IEEE754_ATAN2(ret,y,x);
  return ret;
}

long double (atan2l)(long double y,long double x)
{
  register long double ret;
  IEEE754_ATAN2(ret,y,x);
  return ret;
}

/* e^x = 2^(x * log2(e)) */
#define IEEE754_EXP(ret,x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  if(__SW_ISINF(sw))\
  {\
     if(__SW_ISSIGN(sw)) ret = 0.;\
     else                ret = x;\
  }\
  else\
  asm("fldl2e\n"\
      "	fxch	%%st(1)\n"\
      "	fmulp\n"\
      "	fst	%%st(1)\n"\
      "	frndint\n"\
      "	fst	%%st(2)\n"\
      "	fsubrp\n"\
      "	f2xm1\n"\
      "	fld1\n"\
      "	faddp\n"\
      "	fscale":\
        "=t"(ret):\
        "0"(x):\
        "st(1)", "st(2)");\
}

float (expf)(float x)
{
  register float ret;
  IEEE754_EXP(ret,x);
  return ret;
}

double (exp)(double x)
{
  register double ret;
  IEEE754_EXP(ret,x);
  return ret;
}

long double (expl)(long double x)
{
  register long double ret;
  IEEE754_EXP(ret,x);
  return ret;
}

/* e^x = 2^(x * log2l(10)) */

#define IEEE754_EXP10(ret,x)\
{\
  register int sw;\
  FXAM_SW(sw, x);\
  if(__SW_ISINF(sw))\
  {\
     if(__SW_ISSIGN(sw)) ret = 0.;\
     else                ret = x;\
  }\
  else\
  asm("fldl2t\n"\
      "	fxch	%%st(1)\n"\
      "	fmulp\n"\
      "	fst	%%st(1)\n"\
      "	frndint\n"\
      "	fst	%%st(2)\n"\
      "	fsubrp\n"\
      "	f2xm1\n"\
      "	fld1\n"\
      "	faddp\n"\
      "	fscale\n"\
      "	ffree	%%st(1)\n":\
        "=t"(ret):\
        "0"(x):\
        "st(2)");\
}

float (exp10f)(float x)
{
  register float ret;
  IEEE754_EXP10(ret,x);
  return ret;
}

double (exp10)(double x)
{
  register double ret;
  IEEE754_EXP10(ret,x);
  return ret;
}

long double (exp10l)(long double x)
{
  register long double ret;
  IEEE754_EXP10(ret,x);
  return ret;
}

#define IEEE754_FMOD(ret,x,y)\
  asm("1:\n"\
      "	fprem\n"\
      "	fstsw	%%ax\n"\
      "	sahf\n"\
      "	jp  	1b\n":\
      "=t"(ret):\
      "u"(y),\
      "0"(x):\
      "eax","st(1)")

float (fmodf)(float x,float y)
{
  register float ret;
  IEEE754_FMOD(ret,x,y);
  return ret;
}

double (fmod)(double x,double y)
{
  register double ret;
  IEEE754_FMOD(ret,x,y);
  return ret;
}

long double (fmodl)(long double x,long double y)
{
  long double ret;
  IEEE754_FMOD(ret,x,y);
  return ret;
}

/* We have to test whether any of the parameters is Inf.
   In this case the result is infinity. */
#define IEEE754_HYPOT(retval,x,y)\
   asm (\
      "fxam\n"\
      "	fnstsw\n"\
      "	movb	%%ah, %%ch\n"\
      "	fxch	%2\n"\
      "	fld	%0\n"\
      "	fstp	%0\n"\
      "	fxam\n"\
      "	fnstsw\n"\
      "	movb	%%ah, %%al\n"\
      "	orb	%%ch, %%ah\n"\
      "	sahf\n"\
      "	jc	1f\n"\
      "	fxch	%2\n"\
      "	fmul	%0\n"\
      "	fxch\n"\
      "	fmul	%0\n"\
      "	faddp\n"\
      "	fsqrt\n"\
      "	jmp	2f\n"\
"1:	andb	$0x45, %%al\n"\
      "	cmpb	$5, %%al\n"\
      "	je	3f\n"\
      "	andb	$0x45, %%ch\n"\
      "	cmpb	$5, %%ch\n"\
      "	jne	4f\n"\
      "	fxch\n"\
"3:	fstp	%2\n"\
      "	fabs\n"\
      "	jmp	2f\n"\
"4:	testb	$1, %%al\n"\
      "	jnz	5f\n"\
      "	fxch\n"\
"5:	fstp	%2\n"\
"2:":\
      "=t"(retval)   :\
      "0"(x),"u"(y)  :\
      "eax","ecx","st(1)")

float (hypotf)(float x,float y)
{
  register float retval;
  IEEE754_HYPOT(retval,x,y);
  return retval;
}

double (hypot)(double x,double y)
{
  register double retval;
  IEEE754_HYPOT(retval,x,y);
  return retval;
}

long double (hypotl)(long double x,long double y)
{
  register long double retval;
  IEEE754_HYPOT(retval,x,y);
  return retval;
}

/*
   We pass address of contstants one and limit through registers
   for non relocatable system (-fpic -fPIC)
*/

#define IEEE754_LOG(ret,x)\
   asm("fldln2\n"\
      "	fxch\n"\
      "	fyl2x":\
      "=t"(ret):\
      "0"(x))

float (logf)(float x)
{
  register float ret;
  IEEE754_LOG(ret,x);
  return ret;
}

double (log)(double x)
{
  register double ret;
  IEEE754_LOG(ret,x);
  return ret;
}

long double (logl)(long double x)
{
  register long double ret;
  IEEE754_LOG(ret,x);
  return ret;
}

#define IEEE754_LOG10(ret,x)\
   asm("fldlg2\n"\
      "	fxch\n"\
      "	fyl2x":\
      "=t"(ret):\
      "0"(x))

float (log10f)(float x)
{
  register float ret;
  IEEE754_LOG10(ret,x);
  return ret;
}

double (log10)(double x)
{
  register double ret;
  IEEE754_LOG10(ret,x);
  return ret;
}

long double (log10l)(long double x)
{
  register long double ret;
  IEEE754_LOG10(ret,x);
  return ret;
}

#define IEEE754_REMAINDER(ret,x,y)\
   asm("\n1:	fprem1\n"\
      "	fstsw	%%ax\n"\
      "	sahf\n"\
      "	jp	1b\n"\
      "	fstp	%2"  :\
      "=t"(ret)      :\
      "0"(x),\
      "u"(y):\
      "st(1)","eax")

float (remainderf)(float x,float y)
{
  register float ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

double (remainder)(double x,double y)
{
  register double ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

long double (remainderl)(long double x,long double y)
{
  register long double ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

float (dremf)(float x,float y)
{
  register float ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

double (drem)(double x,double y)
{
  register double ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

long double (dreml)(long double x,long double y)
{
  register long double ret;
  IEEE754_REMAINDER(ret,x,y);
  return ret;
}

#define IEEE754_SQRT(ret,x)\
   asm("fsqrt"  :\
       "=t"(ret):\
       "0"(x))

float (sqrtf)(float x)
{
  register float ret;
  IEEE754_SQRT(ret,x);
  return ret;
}

double (sqrt)(double x)
{
  register double ret;
  IEEE754_SQRT(ret,x);
  return ret;
}

long double (sqrtl)(long double x)
{
  register long double ret;
  IEEE754_SQRT(ret,x);
  return ret;
}

#define __ATAN(ret,x)\
   asm("fld1\n"\
      "	fpatan":\
      "=t"(ret):\
      "0"(x))

float (atanf)(float x)
{
  register float ret;
  __ATAN(ret,x);
  return ret;
}

double (atan)(double x)
{
  register double ret;
  __ATAN(ret,x);
  return ret;
}

long double (atanl)(long double x)
{
  register long double ret;
  __ATAN(ret,x);
  return ret;
}

#define __CEIL(ret,val,cw,new_cw)\
   asm("fstcw	%0":"=m"(cw)::"memory");\
   new_cw = (cw | 0x800) & 0xfbff;\
   asm("fldcw	%3\n"\
      "	frndint\n"\
      "	fldcw	%2"\
      :"=t"(ret)\
      :"0"(val),\
      "m"(cw),\
      "m"(new_cw))

float (ceilf)(float val)
{
  unsigned int cw;
  unsigned int new_cw;
  register float ret;
  __CEIL(ret,val,cw,new_cw);
  return ret;
}

double (ceil)(double val)
{
  unsigned int cw;
  unsigned int new_cw;
  register double ret;
  __CEIL(ret,val,cw,new_cw);
  return ret;
}

long double (ceill)(long double val)
{
  unsigned int cw;
  unsigned int new_cw;
  register long double ret;
  __CEIL(ret,val,cw,new_cw);
  return ret;
}

float (copysignf)(float x,float y)
{
  register int sw;
  uint32_t *xp;
  FXAM_SW(sw, y);
  xp = (uint32_t *)&x;
  if(__SW_ISSIGN(sw)) xp[0] |= 0x80000000UL;
  else                xp[0] &= ~0x80000000UL;
  return x;
}

double (copysign)(double x,double y)
{
  register int sw;
  uint32_t *xp;
  FXAM_SW(sw, y);
  xp = (uint32_t *)&x;
  if(__SW_ISSIGN(sw)) xp[1] |= 0x80000000UL;
  else                xp[1] &= ~0x80000000UL;
  return x;
}

long double (copysignl)(long double x,long double y)
{
  register int sw;
  uint32_t *xp;
  FXAM_SW(sw, y);
  xp = (uint32_t *)&x;
  if(__SW_ISSIGN(sw)) xp[2] |= 0x8000UL;
  else                xp[2] &= ~0x8000UL;
  return x;
}

#define __FTRIG(name,ret,x)\
   asm(name\
      "	fnstsw	%%ax\n"\
      "	testb	$0x04, %%ah\n"\
      "	je	2f\n"\
      "	fldpi\n"\
      "	fadd	%0\n"\
      "	fxch	%%st(1)\n"\
"1:	fprem1\n"\
      "	fnstsw	%%ax\n"\
      "	testb	$0x04, %%ah\n"\
      "	jne	1b\n"\
      "	fstp	%%st(1)\n"\
      "	"name\
"2:":\
      "=t"(ret)    :\
      "0"(x):\
      "st(1)","eax")

float (cosf)(float x)
{
  register float ret;
  __FTRIG("fcos\n",ret,x);
  return ret;
}

double (cos)(double x)
{
  register double ret;
  __FTRIG("fcos\n",ret,x);
  return ret;
}

long double (cosl)(long double x)
{
  register long double ret;
  __FTRIG("fcos\n",ret,x);
  return ret;
}

float (sinf)(float x)
{
  register float ret;
  __FTRIG("fsin\n",ret,x);
  return ret;
}

double (sin)(double x)
{
  register double ret;
  __FTRIG("fsin\n",ret,x);
  return ret;
}

long double (sinl)(long double x)
{
  register long double ret;
  __FTRIG("fsin\n",ret,x);
  return ret;
}

#define __FTAN(ret,x)\
   asm("fptan\n"\
      "	fnstsw	%%ax\n"\
      "	testb	$0x04, %%ah\n"\
      "	je	2f\n"\
      "	fldpi\n"\
      "	fadd	%0\n"\
      "	fxch	%%st(1)\n"\
"1:	fprem1\n"\
      "	fnstsw	%%ax\n"\
      "	testb	$0x04, %%ah\n"\
      "	jne	1b\n"\
      "	fstp	%%st(1)\n"\
      "	fptan\n"\
"2:\n"\
      FFREEP"	%0":\
      "=t"(ret)    :\
      "0"(x):\
      "st(1)","eax")

float (tanf)(float x)
{
  register float ret;
  __FTAN(ret,x);
  return ret;
}

double (tan)(double x)
{
  register double ret;
  __FTAN(ret,x);
  return ret;
}

long double (tanl)(long double x)
{
  register long double ret;
  __FTAN(ret,x);
  return ret;
}

#define IEEE754_EXP2(ret,x)\
   asm("fxam\n"\
      "	fstsw	%%ax\n"\
      "	movb	$0x45, %%dh\n"\
      "	andb	%%ah, %%dh\n"\
      "	cmpb	$0x05, %%dh\n"\
      "	je	1f\n"\
      "	fld	%0\n"\
      "	frndint\n"\
      "	fsubr	%0, %%st(1)\n"\
      "	fxch\n"\
      "	f2xm1\n"\
      "	fld1\n"\
      "	faddp\n"\
      "	fscale\n"\
      "	fstp	%%st(1)\n"\
      "	jmp	2f\n"\
"1:	testl	$0x200, %%eax\n"\
      "	jz	2f\n"\
      FFREEP"	%0\n"\
      "	fldz\n"\
"2:":\
      "=t"(ret):\
      "0"(x):\
      "eax","edx")

float (exp2f)(float x)
{
  register float ret;
  IEEE754_EXP2(ret,x);
  return ret;
}

double (exp2)(double x)
{
  register double ret;
  IEEE754_EXP2(ret,x);
  return ret;
}

long double (exp2l)(long double x)
{
  register long double ret;
  IEEE754_EXP2(ret,x);
  return ret;
}

#define __FDIM(ret,x,y)\
   asm("fsubp	%2\n"\
      "	fabs":\
       "=t"(ret):\
       "0"(y),\
       "u"(x))

float (fdimf)(float x, float y)
{
  register float ret;
  __FDIM(ret,x,y);
  return ret;
}

double (fdim)(double x, double y)
{
  register double ret;
  __FDIM(ret,x,y);
  return ret;
}

long double (fdiml)(long double x, long double y)
{
  register long double ret;
  __FDIM(ret,x,y);
  return ret;
}


#define __FLOOR(ret,val,cw,new_cw)\
   asm("fstcw	%0":"=m"(cw)::"memory");\
   new_cw = (cw | 0x400) & 0xf7ff;\
   asm("fldcw	%3\n"\
      "	frndint\n"\
      "	fldcw	%2"\
      :"=t"(ret)\
      :"0"(val),\
      "m"(cw),\
      "m"(new_cw))

float (floorf)(float val)
{
  unsigned int cw;
  unsigned int new_cw;
  register float ret;
  __FLOOR(ret,val,cw,new_cw);
  return ret;
}

double (floor)(double val)
{
  unsigned int cw;
  unsigned int new_cw;
  register double ret;
  __FLOOR(ret,val,cw,new_cw);
  return ret;
}

long double (floorl)(long double val)
{
  unsigned int cw;
  unsigned int new_cw;
  register long double ret;
  __FLOOR(ret,val,cw,new_cw);
  return ret;
}

#define __FMA(x,y,z) ((x*y)+z)

float (fmaf)(float x,float y,float z)
{
  return __FMA(x,y,z);
}

double (fma)(double x,double y,double z)
{
  return __FMA(x,y,z);
}

long double (fmal)(long double x,long double y,long double z)
{
  return __FMA(x,y,z);
}

#if __CPU__ > 586
#define __FMAX(ret,x,y)\
   asm(\
      "	fucomi	%0, %0\n"\
      "	fcmovu	%2, %0\n"\
      "	fxch\n"\
      "	fucomi	%2, %0\n"\
      "	fcmovb	%2, %0\n"\
      "	fstp	%2":\
      "=t"(ret):\
      "0"(y),\
      "u"(x))
#else
#define __FMAX(ret,x,y)\
   asm("fxam\n"\
      "	fnstsw\n"\
      "	andb	$0x45, %%ah\n"\
      "	fxch	%2\n"\
      "	cmpb	$0x01, %%ah\n"\
      "	je	1f\n"\
      "	fucom	%2\n"\
      "	fnstsw\n"\
      "	sahf\n"\
      "	jnc	1f\n"\
      "	fxch	%2\n"\
"1:	fstp	%2":\
      "=t"(ret):\
      "0"(y),\
      "u"(x):\
      "eax","st(1)")
#endif

float (fmaxf)(float x, float y)
{
  register float ret;
  __FMAX(ret,x,y);
  return ret;
}

double (fmax)(double x, double y)
{
  register double ret;
  __FMAX(ret,x,y);
  return ret;
}

long double (fmaxl)(long double x, long double y)
{
  register long double ret;
  __FMAX(ret,x,y);
  return ret;
}

#if __CPU__ > 586
#define __FMIN(ret,x,y)\
   asm(\
      "	fucomi	%0, %0\n"\
      "	fcmovu	%2, %0\n"\
      "	fucomi	%2, %0\n"\
      "	fcmovnb	%2, %0\n"\
      "	fstp	%2":\
      "=t"(ret):\
      "0"(y),\
      "u"(x))
#else
#define __FMIN(ret,x,y)\
   asm("fxam\n"\
      "	fnstsw\n"\
      "	andb	$0x45, %%ah\n"\
      "	cmpb	$0x01, %%ah\n"\
      "	je	1f\n"\
      "	fucom	%2\n"\
      "	fnstsw\n"\
      "	sahf\n"\
      "	jc	2f\n"\
"1:	fxch	%2\n"\
"2:	fstp	%2\n":\
       "=t"(ret):\
       "0"(y),\
       "u"(x):\
       "eax","st(1)")
#endif

float (fminf)(float x, float y)
{
  register float ret;
  __FMIN(ret,x,y);
  return ret;
}

double (fmin)(double x, double y)
{
  register double ret;
  __FMIN(ret,x,y);
  return ret;
}

long double (fminl)(long double x, long double y)
{
  register long double ret;
  __FMIN(ret,x,y);
  return ret;
}

/*
 frexp.s (emx+gcc) -- Copyright (c) 1992-1993 by Steffen Haecker
                      Modified 1993-1996 by Eberhard Mattes
*/

#define __FREXP(result,x,eptr)\
{\
  register long double minus_one;\
  asm("fld1\n"\
      "	fchs":\
      "=t"(minus_one));\
   *eptr = 0;\
   asm("ftst\n"\
      "	fstsw	%%ax\n"\
      "	andb	$0x41, %%ah\n"\
      "	xorb	$0x40, %%ah\n"\
      "	jz	1f\n"\
      "	fxtract\n"\
      "	fxch	%2\n"\
      "	fistpl	(%3)\n"\
      "	fscale\n"\
      "	incl	(%3)\n"\
"1:	fstp	%2":\
       "=t"(retval):\
       "0"(x),\
       "u"(minus_one),\
       "r"(eptr):\
       "eax","memory","st(1)");\
}
float (frexpf)(float x, int *eptr)
{
  register float retval;
  __FREXP(retval,x,eptr);
  return retval;
}

double (frexp)(double x, int *eptr)
{
  register double retval;
  __FREXP(retval,x,eptr);
  return retval;
}

long double (frexpl)(long double x, int *eptr)
{
  register long double retval;
  __FREXP(retval,x,eptr);
  return retval;
}

#define __ILOGB(ret,x)\
   asm("fxtract\n"\
      "	fstp	%1\n"\
      "	fistpl	%0\n"\
      "	fwait" :\
      "=m"(ret):\
      "t"(x))

int (ilogbf)(float x)
{
  int ret;
  __ILOGB(ret,x);
  return ret;
}

int (ilogb)(double x)
{
  int ret;
  __ILOGB(ret,x);
  return ret;
}

int (ilogbl)(long double x)
{
  int ret;
  __ILOGB(ret,x);
  return ret;
}

#define __LLRINT(ret,x)\
   asm("fistpll	%0\n"\
      "	fwait" :\
      "=m"(ret):\
      "t"(x)   :\
      "st")

long long int (llrintf)(float x)
{
  long long int ret;
  __LLRINT(ret,x);
  return ret;
}

long long int (llrint)(double x)
{
  long long int ret;
  __LLRINT(ret,x);
  return ret;
}

long long int (llrintl)(long double x)
{
  long long int ret;
  __LLRINT(ret,x);
  return ret;
}

	/* The fyl2xp1 can only be used for values in
		-1 + sqrt(2) / 2 <= x <= 1 - sqrt(2) / 2
	   0.29 is a safe value.
	*/

/*
 * Use the fyl2xp1 function when the argument is in the range -0.29 to 0.29,
 * otherwise fyl2x with the needed extra computation.
 */

#define __LOG1P(retval,x)\
   asm("fldln2\n"\
      "	fxch\n"\
      "	fld1\n"\
      "	faddp %%st(1)\n"\
      "	fyl2x":\
      "=t"(retval):\
      "0"(x))

float (log1pf)(float x)
{
  register float retval;
  __LOG1P(retval,x);
  return retval;
}

double (log1p)(double x)
{
  register double retval;
  __LOG1P(retval,x);
  return retval;
}

long double (log1pl)(long double x)
{
  register long double retval;
  __LOG1P(retval,x);
  return retval;
}

#define __LOG2(retval,x)\
   asm("fld1\n"\
      "	fxch\n"\
      "	fyl2x":\
      "=t"(retval):\
      "0"(x))

float (log2f)(float x)
{
  register float retval;
  __LOG2(retval,x);
  return retval;
}

double (log2)(double x)
{
  register double retval;
  __LOG2(retval,x);
  return retval;
}

long double (log2l)(long double x)
{
  register long double retval;
  __LOG2(retval,x);
  return retval;
}

#define __ILOGBF(ret,x)\
   asm("fxtract\n"\
      "	fstp	%0":\
      "=t"(ret)    :\
      "0"(x)       :\
      "st(1)")

float (logbf)(float x)
{
  register float ret;
  __ILOGBF(ret,x);
  return ret;
}

double (logb)(double x)
{
  register double ret;
  __ILOGBF(ret,x);
  return ret;
}

long double (logbl)(long double x)
{
  register long double ret;
  __ILOGBF(ret,x);
  return ret;
}

#define __LRINT(ret,x)\
   asm("fistpl	%0\n"\
      "	fwait" :\
      "=m"(ret):\
      "t"(x)   :\
      "st")

long int (lrintf)(float x)
{
  long int ret;
  __LRINT(ret,x);
  return ret;
}

long int (lrint)(double x)
{
  long int ret;
  __LRINT(ret,x);
  return ret;
}

long int (lrintl)(long double x)
{
  long int ret;
  __LRINT(ret,x);
  return ret;
}

#define __RINT(ret,x)\
   asm("frndint":\
      "=t"(ret) :\
      "0"(x))

float (rintf)(float x)
{
  register float ret;
  __RINT(ret,x);
  return ret;
}

double (rint)(double x)
{
  register double ret;
  __RINT(ret,x);
  return ret;
}

long double (rintl)(long double x)
{
  register long double ret;
  __RINT(ret,x);
  return ret;
}

#define __SCALBN(ret,x,n)\
   asm("fscale"   :\
      "=t"(ret)   :\
      "0"(x),\
      "u"(n):\
      "st(1)")

float (scalbnf)(float x,int n)
{
  register float ret;
  __SCALBN(ret,x,(float)n);
  return ret;
}

double (scalbn)(double x,int n)
{
  register double ret;
  __SCALBN(ret,x,(double)n);
  return ret;
}

long double (scalbnl)(long double x,int n)
{
  register long double ret;
  __SCALBN(ret,x,(long double)n);
  return ret;
}

float (ldexpf)(float x,int n)
{
  register float ret;
  __SCALBN(ret,x,(float)n);
  return ret;
}

double (ldexp)(double x,int n)
{
  register double ret;
  __SCALBN(ret,x,(double)n);
  return ret;
}

long double (ldexpl)(long double x,int n)
{
  register long double ret;
  __SCALBN(ret,x,(long double)n);
  return ret;
}

#define __SIGNIFICAND(ret,x)\
   asm("fxtract\n"\
      "	fstp	%%st(1)":\
      "=t"(ret)    :\
      "0"(x))

float (significandf)(float x)
{
  float ret;
  __SIGNIFICAND(ret,x);
  return ret;
}

double (significand)(double x)
{
  double ret;
  __SIGNIFICAND(ret,x);
  return ret;
}

long double (significandl)(long double x)
{
  long double ret;
  __SIGNIFICAND(ret,x);
  return ret;
}

#define __SINCOS(x,cosptr,sinptr)\
{\
  register long double sv,cv;\
  asm("fsincos":"=t"(cv),"=u"(sv):"0"(x):"st(2)","st(3)");\
  *cosptr = cv;\
  *sinptr = sv;\
}

void (sincosf)(float x,float *sinptr,float *cosptr)
{
  __SINCOS(x,cosptr,sinptr);
}

void (sincos)(double x,double *sinptr,double *cosptr)
{
  __SINCOS(x,cosptr,sinptr);
}

void (sincosl)(long double x,long double *sinptr,long double *cosptr)
{
  __SINCOS(x,cosptr,sinptr);
}

#define __TRUNC(ret,x,orig_cw,mod_cw)\
   asm("fstcw	%0":"=m"(orig_cw)::"memory");\
   mod_cw = orig_cw | 0xc00;\
   asm("fldcw	%3\n"\
      "	frndint\n"\
      "	fldcw	%2":\
      "=t"(ret)    :\
      "0"(x),\
      "m"(orig_cw),\
      "m"(mod_cw))

float (truncf)(float x)
{
  register float ret;
  int i1,i2;
  __TRUNC(ret,x,i1,i2);
  return ret;
}

double (trunc)(double x)
{
  register double ret;
  int i1,i2;
  __TRUNC(ret,x,i1,i2);
  return ret;
}

long double (truncl)(long double x)
{
  register long double ret;
  int i1,i2;
  __TRUNC(ret,x,i1,i2);
  return ret;
}

#define IEEE754_FABS(ret,x)\
   asm("fabs" :\
       "=t"(ret):\
       "0"(x))

float (fabsf)(float x)
{
  register float ret;
  IEEE754_FABS(ret,x);
  return ret;
}

double (fabs)(double x)
{
  register double ret;
  IEEE754_FABS(ret,x);
  return ret;
}

long double (fabsl)(long double x)
{
  register long double ret;
  IEEE754_FABS(ret,x);
  return ret;
}

static void (frac)( void )
{
  short cw1,cw2;
   asm("fnstcw	%0\n"
      "	fwait"
      :"=m"(cw1));
  cw2 = (cw1 & 0xf3ff) | 0x0400;
   asm("fldcw	%1\n"
      "	fld	%%st\n"
      "	frndint\n"
      "	fldcw	%0\n"
      "	fxch	%%st(1)\n"
      "	fsub	%%st(1), %%st"
      ::"m"(cw1),"m"(cw2):"memory");
}
#ifdef __USE_UNDERSCORE
#define FRAC "call	_frac\n"
#else
#define FRAC "call	frac\n"
#endif

static void (Lpow2)( void )
{
   asm(FRAC
      "	f2xm1\n"
      "	fld1\n"
      "	faddp	%%st(1)\n"
      "	fscale\n"
      "	fstp	%%st(1)\n"
      ::: "memory");
}
#ifdef __USE_UNDERSCORE
#define LPOW2 "call	_Lpow2\n"
#else
#define LPOW2 "call	Lpow2\n"
#endif

#define __POW10(retval, y)\
{\
   asm("fldl2t\n"\
      "	fmulp\n"\
      FRAC\
      "	f2xm1\n"\
      "	fld1\n"\
      "	faddp	%1, %%st(1)\n"\
      "	fscale\n"\
      "	fstp	%%st(1)\n"\
      :"=t"(retval)\
      :"0"(y));\
}

#define __POW(retval,x,y)\
{\
  int yint;\
   asm("ftst\n"\
      "	fnstsw	%%ax\n"\
      "	sahf\n"\
      "	jbe	1f\n"\
      "	fyl2x\n"\
      LPOW2\
      "	jmp	6f\n"\
"1:	jb	4f\n"\
      "	fstp	%0\n"\
      "	ftst\n"\
      "	fnstsw	%%ax\n"\
      "	sahf\n"\
      "	ja	3f\n"\
      "	jb	2f\n"\
      "	fstp	%0\n"\
      "	fld1\n"\
      "	fchs\n"\
"2:	fsqrt\n"\
      "	jmp     6f\n"\
"3:	fstp	%0\n"\
      "	fldz\n"\
      "	jmp	6f\n"\
"4:	fabs\n"\
      "	fxch	%2\n"\
      FRAC\
      "	ftst\n"\
      "	fnstsw	%%ax\n"\
      "	fstp	%0\n"\
      "	sahf\n"\
      "	je	5f\n"\
      "	fstp	%0\n"\
      "	fchs\n"\
      "	jmp	2b\n"\
"5:	fistl	%3\n"\
      "	fxch	%2\n"\
      "	fyl2x\n"\
      LPOW2\
      "	andl	$1, %3\n"\
      "	jz	6f\n"\
      "	fchs\n"\
"6:"\
      :"=t"(retval)\
      :"0"(x),"u"(y),"m"(yint)\
      :"eax","memory","st(1)");\
}

float (powf)(float x, float y)
{
  register float retval;
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw) || x == 1) return x;
  else
  if(x == (float)10.) __POW10(retval, y)
  else                __POW(retval,x,y)
  return retval;
}

double (pow)(double x, double y)
{
  register double retval;
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw) || x == 1) return x;
  else
  if(x == (double)10.) __POW10(retval, y)
  else                 __POW(retval,x,y)
  return retval;
}

long double (powl)(long double x, long double y)
{
  register long double retval;
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw) || x == 1) return x;
  else
  if(x == (long double)10.) __POW10(retval, y)
  else                      __POW(retval,x,y)
  return retval;
}

float (pow10f)(float y)
{
  register float retval;
  register int sw;
  FXAM_SW(sw, y);
  if(__SW_ISINF(sw)) return y;
  else
  __POW10(retval, y)
  return retval;
}

double (pow10)(double y)
{
  register double retval;
  register int sw;
  FXAM_SW(sw, y);
  if(__SW_ISINF(sw)) return y;
  else
  __POW10(retval, y)
  return retval;
}

long double (pow10l)(long double y)
{
  register long double retval;
  register int sw;
  FXAM_SW(sw, y);
  if(__SW_ISINF(sw)) return y;
  else
  __POW10(retval, y)
  return retval;
}

/*
 cbrt.c (emx+gcc) -- Copyright (c) 1992-1995 by Eberhard Mattes
*/

float (cbrtf)(float x)
{
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw)) return x;
  else
  if (x >= 0)
    return powf (x, 1.0 / 3.0);
  else
    return -powf (-x, 1.0 / 3.0);
}

double (cbrt)(double x)
{
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw)) return x;
  else
  if (x >= 0)
    return pow (x, 1.0 / 3.0);
  else
    return -pow (-x, 1.0 / 3.0);
}

long double (cbrtl)(long double x)
{
  register int sw;
  FXAM_SW(sw, x);
  if(__SW_ISINF(sw)) return x;
  else
  if (x >= 0)
    return powl (x, 1.0 / 3.0);
  else
    return -powl (-x, 1.0 / 3.0);
}

float (acoshf)(float x)
{
/* return log(x + sqrt(x*x - 1)); */
  float retval;
  IEEE754_SQRT(retval, x*x-1);
  IEEE754_LOG(retval,x + retval);
  return retval;
}

double (acosh)(double x)
{
/* return log(x + sqrt(x*x - 1)); */
  double retval;
  IEEE754_SQRT(retval, x*x-1);
  IEEE754_LOG(retval,x + retval);
  return retval;
}

long double (acoshl)(long double x)
{
/* return log(x + sqrt(x*x - 1)); */
  long double retval;
  IEEE754_SQRT(retval, x*x-1);
  IEEE754_LOG(retval,x + retval);
  return retval;
}

float (asinhf)(float x)
{
/* return x>0 ? log(x + sqrt(x*x + 1)) : -log(sqrt(x*x+1)-x); */
  float retval;
  IEEE754_SQRT(retval, x*x+1);
  if(x>0) IEEE754_LOG(retval,x + retval);
  else
  {
    IEEE754_LOG(retval,retval-x);
    retval = -retval;
  }
  return retval;
}

double (asinh)(double x)
{
/* return x>0 ? log(x + sqrt(x*x + 1)) : -log(sqrt(x*x+1)-x); */
  double retval;
  IEEE754_SQRT(retval, x*x+1);
  if(x>0) IEEE754_LOG(retval,x + retval);
  else
  {
    IEEE754_LOG(retval,retval-x);
    retval = -retval;
  }
  return retval;
}

long double (asinhl)(long double x)
{
/* return x>0 ? log(x + sqrt(x*x + 1)) : -log(sqrt(x*x+1)-x); */
  long double retval;
  IEEE754_SQRT(retval, x*x+1);
  if(x>0) IEEE754_LOG(retval,x + retval);
  else
  {
    IEEE754_LOG(retval,retval-x);
    retval = -retval;
  }
  return retval;
}

float (atanhf)(float x)
{
/*  return log((1+x)/(1-x)) / 2.0;*/
  float retval;
  IEEE754_LOG(retval,(1+x)/(1-x));
  return retval/2.;
}

double (atanh)(double x)
{
/*  return log((1+x)/(1-x)) / 2.0;*/
  double retval;
  IEEE754_LOG(retval,(1+x)/(1-x));
  return retval/2.;
}

long double (atanhl)(long double x)
{
/*  return log((1+x)/(1-x)) / 2.0;*/
  long double retval;
  IEEE754_LOG(retval,(1+x)/(1-x));
  return retval/2.;
}

float (coshf)(float x)
{
  float retval;
  IEEE754_FABS(retval, x);
  IEEE754_EXP(retval, retval);
  return (retval + 1.0/retval) / 2.0;
}

double (cosh)(double x)
{
  double retval;
  IEEE754_FABS(retval, x);
  IEEE754_EXP(retval, retval);
  return (retval + 1.0/retval) / 2.0;
}

long double (coshl)(long double x)
{
  long double retval;
  IEEE754_FABS(retval, x);
  IEEE754_EXP(retval, retval);
  return (retval + 1.0/retval) / 2.0;
}

float (sinhf)(float x)
{
 if(x >= 0.0)
 {
   float epos;
   IEEE754_EXP(epos, x);
   return (epos - 1.0/epos) / 2.0;
 }
 else
 {
   float eneg;
   IEEE754_EXP(eneg, -x);
   return (1.0/eneg - eneg) / 2.0;
 }
}

double (sinh)(double x)
{
 if(x >= 0.0)
 {
   double epos;
   IEEE754_EXP(epos, x);
   return (epos - 1.0/epos) / 2.0;
 }
 else
 {
   double eneg;
   IEEE754_EXP(eneg, -x);
   return (1.0/eneg - eneg) / 2.0;
 }
}

long double (sinhl)(long double x)
{
 if(x >= 0.0)
 {
   long double epos;
   IEEE754_EXP(epos, x);
   return (epos - 1.0/epos) / 2.0;
 }
 else
 {
   long double eneg;
   IEEE754_EXP(eneg, -x);
   return (1.0/eneg - eneg) / 2.0;
 }
}

float (tanhf)(float x)
{
  if (x > 50)
    return 1;
  else if (x < -50)
    return -1;
  else
  {
    float ebig;
    float esmall;
    IEEE754_EXP(ebig, x);
    esmall = 1./ebig;
    return (ebig - esmall) / (ebig + esmall);
  }
}

double (tanh)(double x)
{
  if (x > 50)
    return 1;
  else if (x < -50)
    return -1;
  else
  {
    double ebig;
    double esmall;
    IEEE754_EXP(ebig, x);
    esmall = 1./ebig;
    return (ebig - esmall) / (ebig + esmall);
  }
}

long double (tanhl)(long double x)
{
  if (x > 50)
    return 1;
  else if (x < -50)
    return -1;
  else
  {
    long double ebig;
    long double esmall;
    IEEE754_EXP(ebig, x);
    esmall = 1./ebig;
    return (ebig - esmall) / (ebig + esmall);
  }
}

#define __NEARBYINT(retval,x,new_cw,org_cw)\
   asm("fnstcw	%0\n":\
      "=m"(org_cw));\
   new_cw = org_cw & (~0x20);\
   asm(\
      "	fldcw	%2\n"\
      "	frndint\n"\
      "	fnclex\n"\
      "	fldcw	%3":\
      "=t"(retval):\
      "0"(x),\
      "m"(new_sw),\
      "m"(org_cw))

float (nearbyintf)(float x)
{
  register float retval;
  int new_sw,org_sw;
  __NEARBYINT(retval,x,new_sw,org_sw);
  return retval;
}

double (nearbyint)(double x)
{
  register double retval;
  int new_sw,org_sw;
  __NEARBYINT(retval,x,new_sw,org_sw);
  return retval;
}

long double (nearbyintl)(long double x)
{
  register long double retval;
  int new_sw,org_sw;
  __NEARBYINT(retval,x,new_sw,org_sw);
  return retval;
}

#define __IEEE754_EXPM1(retval, x)\
   asm("fxam\n"\
      "	fstsw	%%ax\n"\
      "	movb	$0x45, %%ch\n"\
      "	andb	%%ah, %%ch\n"\
      "	cmpb	$0x40, %%ch\n"\
      "	je	3f\n"\
      "	cmpb	$0x05, %%ch\n"\
      "	je	2f\n"\
      "	fldl2e\n"\
      "	fmulp\n"\
      "	fld	%1\n"\
      "	frndint\n"\
      "	fsubr	%1,  %%st(1)\n"\
      "	fxch\n"\
      "	f2xm1\n"\
      "	fscale\n"\
      "	fxch\n"\
      "	fld1\n"\
      "	fscale\n"\
      "	fld1\n"\
      "	fsubp	%1, %%st(1)\n"\
      "	fstp	%%st(1)\n"\
      "	fsubrp	%1, %%st(1)\n"\
      "	jmp	3f\n"\
"2:	testb	$0x02, %%ah\n"\
      "	jz	3f\n"\
      FFREEP"	%1\n"\
      "	fld1\n"\
      "	fchs\n"\
"3:":\
      "=t"(retval):\
      "0"(x):\
      "eax","ecx","st(1)")

float (expm1f)(float x)
{
  register float retval;
  __IEEE754_EXPM1(retval,x);
  return retval;
}

double (expm1)(double x)
{
  register double retval;
  __IEEE754_EXPM1(retval,x);
  return retval;
}

long double (expm1l)(long double x)
{
  register long double retval;
  __IEEE754_EXPM1(retval,x);
  return retval;
}

#define NAN (0./0.)

#define __IEEE754_SCALB(retval, x, fn)\
{\
  register int nx, nfn;\
  ISNAN(nx, x);\
  ISNAN(nfn, fn);\
  if (nx||nfn) return x*fn;\
  ISFINITE(nx, x);\
  ISFINITE(nfn, fn);\
  if (!nfn) {\
    if(fn>0.0) return x*fn;\
    else if (x == 0)\
      return x;\
    else if (!nx)\
      return NAN;\
    else  return x/(-fn);\
  }\
  if (rint(fn)!=fn) return NAN;\
  if ( fn > 65000.0) return scalbn(x, 65000);\
  if (-fn > 65000.0) return scalbn(x,-65000);\
  return scalbn(x,(int)fn);\
}

float (scalbf)(float x, float n)
{
  register float retval;
  __IEEE754_SCALB(retval, x, n);
  return retval;
}

double (scalb)(double x, double n)
{
  register double retval;
  __IEEE754_SCALB(retval, x, n);
  return retval;
}

long double (scalbl)(long double x, long double n)
{
  register long double retval;
  __IEEE754_SCALB(retval, x, n);
  return retval;
}
