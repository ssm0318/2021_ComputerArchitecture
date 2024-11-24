#----------------------------------------------------------------
#
#  4190.308 Computer Architecture (Fall 2021)
#
#  Project #3: Image Convolution in RISC-V Assembly
#
#  October 25, 2021
#
#  Jaehoon Shim (mattjs@snu.ac.kr)
#  Ikjoon Son (ikjoon.son@snu.ac.kr)
#  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
#  Systems Software & Architecture Laboratory
#  Dept. of Computer Science and Engineering
#  Seoul National University
#
#----------------------------------------------------------------

####################
# void bmpconv(unsigned char *imgptr, int h, int w, unsigned char *k, unsigned char *outptr)
# a0: imgptr, a1: h, a2: w, a3: k, a4: outptr
####################

	.globl bmpconv
bmpconv:
    add t4, a2, a2                      # t4 = 2 * w
    add t4, t4, a2                      # t4 = 3 * w; width of one row
    add a2, t4, x0                      # a2 = width of one row
    slli t1, t4, 30                     # t1 = t4 << 6; t1 = last two bits of t4
    beq t1, x0, initialize              # if ncol is multiple of 4, continue
    srli t1, t4, 2                      # t1 = t4 >> 2; remove last two bits from t4
    addi t1, t1, 1
    slli a2, t1, 2                      # a2 = number of bytes in a row as multiple of 4

initialize:
    add t0, x0, x0                      # t0 = 0 (current row)
    add t1, x0, x0                      # t1 = 0 (current col)

save_val:
    addi sp, sp, -132                   # add 132 bytes to stack space
    sw t4, 28(sp)                       # 28(sp) = number of RGB bytes in a row
    sw a0, 24(sp)                       # 24(sp) = imgptr
    sw a1, 20(sp)                       # 20(sp) = height
    sw a2, 16(sp)                       # 16(sp) = number of bytes in a row as multiple of 4
    sw a3, 12(sp)                       # 12(sp) = k
    sw a4, 8(sp)                        # 8(sp) = outptr
    sw t0, 4(sp)                        # 4(sp) = current row
    sw t1, 0(sp)                        # 0(sp) = current col

get_kernel:
    lw t1, 0(a3)                # t1 = first 4 bytes of k
    srai t2, t1, 24             # t2 = 4th byte of k, sign extended
    sw t2, 108(sp)              # 108(sp) = 4th byte of k, sign extended
    slli t2, t1, 8              # t2 = first 3 bytes of k
    srai t2, t2, 24             # t2 = 3rd byte of k, sign extended
    sw t2, 104(sp)              # 104(sp) = 3rd byte of k, sign extended
    slli t2, t1, 16             # t2 = first 2 bytes of k
    srai t2, t2, 24             # t2 = 2nd byte of k, sign extended
    sw t2, 100(sp)              # 100(sp) = 2nd byte of k, sign extended
    slli t2, t1, 24             # t2 = first 1 byte of k
    srai t2, t2, 24             # t2 = 1st byte of k, sign extended
    sw t2, 96(sp)               # 96(sp) = 1st byte of k, sign extended

    lw t1, 4(a3)                # t1 = next 4 bytes of k
    srai t2, t1, 24             # t2 = 8th byte of k, sign extended
    sw t2, 124(sp)              # 124(sp) = 8th byte of k, sign extended
    slli t2, t1, 8              # t2 = next 3 bytes of k
    srai t2, t2, 24             # t2 = 7th byte of k, sign extended
    sw t2, 120(sp)              # 120(sp) = 7th byte of k, sign extended
    slli t2, t1, 16             # t2 = next 2 bytes of k
    srai t2, t2, 24             # t2 = 6th byte of k, sign extended
    sw t2, 116(sp)              # 116(sp) = 6th byte of k, sign extended
    slli t2, t1, 24             # t2 = next 1 byte of k
    srai t2, t2, 24             # t2 = 5th byte of k, sign extended
    sw t2, 112(sp)              # 112(sp) = 5th byte of k, sign extended

    lw t1, 8(a3)                # t1 = last 4 bytes of k
    slli t2, t1, 24             # t2 = last byte of k
    srai t2, t2, 24             # t2 = 9th byte of k, sign extended
    sw t2, 128(sp)              # 128(sp) = 9th byte of k, sign extended

