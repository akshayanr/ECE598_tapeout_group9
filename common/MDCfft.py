import numpy as np
from numpy.fft import fft

twiddle_rom = []

def calculate_fft(input_arr):
    num_points = len(input_arr)
    num_stages = int(np.log2(num_points))

    input_a = input_arr[0:(num_points//2)]
    input_b = input_arr[(num_points//2):num_points]

    print(f"num_points: {num_points} num_stages: {num_stages} len_a: {len(input_a)} len_b: {len(input_b)}")

    # Do all the stages but the last
    for stage in range(num_stages - 1):
        real_stage = stage + 1
        output_a = np.zeros(num_points//2, dtype=complex)
        output_b = np.zeros(num_points//2, dtype=complex)
        # output_a = input_a
        # output_b = input_b

        # Do the butterfly
        print(f"################ STAGE: {real_stage}")
        for idx in range(len(input_a)):
            a1 = input_a[idx]
            b1 = input_b[idx]
            #output_a[idx], output_b[idx] = butterfly(a1, b1, num_stages, real_stage, idx)
            output_a[idx], output_b[idx] = butterfly_table(a1, b1, num_stages, real_stage, idx)

        # Do the comutation
        input_a, input_b = commutate(output_a, output_b, num_stages, real_stage)
    
    # Do the last stage
    print(f"################ STAGE: {num_stages}")
    output_a = np.zeros(num_points//2, dtype=complex)
    output_b = np.zeros(num_points//2, dtype=complex)
    for idx in range(len(input_a)):
            a1 = input_a[idx]
            b1 = input_b[idx]
            #output_a[idx], output_b[idx] = butterfly(a1, b1, num_stages, num_stages, idx)
            output_a[idx], output_b[idx] = butterfly_table(a1, b1, num_stages, num_stages, idx)

    # Remake serial output arr
    output_arr = np.zeros(num_points, dtype=complex)
    for idx in range(num_points//2):
        output_arr[idx*2] = output_a[idx]
        output_arr[idx*2+1] = output_b[idx]

    print("################## DONE")
    return output_arr

# Calculates the twiddle factor everytime
def butterfly(a1, b1, num_stages, stage, calc_count):

    # Calculate twiddle factor
    N = 2**(num_stages - stage + 1)
    Q = calc_count % (N // 2)
    Wkn = np.exp(-2j*np.pi*Q/N)

    # Do the butterfly
    print(f"N: {N} Q: {Q} Twiddle: {Wkn}")
    a2 = a1 + b1
    b2 = (a1 - b1) * Wkn
    return a2, b2

# Uses a table to get the twiddle factor
def butterfly_table(a1, b1, num_stages, stage, calc_count):

    # Generate table if it doesn't exist
    if(len(twiddle_rom) == 0):
        generate_twiddle_rom(num_stages)
        print(f"Generated twiddle table size: {len(twiddle_rom)}")
    
    # Get the correct twiddle factor from the table
    stride = 2**(stage-1)
    table_idx = int((stride * calc_count) % (2**(num_stages - 1))) 
    Wkn = twiddle_rom[table_idx]

    # Do the butterfly
    print(f"stride: {stride} table_idx: {table_idx} Twiddle: {Wkn}")
    a2 = a1 + b1
    b2 = (a1 - b1) * Wkn
    return a2, b2

def generate_twiddle_rom(num_stages):
    num_points = 2**num_stages
    num_calcs = (num_points >> 1)
    for idx in range(num_calcs):
        Q = idx
        N = num_points
        Wkn = np.exp(-2j*np.pi*Q/N)
        twiddle_rom.append(Wkn)

def commutate(input_a, input_b, num_stages, stage):
    # I determined this all by just looking at it
    start = ((2**num_stages) // (2 << (stage)))
    length = start
    num_swaps = stage
    swap_stride = 2*length

    arr1 = input_a
    arr2 = input_b
    print(f"NUM_SWAPS: {num_swaps}")
    for swap in range(num_swaps):
        print(f"start: {start} length: {length} swap: {swap+1} swap_stride: {swap_stride}")
        # TIL that python does not do deep copies unless you tell it to, dont ask me how long it took to figure that out
        tmp1 = arr2[start-length:start].copy()
        tmp2 = arr1[start:start+length].copy()
        arr1[start:start+length] = tmp1
        arr2[start-length:start] = tmp2
        start += swap_stride

    return arr1, arr2
    
sample_length = 16
input_arr = np.random.rand(sample_length)
my_fft = calculate_fft(input_arr)
golden_fft = fft(input_arr)

print(my_fft)
print(golden_fft)