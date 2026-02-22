import numpy as np
import re
import sys

# thanks gemini
def hex_to_fp16(hex_16):
    try:
        bits = np.uint16(int(hex_16, 16))
        return bits.view(np.float16)
    except:
        return np.nan

def parse_chunk_to_complex(chunk):
    imag = hex_to_fp16(chunk[0:4])
    real = hex_to_fp16(chunk[4:8])
    return real, imag

def bit_reverse_reorder(data, n):
    width = int(np.log2(n))
    reordered = [0] * n
    for i in range(n):
        # Generate bit-reversed index
        # for example -> N=8 index 1 (001) -> 4 (100)
        rev_i = int('{:0{w}b}'.format(i, w=width)[::-1], 2)
        reordered[rev_i] = data[i]
    return reordered

def check(output_filepath, correct_raw_filepath, correct_filepath):
    output_file = open(output_filepath, 'r')
    correct_raw_file = open(correct_raw_filepath, 'r')

    output = output_file.readlines()
    correct_raw = correct_raw_file.readlines()
    
    print(f'# output {len(output)}')
    print(f'# correct {len(correct_raw)}')

    print(f'COMPARING OUTPUT V. GOLDENBRICK')
    largest_delta = 0
    delta_threshold = 0.1
    print(f'Threshold: {delta_threshold}')
    err_count = 0
    for idx in range(len(output)):

        real_out, imag_out = parse_chunk_to_complex(output[idx])
        real_correct, imag_correct = parse_chunk_to_complex(correct_raw[idx])
        # print(f"real_out: {real_out} imag_out: {imag_out} real_correct: {real_correct} imag_correct: {imag_correct}")
        real_delta = abs(real_correct - real_out)
        imag_delta = abs(imag_correct - imag_out)
        delta = max(real_delta, imag_delta)
        largest_delta = max(delta, largest_delta)
        if delta > delta_threshold:
            print(f'Output at line [{idx}] is has too big of a delta: {delta}')
            err_count += 1
            
    print(f"Data Errors that exceed threshold: {err_count}")
    print(f"Largest Delta {largest_delta}")

    output_reversed = bit_reverse_reorder(output, len(output))
    correct_file = open(correct_filepath, 'r')
    correct = correct_file.readlines()

    print(f'COMPARING OUTPUT V. NUMPY FFT')
    largest_delta = 0
    delta_threshold = 0.1
    print(f'Threshold: {delta_threshold}')
    err_count = 0
    for idx in range(len(output)):
        real_out, imag_out = parse_chunk_to_complex(output_reversed[idx])
        real_correct, imag_correct = parse_chunk_to_complex(correct[idx])
        real_delta = abs(real_correct - real_out)
        imag_delta = abs(imag_correct - imag_out)
        delta = max(real_delta, imag_delta)
        largest_delta = max(delta, largest_delta)
        if delta > delta_threshold:
            print(f'Output at line [{idx}] is has too big of a delta: {delta}')
            err_count += 1
            
    print(f"Data Errors that exceed threshold: {err_count}")
    print(f"Largest Delta {largest_delta}")
    
                

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python output_check.py <output> <correct_raw> <correct>")
    else:
        check(sys.argv[1], sys.argv[2], sys.argv[3])