boundary_check:
    lw t4, 28(sp)                       # t4 = number of RGB bytes in a row
    lw a0, 24(sp)                       # a0 = imgptr
    lw a1, 20(sp)                       # a1 = height
    lw a2, 16(sp)                       # a2 = number of bytes in a row as multiple of 4
    lw a3, 12(sp)                       # a3 = k
    lw a4, 8(sp)                        # a4 = outptr
    lw t0, 4(sp)                        # t0 = current row
    lw t1, 0(sp)                        # t1 = current col
    addi t2, t1, 6                      # t2 = current_col + 6
    blt t2, t4, load_img_word           # if current_col exceeds max RGB bytes, move to next row

next_row:
    sub a4, a2, t1                      # a4 = number of leftover bytes
    add t1, x0, x0                      # t1 = 0 (current col)
    sw t1, 0(sp)
    addi t0, t0, 1                      # t0 = t0 + 1 (current row)
    sw t0, 4(sp)
    addi t2, t0, 2                      # t2 = current_row + 2
    lw a0, 24(sp)
    add a0, a0, a4                      # move imgptr to next row
    sw a0, 24(sp)
    bge t2, a1, finish

load_img_word:
    sw x0, 44(sp)                       # 44(sp) = output 1 (initialized to zero)
    sw x0, 40(sp)                       # 40(sp) = output 2 (initialized to zero)
    sw x0, 36(sp)                       # 36(sp) = output 3 (initialized to zero)
    sw x0, 32(sp)                       # 32(sp) = output 4 (initialized to zero)
    sw x0, 60(sp)                       # 60(sp) = output val combined

load_img_words:
    add a4, a0, a2                      # a4 = start of second row
    lw t2, 0(a4)                        # t2 = second row word 1
    sw t2, 52(sp)                       # 52(sp) = second row word 1
    lw t2, 4(a4)                        # t2 = second row word 2
    sw t2, 76(sp)                       # 76(sp) = second row word 2
    add a4, a4, a2                      # a4 = start of third row
    lw t2, 0(a4)                        # t2 = third row word 1
    sw t2, 56(sp)                       # 56(sp) = third row word 1
    lw t2, 4(a4)                        # t2 = third row word 2
    sw t2, 80(sp)                       # 80(sp) = third row word 2
    lw t2, 4(a0)                        # t2 = first row word 2
    sw t2, 72(sp)                       # 72(sp) = first row word 2
    lw t2, 0(a0)                        # t2 = first row word 1
    sw t2, 48(sp)                       # 48(sp) = first row word 1
    addi a4, t1, 8
    bge a4, a2, load_zeroes             # if cannot load third word, skip
    add a4, a0, a2
    lw t2, 8(a4)                        # t2 = second row word 3
    sw t2, 88(sp)                       # 88(sp) = second row word 3
    add a4, a4, a2
    lw t2, 8(a4)                        # t2 = third row word 3
    sw t2, 92(sp)                       # 92(sp) = third row word 3
    lw t2, 8(a0)                        # t2 = first row word 3
    sw t2, 84(sp)                       # 84(sp) = first row word 3
    beq x0, x0, row_1_byte_1_col_1

load_zeroes:
    sw x0, 88(sp)                       # 88(sp) = second row word 3
    sw x0, 92(sp)                       # 92(sp) = third row word 3
    sw x0, 84(sp)                       # 84(sp) = first row word 3

