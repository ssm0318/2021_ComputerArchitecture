//---------------------------------------------------------------
//
//  4190.308 Computer Architecture (Fall 2021)
//
//  Project #1: Run-Length Encoding
//
//  September 14, 2021
//
//  Jaehoon Shim (mattjs@snu.ac.kr)
//  Ikjoon Son (ikjoon.son@snu.ac.kr)
//  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
//  Systems Software & Architecture Laboratory
//  Dept. of Computer Science and Engineering
//  Seoul National University
//
//---------------------------------------------------------------

#define RUN_LEN 3

unsigned long long pos;

void append(char* const dst, unsigned char pattern, unsigned char len, const int dstlen) {
    if (len == 0) return;

    int bytepos = (int) (pos / 8);
    unsigned char bitpos = pos % 8;

    if ((bytepos > dstlen) || (bytepos == dstlen && bitpos > 0)) {
        return;
    }

    char shift = (char) (8 - len - bitpos);

    if (shift >= 0) {
        *(dst + bytepos) |= pattern << (shift);
    } else {
        *(dst + bytepos) |= pattern >> (-shift);
        *(dst + bytepos + 1) |= pattern << (8 + shift);
    }

    pos += len;
}


int encode(const char* const src, const int srclen, char* const dst, const int dstlen)
{
    // special case
    pos = 0;
    if (srclen == 0) {
        return 0;
    } else if (srclen / 7 * RUN_LEN > dstlen) { // size of the output will exceed the dstlen
        return -1;
    }

    // initialize output
    for (int i = 0; i < dstlen; i++) {
        *(dst + i) = (char) 0;
    }

    // if the src does not begin with `0`
    unsigned char curr_bit = (*(src) & 0x80) >> 7;  // first bit
    if (curr_bit == 1) {
        append(dst, 0, RUN_LEN, dstlen);
    }

    // encode
    unsigned char num_bits = 0, new_bit;
    for (int i = 0; i < srclen; i++) {
        unsigned char ch = *(src + i);  // curr byte

        for (int j = 7; j >= 0; j--) {
            new_bit = (ch & (1 << j)) >> j;

            if (curr_bit == new_bit) {
                if (++num_bits >= 8) {
                    append(dst, 7, RUN_LEN, dstlen);
                    num_bits -= 7;
                    append(dst, 0, RUN_LEN, dstlen);
                }
            } else {
                append(dst, num_bits, RUN_LEN, dstlen);
                num_bits = 1;
                curr_bit = new_bit;
            }
        }
    }

    append(dst, num_bits, RUN_LEN, dstlen);

    int outlen = (pos + 7) / 8;
    if (outlen > dstlen) { // output exceeded dstlen
        return -1;
    } else {
        return outlen;
    }
}


int decode(const char* const src, const int srclen, char* const dst, const int dstlen)
{
    pos = 0;
    // special case
    if (srclen == 0) {
        return 0;
    } else if ((srclen + 2) / 3 * 7 > dstlen) { // output will exceed dstlen
        return -1;
    }

    // initialize output
    for (int i = 0; i < dstlen; i++) {
        *(dst + i) = (char) 0;
    }

    // decode
    unsigned char num_carry_bits = 0, num_bits, carry = 0;
    unsigned char shift = 0xE0;
    unsigned char ones = 0x7F;
    for (int i = 0; i < srclen; i++) {
        unsigned char ch = *(src + i);  // curr byte

        if (num_carry_bits == 0) {
            num_bits = (ch & shift) >> 5;           // 1, 2, 3
            pos += num_bits;

            num_bits = (ch & (shift >> 3)) >> 2;    // 4, 5, 6
            append(dst, ones >> (7 - num_bits), num_bits, dstlen);

            carry = (ch & 0x03) << 1;              // 7, 8
            num_carry_bits = 2;
        } else if (num_carry_bits == 1) {
            num_bits = (ch & (shift << 1)) >> 6;   // 1, 2
            num_bits += carry;
            append(dst, ones >> (7 - num_bits), num_bits, dstlen);

            num_bits = (ch & (shift >> 2)) >> 3;   // 3, 4, 5
            pos += num_bits;

            num_bits = (ch & 0x07);                // 6, 7, 8
            append(dst, ones >> (7 - num_bits), num_bits, dstlen);

            num_carry_bits = 0;
        } else { // num_carry_bits == 2
            num_bits = (ch & (shift << 2)) >> 7;   // 1
            num_bits += carry;
            pos += num_bits;

            num_bits = (ch & (shift >> 1)) >> 4;   // 2, 3, 4
            append(dst, ones >> (7 - num_bits), num_bits, dstlen);

            num_bits = (ch & (shift >> 4)) >> 1;   // 5, 6, 7
            pos += num_bits;

            carry = (ch & 0x01) << 2;              // 8
            num_carry_bits = 1;
        }
    }

    int outlen = (pos + 7) / 8;
    if (outlen > dstlen) { // output exceeded dstlen
        return -1;
    } else {
        return outlen;
    }
}
