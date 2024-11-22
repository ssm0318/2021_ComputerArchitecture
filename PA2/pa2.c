//---------------------------------------------------------------
//
//  4190.308 Computer Architecture (Fall 2021)
//
//  Project #2: FP10 (10-bit floating point) Representation
//
//  October 5, 2021
//
//  Jaehoon Shim (mattjs@snu.ac.kr)
//  Ikjoon Son (ikjoon.son@snu.ac.kr)
//  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
//  Systems Software & Architecture Laboratory
//  Dept. of Computer Science and Engineering
//  Seoul National University
//
//---------------------------------------------------------------

#include "pa2.h"

#define FP10_INF_NAN_EXP 0x001F
#define FP10_EXP_MASK 0x01F0
#define FP10_FRAC_MASK 0x000F

#define FP10_EXP_SHFT 4

#define FP32_INF_NAN_EXP 0x000000FF
#define FP32_SIGN_MASK 0x80000000
#define FP32_EXP_MASK 0x7F800000
#define FP32_FRAC_MASK 0x007FFFFF
#define FP32_NORM 0x00800000

#define FP32_EXP_SHFT 23

/* Convert 32-bit signed integer to 10-bit floating point */
fp10 int_fp10(int n)
{
    return float_fp10((float) n);
}

/* Convert 10-bit floating point to 32-bit signed integer */
int fp10_int(fp10 x)
{
    return (int) fp10_float(x);
}

/* Convert 32-bit single-precision floating point to 10-bit floating point */
fp10 float_fp10(float f)
{
    unsigned int exp = (*((unsigned int *) &f) & FP32_EXP_MASK) >> FP32_EXP_SHFT;
    unsigned int frac = *((unsigned int *) &f) & FP32_FRAC_MASK;
    fp10 fp10_sign = *((unsigned int *) &f) & FP32_SIGN_MASK ? 0xFE00 : 0x0000;

    /* special cases */
    if (exp == FP32_INF_NAN_EXP) {      // Inf, NaN
        return fp10_sign | FP10_EXP_MASK | (frac > 0);
    } else if ((exp >= 143) || ((exp == 142) && (frac >= 0x007C0000))) {  // Exceed max. fp10 range
        return fp10_sign | FP10_EXP_MASK;
    } else if (exp >= 113) {    // Norm fp10 range (exp == -14)
        /* r && (l || s) */
        unsigned int round = ((frac >> 18) & 0x00000001) && (((frac >> 19) & 0x00000001) || ((frac << 14) > 0));
        unsigned int renormalize = round && (frac > 0x00780000);
        unsigned int fp10_exp = ((exp - 112) + renormalize) << FP10_EXP_SHFT;
        unsigned int fp10_frac = round ? (frac + 0x00080000) >> (19 + (renormalize << 3)) : (frac >> 19);
        return fp10_sign | fp10_exp | fp10_frac;
    } else if ((exp < 107) || ((exp == 108) && (frac == 0))) { // Below min. fp10 range, +0.0, -0.0
        return fp10_sign;
    } else if ((exp == 112) && (frac > 0x00780000)) {   // 1.1111xx...x * 2^(-15) -> 1.0000 * 2^(-14)
        return fp10_sign | 0x0010;
    } else {  // denorm fp10 range
        frac |= FP32_NORM;      // add hidden 1 to frac bits (norm -> denorm)
        frac >>= (-14 - (exp - 127));   // align exponent to 2^(-14)

        /* r && (l || s) */
        unsigned int round = ((frac >> 18) & 0x00000001) && (((frac >> 19) & 0x00000001) || ((frac << 14) > 0));
        return fp10_sign | (round ? ((frac + 0x00080000) >> 19) : (frac >> 19));  // round up if necessary
    }
}

/* Convert 10-bit floating point to 32-bit single-precision floating point */
float fp10_float(fp10 x)
{
    unsigned int exp = (x & FP10_EXP_MASK) >> FP10_EXP_SHFT;
    unsigned int frac = x & FP10_FRAC_MASK;
    unsigned int fp32_sign = (x & 0x8000) << 16;

    /* special case */
    unsigned int ans;
    if (exp == FP10_INF_NAN_EXP) {      // Inf, NaN
        ans = fp32_sign | FP32_EXP_MASK | frac;
    } else if (exp > 0) {               // Normalized fp10 range
        ans = fp32_sign | ((exp + 112) << 23) | (frac << 19);
    } else if (exp == 0 && frac == 0) { // +0.0, -0.0
        ans = fp32_sign;
    } else {                            // Denormalized fp10 range
        if (frac & 0x00000008) {        // F = 0.1XXX
            ans = fp32_sign | ((exp + 112) << 23) | ((frac & 0x00000007) << 20);
        } else if (frac & 0x00000004) { // F = 0.01XX
            ans = fp32_sign | ((exp + 111) << 23) | ((frac & 0x00000003) << 21);
        } else if (frac & 0x00000002) { // F = 0.001X
            ans = fp32_sign | ((exp + 110) << 23) | ((frac & 0x00000001) << 22);
        } else {                        // F = 0.0001
            ans = fp32_sign | ((exp + 109) << 23);
        }
    }

    return *((float *) (&ans));
}