row_1_byte_1_col_1:
    lw a1, 96(sp)
    beq a1, x0, row_1_byte_1_col_2      # if kernel val is zero, skip
    lw t2, 48(sp)                       # t2 = row 1 word 1
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_1_byte_1_col_2      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a3
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_1_byte_1_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_1_byte_1_col_2:
    lw a1, 100(sp)
    beq a1, x0, row_1_byte_1_col_3      # if kernel val is zero, skip
    lw t2, 48(sp)                       # t2 = row 1 word 1
    srli a4, t2, 24                     # a4 = fourth byte of word
    beq a4, x0, row_1_byte_1_col_3      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_1_byte_1_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_1_byte_1_col_3:
    lw a1, 104(sp)
    beq a1, x0, row_2_byte_1_col_1      # if kernel val is zero, skip
    lw t2, 72(sp)                       # t2 = row 1 word 2
    srli a4, t2, 16                     # a1 = third byte of word
    andi a4, a4, 255                    # a1 = mask third byte of word
    beq a4, x0, row_2_byte_1_col_1      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_2_byte_1_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_2_byte_1_col_1:
    lw a1, 108(sp)
    beq a1, x0, row_2_byte_1_col_2      # if kernel val is zero, skip
    lw t2, 52(sp)                       # t2 = row 2 word 1
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_2_byte_1_col_2      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a3
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_2_byte_1_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_2_byte_1_col_2:
    lw a1, 112(sp)
    beq a1, x0, row_2_byte_1_col_3      # if kernel val is zero, skip
    lw t2, 52(sp)                       # t2 = row 2 word 1
    srli a4, t2, 24                     # a4 = fourth byte of word
    beq a4, x0, row_2_byte_1_col_3      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_2_byte_1_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_2_byte_1_col_3:
    lw a1, 116(sp)
    beq a1, x0, row_3_byte_1_col_1      # if kernel val is zero, skip
    lw t2, 76(sp)                       # t2 = row 2 word 2
    srli a4, t2, 16                     # a1 = third byte of word
    andi a4, a4, 255                    # a1 = mask third byte of word
    beq a4, x0, row_3_byte_1_col_1      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_3_byte_1_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_3_byte_1_col_1:
    lw a1, 120(sp)
    beq a1, x0, row_3_byte_1_col_2      # if kernel val is zero, skip
    lw t2, 56(sp)                       # t2 = row 3 word 1
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_3_byte_1_col_2      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a3
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_3_byte_1_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_3_byte_1_col_2:
    lw a1, 124(sp)
    beq a1, x0, row_3_byte_1_col_3      # if kernel val is zero, skip
    lw t2, 56(sp)                       # t2 = row 3 word 1
    srli a4, t2, 24                     # a4 = fourth byte of word
    beq a4, x0, row_3_byte_1_col_3      # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, row_3_byte_1_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

row_3_byte_1_col_3:
    lw a1, 128(sp)
    beq a1, x0, byte_2                  # if kernel val is zero, skip
    lw t2, 80(sp)                       # t2 = row 3 word 2
    srli a4, t2, 16                     # a1 = third byte of word
    andi a4, a4, 255                    # a1 = mask third byte of word
    beq a4, x0, byte_2                  # if img val is zero, skip
    lw a3, 44(sp)                       # a3 = output 1
    add a3, a3, a4                      # add img val to a31
    sw a3, 44(sp)                       # 44(sp) = output 1
    bge a1, x0, byte_2                  # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 44(sp)                       # 44(sp) = output 1

byte_2:
    blt a3, x0, saturate_down_byte1     # if less than 0, saturate to 0
    addi a1, x0, 256                    # store 256 to a1
    bge a3, a1, saturate_up_byte1       # if greater than 255, saturate to 255
    beq x0, x0, store_byte1

saturate_up_byte1:
    addi a3, x0, 255
    beq x0, x0, store_byte1

saturate_down_byte1:
    add a3, x0, x0

store_byte1:
    sw a3, 60(sp)                       # store output a3 to 60(sp)
    addi t1, t1, 1                      # current_col += 1
    addi a2, t1, 7                      # a2 = current_col + 7
    blt t4, a2, output_word             # if current_col exceeds max RGB bytes, move to next row

row_1_byte_2_col_1:
    lw a1, 96(sp)
    beq a1, x0, row_1_byte_2_col_2      # if kernel val is zero, skip
    lw t2, 48(sp)                       # t2 = row 1 word 1
    srli t2, t2, 8                      # t2 = second byte of word
    andi a4, t2, 255                    # a4 = second byte of word
    beq a4, x0, row_1_byte_2_col_2      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a3
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_1_byte_2_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_1_byte_2_col_2:
    lw a1, 100(sp)
    beq a1, x0, row_1_byte_2_col_3      # if kernel val is zero, skip
    lw t2, 72(sp)                       # t2 = row 1 word 2
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_1_byte_2_col_3      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_1_byte_2_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_1_byte_2_col_3:
    lw a1, 104(sp)
    beq a1, x0, row_2_byte_2_col_1      # if kernel val is zero, skip
    lw t2, 72(sp)                       # t2 = row 1 word 2
    srli a4, t2, 24                     # a1 = fourth byte of word
    beq a4, x0, row_2_byte_2_col_1      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_2_byte_2_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_2_byte_2_col_1:
    lw a1, 108(sp)
    beq a1, x0, row_2_byte_2_col_2      # if kernel val is zero, skip
    lw t2, 52(sp)                       # t2 = loaded word
    srli t2, t2, 8                      # t2 = second byte of word
    andi a4, t2, 255                    # a4 = second byte of word
    beq a4, x0, row_2_byte_2_col_2      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a3
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_2_byte_2_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_2_byte_2_col_2:
    lw a1, 112(sp)
    beq a1, x0, row_2_byte_2_col_3      # if kernel val is zero, skip
    lw t2, 76(sp)                       # t2 = loaded word
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_2_byte_2_col_3      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_2_byte_2_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_2_byte_2_col_3:
    lw a1, 116(sp)
    beq a1, x0, row_3_byte_2_col_1      # if kernel val is zero, skip
    lw t2, 76(sp)                       # t2 = row 2 word 2
    srli a4, t2, 24                     # a1 = fourth byte of word
    beq a4, x0, row_3_byte_2_col_1      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_3_byte_2_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_3_byte_2_col_1:
    lw a1, 120(sp)
    beq a1, x0, row_3_byte_2_col_2      # if kernel val is zero, skip
    lw t2, 56(sp)                       # t2 = row 3 word 1
    srli t2, t2, 8                      # t2 = second byte of word
    andi a4, t2, 255                    # a4 = second byte of word
    beq a4, x0, row_3_byte_2_col_2      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a3
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_3_byte_2_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_3_byte_2_col_2:
    lw a1, 124(sp)
    beq a1, x0, row_3_byte_2_col_3      # if kernel val is zero, skip
    lw t2, 80(sp)                       # t2 = row 3 word 1
    andi a4, t2, 255                    # a4 = first byte of word
    beq a4, x0, row_3_byte_2_col_3      # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, row_3_byte_2_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

row_3_byte_2_col_3:
    lw a1, 128(sp)
    beq a1, x0, byte_3                  # if kernel val is zero, skip
    lw t2, 80(sp)                       # t2 = row 3 word 2
    srli a4, t2, 24                     # a1 = fourth byte of word
    beq a4, x0, byte_3                  # if img val is zero, skip
    lw a3, 40(sp)                       # a3 = output 2
    add a3, a3, a4                      # add img val to a31
    sw a3, 40(sp)                       # 44(sp) = output 2
    bge a1, x0, byte_3                  # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 40(sp)                       # 44(sp) = output 2

byte_3:
    blt a3, x0, saturate_down_byte2     # if less than 0, saturate to 0
    addi a1, x0, 256                    # store 256 to a1
    bge a3, a1, saturate_up_byte2       # if greater than 255, saturate to 255
    beq x0, x0, store_byte2

saturate_up_byte2:
    addi a3, x0, 255
    beq x0, x0, store_byte2

saturate_down_byte2:
    add a3, x0, x0

store_byte2:
    slli a3, a3, 8                      # output val shifted left
    lw t3, 60(sp)
    add t3, t3, a3                      # combine output
    sw t3, 60(sp)
    addi t1, t1, 1                      # current_col += 1
    addi a2, t1, 7                      # a2 = current_col + 7
    blt t4, a2, output_word             # if current_col exceeds max RGB bytes, move to next row

row_1_byte_3_col_1:
    lw a1, 96(sp)
    beq a1, x0, row_1_byte_3_col_2      # if kernel val is zero, skip
    lw t2, 48(sp)                       # t2 = row 1 word 1
    srli a4, t2, 16                     # a4 = third byte of word
    andi a4, a4, 255                    # a4 = third byte of word
    beq a4, x0, row_1_byte_3_col_2      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a3
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_1_byte_3_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_1_byte_3_col_2:
    lw a1, 100(sp)
    beq a1, x0, row_1_byte_3_col_3      # if kernel val is zero, skip
    lw t2, 72(sp)                       # t2 = row 1 word 2
    srli a4, t2, 8                      # a4 = second byte of word
    andi a4, a4, 255                    # a4 = second byte of word
    beq a4, x0, row_1_byte_3_col_3      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_1_byte_3_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_1_byte_3_col_3:
    lw a1, 104(sp)
    beq a1, x0, row_2_byte_3_col_1      # if kernel val is zero, skip
    lw t2, 84(sp)                       # t2 = row 1 word 3
    andi a4, t2, 255                    # a1 = mask first byte of word
    beq a4, x0, row_2_byte_3_col_1      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_2_byte_3_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_2_byte_3_col_1:
    lw a1, 108(sp)
    beq a1, x0, row_2_byte_3_col_2      # if kernel val is zero, skip
    lw t2, 52(sp)                       # t2 = row 2 word 1
    srli t2, t2, 16                     # third byte of word
    andi a4, t2, 255                    # a4 = third byte of word
    beq a4, x0, row_2_byte_3_col_2      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a3
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_2_byte_3_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_2_byte_3_col_2:
    lw a1, 112(sp)
    beq a1, x0, row_2_byte_3_col_3      # if kernel val is zero, skip
    lw t2, 76(sp)                       # t2 = row 2 word 2
    srli a4, t2, 8                      # a4 = second byte of word
    andi a4, a4, 255                    # a4 = mask second byte
    beq a4, x0, row_2_byte_3_col_3      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_2_byte_3_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_2_byte_3_col_3:
    lw a1, 116(sp)
    beq a1, x0, row_3_byte_3_col_1      # if kernel val is zero, skip
    lw t2, 88(sp)                       # t2 = row 2 word 3
    andi a4, t2, 255                    # a1 = mask first byte of word
    beq a4, x0, row_3_byte_3_col_1      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_3_byte_3_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_3_byte_3_col_1:
    lw a1, 120(sp)
    beq a1, x0, row_3_byte_3_col_2      # if kernel val is zero, skip
    lw t2, 56(sp)                       # t2 = row 3 word 1
    srli t2, t2, 16                     # a4 = third byte of word
    andi a4, t2, 255                    # a4 = mask third byte of word
    beq a4, x0, row_3_byte_3_col_2      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a3
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_3_byte_3_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_3_byte_3_col_2:
    lw a1, 124(sp)
    beq a1, x0, row_3_byte_3_col_3      # if kernel val is zero, skip
    lw t2, 80(sp)                       # t2 = row 3 word 2
    srli a4, t2, 8                      # a4 = second byte of word
    andi a4, a4, 255                    # a4 = mask second byte
    beq a4, x0, row_3_byte_3_col_3      # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, row_3_byte_3_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

row_3_byte_3_col_3:
    lw a1, 128(sp)
    beq a1, x0, byte_4                  # if kernel val is zero, skip
    lw t2, 92(sp)                       # t2 = row 3 word 3
    andi a4, t2, 255                    # a1 = mask first byte of word
    beq a4, x0, byte_4                  # if img val is zero, skip
    lw a3, 36(sp)                       # a3 = output 3
    add a3, a3, a4                      # add img val to a31
    sw a3, 36(sp)                       # 44(sp) = output 3
    bge a1, x0, byte_4                  # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 36(sp)                       # 44(sp) = output 3

byte_4:
    blt a3, x0, saturate_down_byte3     # if less than 0, saturate to 0
    addi a1, x0, 256                    # store 256 to a1
    bge a3, a1, saturate_up_byte3       # if greater than 255, saturate to 255
    beq x0, x0, store_byte3

saturate_up_byte3:
    addi a3, x0, 255
    beq x0, x0, store_byte3

saturate_down_byte3:
    add a3, x0, x0

store_byte3:
    slli a3, a3, 16                     # output val shifted left
    lw t3, 60(sp)                       # t3 = output val
    add t3, t3, a3                      # combine output
    sw t3, 60(sp)
    addi t1, t1, 1                      # current_col += 1
    addi a2, t1, 7                      # a2 = current_col + 7
    blt t4, a2, output_word             # if current_col exceeds max RGB bytes, move to next row

row_1_byte_4_col_1:
    lw a1, 96(sp)
    beq a1, x0, row_1_byte_4_col_2      # if kernel val is zero, skip
    lw t2, 48(sp)                       # t2 = row 1 word 1
    srli a4, t2, 24                     # a4 = first byte of word
    beq a4, x0, row_1_byte_4_col_2      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a3
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_1_byte_4_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_1_byte_4_col_2:
    lw a1, 100(sp)
    beq a1, x0, row_1_byte_4_col_3      # if kernel val is zero, skip
    lw t2, 72(sp)                       # t2 = row 1 word 2
    srli a4, t2, 16                     # a4 = third byte of word
    andi a4, a4, 255                    # a4 = mask third byte
    beq a4, x0, row_1_byte_4_col_3      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a31
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_1_byte_4_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_1_byte_4_col_3:
    lw a1, 104(sp)
    beq a1, x0, row_2_byte_4_col_1      # if kernel val is zero, skip
    lw t2, 84(sp)                       # t2 = row 1 word 2
    srli a4, t2, 8                      # a1 = second byte of word
    andi a4, a4, 255                    # a1 = mask second byte of word
    beq a4, x0, row_2_byte_4_col_1      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a31
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_2_byte_4_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_2_byte_4_col_1:
    lw a1, 108(sp)
    beq a1, x0, row_2_byte_4_col_2      # if kernel val is zero, skip
    lw t2, 52(sp)                       # t2 = row 2 word 1
    srli a4, t2, 24                     # a4 = first byte of word
    beq a4, x0, row_2_byte_4_col_2      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a3
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_2_byte_4_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_2_byte_4_col_2:
    lw a1, 112(sp)
    beq a1, x0, row_2_byte_4_col_3      # if kernel val is zero, skip
    lw t2, 76(sp)                       # t2 = row 2 word 2
    srli a4, t2, 16                     # a4 = third byte of word
    andi a4, a4, 255                    # a4 = mask third byte
    beq a4, x0, row_2_byte_4_col_3      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a31
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_2_byte_4_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_2_byte_4_col_3:
    lw a1, 116(sp)
    beq a1, x0, row_3_byte_4_col_1      # if kernel val is zero, skip
    lw t2, 88(sp)                       # t2 = row 2 word 3
    srli a4, t2, 8                      # a1 = second byte of word
    andi a4, a4, 255                    # a1 = mask second byte of word
    beq a4, x0, row_3_byte_4_col_1      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a31
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_3_byte_4_col_1      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_3_byte_4_col_1:
    lw a1, 120(sp)
    beq a1, x0, row_3_byte_4_col_2      # if kernel val is zero, skip
    lw t2, 56(sp)                       # t2 = row 3 word 1
    srli a4, t2, 24                     # a4 = fourth byte of word
    beq a4, x0, row_3_byte_4_col_2      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a3
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_3_byte_4_col_2      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_3_byte_4_col_2:
    lw a1, 124(sp)
    beq a1, x0, row_3_byte_4_col_3      # if kernel val is zero, skip
    lw t2, 80(sp)                       # t2 = row 3 word 2
    srli a4, t2, 16                     # a4 = third byte of word
    andi a4, a4, 255                    # a4 = mask third byte
    beq a4, x0, row_3_byte_4_col_3      # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a31
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, row_3_byte_4_col_3      # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

row_3_byte_4_col_3:
    lw a1, 128(sp)
    beq a1, x0, store_output            # if kernel val is zero, skip
    lw t2, 92(sp)                       # t2 = row 3 word 3
    srli a4, t2, 8                      # a1 = second byte of word
    andi a4, a4, 255                    # a1 = mask second byte of word
    beq a4, x0, store_output            # if img val is zero, skip
    lw a3, 32(sp)                       # a3 = output 4
    add a3, a3, a4                      # add img val to a3
    sw a3, 32(sp)                       # 44(sp) = output 4
    bge a1, x0, store_output            # if kernel val is 1, add img val
    sub a3, a3, a4                      # subtract img val from a3
    sub a3, a3, a4                      # subtract img val from a3
    sw a3, 32(sp)                       # 44(sp) = output 4

store_output:
    blt a3, x0, saturate_down_byte4     # if less than 0, saturate to 0
    addi a1, x0, 256                    # store 256 to a1
    bge a3, a1, saturate_up_byte4       # if greater than 255, saturate to 255
    beq x0, x0, store_byte4

saturate_up_byte4:
    addi a3, x0, 255
    beq x0, x0, store_byte4

saturate_down_byte4:
    add a3, x0, x0

store_byte4:
    slli a3, a3, 24                     # output val shifted left
    lw t3, 60(sp)                       # t3 = output val
    add t3, t3, a3                      # combine output
    sw t3, 60(sp)

output_word:
    lw a4, 8(sp)                        # a4 = outptr
    lw t3, 60(sp)
    sw t3, 0(a4)                        # store t3 to outptr
    addi a4, a4, 4                      # increment outptr by 4
    sw a4, 8(sp)                        # store outptr
    lw a0, 24(sp)                       # a0 = imgptr
    addi a0, a0, 4                      # increment imgptr by 4
    sw a0, 24(sp)                       # store imgptr
    lw t1, 0(sp)                        # t1 = current_col
    addi t1, t1, 4                      # increment current_col by 4
    sw t1, 0(sp)                        # store current_col
    beq x0, x0, boundary_check

finish:
    addi sp, sp, 132
    ret
