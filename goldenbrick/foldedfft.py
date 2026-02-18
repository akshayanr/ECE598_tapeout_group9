import numpy as np
from numpy.fft import fft
import argparse
import sys
import os

# Add the common script to our path so we can get some epic func's
script_dir = os.path.dirname(__file__) 
scripts_path = os.path.join(script_dir, '../common') 
sys.path.append(scripts_path) 

from common import fp16_to_hex

#NOTE: SRAM IS ACURATELY MODELED AS A 2D LIST WHERE EACH ROW IS AN ADDRESS LINE, but write and read is simplified
#doesn't coinsider activation. 

#TODO: NEED TO FIGURE OUT WHEN WE READ DO WE READ THE WHOLE LINE, so the read signal triggers the entire line.

class Reconfigurable_FFT:
    def __init__(self, point_size, butterfly_count, mult_pipeline_stages, options):

        #configuration of points
        self.point_size = point_size
        #the butterfly count in the stage.
        self.butterfly_count = butterfly_count

        #the number of mulitiplication stages.
        self.mult_pipeline_stages = mult_pipeline_stages
        
        # Performance Tracking
        self.total_cycles = 0

        # Twiddle ROM
        self.twiddle_rom = self.generate_twiddle_factors()


        #the depth of the sram memory banks.
        self.memory_depth = 1024  // butterfly_count

        # Initialize SRAMs (Using complex numbers for simulation simplicity
        #the sram is going to be a ping pong mechanism because we could be sending data in while we operate.
        #we could have an option to read from sram while we do sram processing of another set of 1024 points.
        self.sram_a = [[0+0j]*butterfly_count for _ in range(self.memory_depth)]
        self.sram_b = [[0+0j]*butterfly_count for _ in range(self.memory_depth)]

      
        self.operating_sram = 'a'

        self.done = False

        self.options = options


    #can read if the fft is done operating through all stages.
    def get_done(self):
        return self.done
    
    #this function is purely for debugging; it's there for comparison with an actual fft.
    #TODO: Need to think about which sram has the result in the verilog version
    def sram_read_debug(self):
        #we write to write_sram not the operating - which we use for reading, so need to return the write_sram
        #but no, we swap always at the end, so the former write_sram becomes the actual sram.
        if self.operating_sram == 'a':
            return self.sram_a
        else:
            return self.sram_b


    
    #can tell which sram is the most recently operated on.
    def get_operating_sram(self):
        return self.operating_sram
    
    #need to remember to call this after loading the data into the sram. 
    def set_operating_sram(self, sram_bank):
        self.operating_sram = sram_bank
        
    #function to generate twiddle factors
    def generate_twiddle_factors(self):
        twiddles = []
        for k in range(self.point_size // 2):
            W = np.exp(-2j * np.pi * k / self.point_size)
            twiddles.append(W)
        return twiddles
    
    #gets the twiddle factor needed.
    def get_twiddle_factor(self, k):
        return self.twiddle_rom[k]

    #function to load data into the sram banks
    #it's one the user to select which sram to load into.
    #the user has to check done and which sram is being operated on.
    #we can input 32 bits complex number so it is one entry per index.
    def load_data(self, input_arr, sram_bank, input_address):
        #the address provided will be an index.

        #Width is butterfly count
        WIDTH = self.butterfly_count


        row = input_address // WIDTH   
        col = input_address % WIDTH

        #NEED TO KEEP IN MIND THAT READ ADDRESS TRANSLATION WILL HAVE TO BE DONE IN THE ADDRESS DECODER
        #AND WE NEED TO WORRY ABOUT ACTIVATING THE ENTIRE LINE.
        if sram_bank == 'a':
            self.sram_a[row][col] = input_arr
        else:
            self.sram_b[row][col] = input_arr

    #similar to loading the data, the user's will be responsible for reading from the correct sram bank.
    def read_data(self, sram_bank, input_address):
        #read from the sram bank that has the finished data and not operating.
        #need to figure this out.

        #Width is butterfly count
        WIDTH = self.butterfly_count


        row = input_address // WIDTH   
        col = input_address % WIDTH
        
        if sram_bank == 'a':
            return self.sram_a[row][col]
        else:
            return self.sram_b[row][col]
        
    #butterfly unit
    def butterfly_unit(self, val_a, val_b, twiddle):
        top_out = val_a + val_b
        bot_out = (val_a - val_b) * twiddle

        #TODO : Need to get back to this.
        # for _ in range(self.mult_pipeline_stages):
        #     self.total_cycles += 1  # Simulate pipeline delay
        #     print(f"    [Pipeline] Processing... (Cycle {self.total_cycles})")
        return top_out, bot_out

    def calculate_fft(self):
        num_stages = int(np.log2(self.point_size))
        
        # print(f"--- STARTING FFT (N={self.point_size}) ---")
        # print(f"Config: {self.butterfly_count} Parallel Units | Pipeline Depth: {self.mult_pipeline_stages}")
        
        #the stride starts at N/2
        stride = self.point_size // 2

        #the total number of butterflies
        total_num_butterflies = self.point_size // 2


        #current_sram is the sram we read from.
        if(self.operating_sram == 'a'):
            current_sram = self.sram_a
            write_sram = self.sram_b
        else:
            current_sram = self.sram_b
            write_sram = self.sram_a
       
        if(self.options.datapath_test):
            input_file = open('datapath.in.txt', 'w')
            output_file = open('datapath.out.txt', 'w')

        if(self.options.fft_top_test):
            write_log = open('mem_writes.txt', 'w')
            write_log_fp16 = open('mem_writes_fp16.txt', 'w')

        for stage in range(num_stages):
            #so this idx is accurate of the cycles -> each idx would ideally be a cycle.
            #this is the number of butterflies per stage.

            #every cycle we will always do butterfly_count amount of calculations.
            #set idx and use a while loop to accomodate the intra-row case.

            #inter-row case:
            if stride >= self.butterfly_count:
                for idx in range(0, total_num_butterflies, self.butterfly_count):

                    #there is grouping, so when N = 8, and stride is 2 and butterfly is like 1
                    #the instance where 4 needs to map to 6 but instead will pair with 8.

                    #this maps the group that the row belongs to.
                    group = idx // stride 

                    #offet is the distance to the bottom.
                    offset = idx % stride
                    
                    #stride is to jump to the correct group.
                    base_top_idx = (group * (2 * stride)) + offset

                    #the bottom gets the stride. 
                    base_bot_idx = base_top_idx + stride
                    
                    # Convert logical indices to SRAM Rows
                    top_row = base_top_idx // self.butterfly_count
                    bot_row = base_bot_idx // self.butterfly_count

                    input_top = current_sram[top_row]
                    input_bot = current_sram[bot_row]

                    if(self.options.datapath_test):
                        input_file.write(f'{stride} ')
                        for butterfly in range(self.butterfly_count):
                            input_file.write(f'{fp16_to_hex(input_top[butterfly].real)}{fp16_to_hex(input_top[butterfly].imag)} ')
                        for butterfly in range(self.butterfly_count):
                            input_file.write(f'{fp16_to_hex(input_bot[butterfly].real)}{fp16_to_hex(input_bot[butterfly].imag)} ')

                    output_top = [0j] * self.butterfly_count
                    output_bot = [0j] * self.butterfly_count
        
                    for col_idx in range(self.butterfly_count):
                        val_a = input_top[col_idx]
                        val_b = input_bot[col_idx]

                        #the absolute index -> some number from 0 to 1024.
                        abs_index = base_top_idx + col_idx
                        
                        #position in group determined by stride.
                        position_in_group = abs_index % stride

                        #the jump per stride.
                        twiddle_stride = self.point_size // (2 * stride)

                        #the position and the stride.
                        k = position_in_group * twiddle_stride

                        if(self.options.datapath_test):
                            input_file.write(f'{1024//self.point_size * k} ')

                        twiddle = self.get_twiddle_factor(k)

                        out_a, out_b = self.butterfly_unit(val_a, val_b, twiddle)
                        
                        output_top[col_idx] = out_a
                        output_bot[col_idx] = out_b

                    write_sram[top_row] = output_top
                    write_sram[bot_row] = output_bot

                    if(self.options.datapath_test):
                        for butterfly in range(self.butterfly_count):
                            output_file.write(f'{fp16_to_hex(output_top[butterfly].real)}{fp16_to_hex(output_top[butterfly].imag)} ')
                        for butterfly in range(self.butterfly_count):
                            output_file.write(f'{fp16_to_hex(output_bot[butterfly].real)}{fp16_to_hex(output_bot[butterfly].imag)} ')
                        input_file.write('\n')
                        output_file.write('\n')
                    
                    if(self.options.fft_top_test):
                        write_log.write(f'{top_row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log.write(f'{fp16_to_hex(output_top[self.butterfly_count - 1 - butterfly].real)}{fp16_to_hex(output_top[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log.write(f'\n{bot_row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log.write(f'{fp16_to_hex(output_bot[self.butterfly_count - 1 - butterfly].real)}{fp16_to_hex(output_bot[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log.write('\n')
                        write_log_fp16.write(f'{top_row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log_fp16.write(f'{(output_top[self.butterfly_count - 1 - butterfly].real)}{(output_top[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log_fp16.write(f'\n{bot_row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log_fp16.write(f'{(output_bot[self.butterfly_count - 1 - butterfly].real)}{(output_bot[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log_fp16.write('\n')

            #intra-row case:
            else:
                row = 0
                active_depth = self.point_size // self.butterfly_count
                while row < active_depth:
                    first_row = current_sram[row]
                    second_row = current_sram[row + 1]

                    if(self.options.datapath_test):
                        input_file.write(f'{stride} ')
                        for butterfly in range(self.butterfly_count):
                            input_file.write(f'{fp16_to_hex(first_row[butterfly].real)} {fp16_to_hex(first_row[butterfly].imag)} ')
                        for butterfly in range(self.butterfly_count):
                            input_file.write(f'{fp16_to_hex(second_row[butterfly].real)} {fp16_to_hex(second_row[butterfly].imag)} ')


                    #create a data_pool of both rows
                    data_pool = first_row + second_row

                    #outputs
                    output_first_row = [0j] * self.butterfly_count
                    output_second_row = [0j] * self.butterfly_count

                    for k in range(self.butterfly_count):

                        #which group the element belongs to.
                        group_id = k // stride
                    
                        #local offset within that group
                        local_offset = k % stride

                        #calculate index in combined data pool
                        #each group consumes (2 * stride) amount of data.
                        base_idx = (group_id * 2 * stride) + local_offset

                        #top is at base, Bottom is always 'stride' away from Top
                        val_a = data_pool[base_idx]
                        val_b = data_pool[base_idx + stride]


                        #now need to calculate twiddle factor
                        abs_index = (row * self.butterfly_count) + base_idx


                        #this tells us which group of weights
                        position_in_group = abs_index % stride

                        #twiddle stride because the number of indexed decreases each stage.
                        twiddle_stride = self.point_size // (2 * stride)

                        #twiddle index.
                        twiddle_idx = position_in_group * twiddle_stride

                        if(self.options.datapath_test):
                            input_file.write(f'{1024//self.point_size * twiddle_idx} ')

                        twiddle = self.get_twiddle_factor(twiddle_idx)

                        #butterfly unit
                        out_a, out_b = self.butterfly_unit(val_a, val_b, twiddle)
                        
                        #if base_idx is less than butterfly count so in first row
                        if base_idx < self.butterfly_count:
                            output_first_row[base_idx] = out_a
                        #base_idx is in the second row.
                        else:
                            output_second_row[base_idx - self.butterfly_count] = out_a

                        #base_idx + stride
                        bot_idx = base_idx + stride

                        #bot_idx is the bottom input.
                        if bot_idx < self.butterfly_count:
                            output_first_row[bot_idx] = out_b

                        else:
                            output_second_row[bot_idx - self.butterfly_count] = out_b

                    write_sram[row] = output_first_row
                    write_sram[row + 1] = output_second_row

                    if(self.options.datapath_test):
                        for butterfly in range(self.butterfly_count):
                            output_file.write(f'{fp16_to_hex(output_first_row[butterfly].real)}{fp16_to_hex(output_first_row[butterfly].imag)} ')
                        for butterfly in range(self.butterfly_count):
                            output_file.write(f'{fp16_to_hex(output_second_row[butterfly].real)}{fp16_to_hex(output_second_row[butterfly].imag)} ')
                        input_file.write('\n')
                        output_file.write('\n')

                    if(self.options.fft_top_test):
                        write_log.write(f'{row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log.write(f'{fp16_to_hex(output_first_row[self.butterfly_count - 1 - butterfly].real)}{fp16_to_hex(output_first_row[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log.write(f'\n{row+1} ')
                        for butterfly in range(self.butterfly_count):
                            write_log.write(f'{fp16_to_hex(output_second_row[self.butterfly_count - 1 - butterfly].real)}{fp16_to_hex(output_second_row[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log.write('\n')
                        write_log_fp16.write(f'{row} ')
                        for butterfly in range(self.butterfly_count):
                            write_log_fp16.write(f'{(output_first_row[self.butterfly_count - 1 - butterfly].real)} {(output_first_row[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log_fp16.write(f'\n{row + 1} ')
                        for butterfly in range(self.butterfly_count):
                            write_log_fp16.write(f'{(output_second_row[self.butterfly_count - 1 - butterfly].real)} {(output_second_row[self.butterfly_count - 1 - butterfly].imag)} ')
                        write_log_fp16.write('\n')

                    #increase row
                    row += 2


            
            #ping pong effect to switch sram banks after each stage.
            if(self.operating_sram == 'a'):
                self.operating_sram = 'b'
                current_sram = self.sram_b
                write_sram = self.sram_a
            else:
                self.operating_sram = 'a'
                current_sram = self.sram_a
                write_sram = self.sram_b

            #update stride for the next cycle.
            stride = stride // 2
        
        #fft is done, so
        self.done = True


#function that helps compare DIF with numpy's built-in version.
def bit_reverse_reorder(data, n):
    width = int(np.log2(n))
    reordered = [0] * n
    for i in range(n):
        # Generate bit-reversed index
        # for example -> N=8 index 1 (001) -> 4 (100)
        rev_i = int('{:0{w}b}'.format(i, w=width)[::-1], 2)
        reordered[rev_i] = data[i]
    return reordered

#function to run test_case
def run_test_case(test_name, input_signal, fft_hw, N):
    print(f"\n[TEST] Running: {test_name}")
    
    #load data
    # We load into Bank 'a' and set 'a' as the active starting point
    for i, val in enumerate(input_signal):
        fft_hw.load_data(val, 'a', i)
    fft_hw.set_operating_sram('a') 

    #run Hardware calculate FFT
    fft_hw.calculate_fft()

    #read the output from the sram that has the result
    result_bank = fft_hw.get_operating_sram()

    #store the outputs 
    hw_output_raw = []
    
    #read the outputs as you could from the chip in the verification class
    for i in range(N):
        hw_output_raw.append(fft_hw.read_data(result_bank, i))

    #unscramble the results
    hw_output_ordered = bit_reverse_reorder(hw_output_raw, N)

    # compare with Golden Reference - NumPy
    np_result = np.fft.fft(input_signal)
    
    # Calculate Error
    # We accept a small tolerance (1e-5) for floating point rounding differences
    is_match = np.allclose(hw_output_ordered, np_result, atol=1e-5)

    # Report
    max_error = np.max(np.abs(np.array(hw_output_ordered) - np_result))
    print(f"   Status: {'PASS' if is_match else 'FAIL'}")
    print(f"   Max Error: {max_error:.6f}")
    
    return is_match

def main(options):
    # Configuration
    N = options.num_points
    BUTTERFLY_COUNT = options.num_butterflys
    STAGES = 0 # Not used in logic yet
    
    print(f"INITIALIZING HW MODEL (N={N}, Width={BUTTERFLY_COUNT})")
    fft_hw = Reconfigurable_FFT(point_size=N, butterfly_count=BUTTERFLY_COUNT, mult_pipeline_stages=STAGES, options=options)

    # --- TEST 1: Pure Sine Wave ---
    # Good for checking frequency alignment
    t = np.linspace(0, 1, N, endpoint=False)
    signal_sine = np.sin(2 * np.pi * 50 * t) # 50 Hz tone
    if(options.fft_top_test):
        with open('mem_init.txt', 'w') as file:
            for point in range(0, N, BUTTERFLY_COUNT):
                for col in range(BUTTERFLY_COUNT):
                    # Want MSB first in mem init file
                    file.write(f'{fp16_to_hex(signal_sine[point + (BUTTERFLY_COUNT - 1 - col)].real)}{fp16_to_hex(signal_sine[point + (BUTTERFLY_COUNT - 1 - col)].imag)}' )
                file.write('\n')
    print(run_test_case("Sine Wave (50Hz)", signal_sine, fft_hw, N))

    # --- TEST 2: Impulse Response ---
    # Input: [1, 0, 0, ...]. Output should be [1, 1, 1, ...] (Flat Magnitude)
    # If this fails, your butterflies are scaling/twiddling incorrectly.
    # signal_impulse = np.zeros(N)
    # signal_impulse[0] = 1.0
    # print(run_test_case("Impulse Response", signal_impulse, fft_hw, N))

    # --- TEST 3: Random Complex Noise ---
    # Stress tests every path with non-symmetrical data
    # np.random.seed(42) # Deterministic random
    # signal_random = np.random.rand(N).astype(np.float16) + 1j * np.random.rand(N).astype(np.float16)
    # Generate a mem init file for our fft_top_tb
    # if(options.fft_top_test):
    #     with open('mem_init.txt', 'w') as file:
    #         for point in range(0, N, BUTTERFLY_COUNT):
    #             for col in range(BUTTERFLY_COUNT):
    #                 # Want MSB first in mem init file
    #                 file.write(f'{fp16_to_hex(signal_random[point + (BUTTERFLY_COUNT - 1 - col)].real)}{fp16_to_hex(signal_random[point + (BUTTERFLY_COUNT - 1 - col)].imag)}' )
    #             file.write('\n')
    # print(run_test_case("Random Complex Noise", signal_random, fft_hw, N))

    # if(options.fft_top_test):
    #     # --- TEST 4: Linear function ---
    #     # Counts up by 1
    #     linear_signal = np.linspace(0, N-1, N)
    #     print(linear_signal)
    #     # Generate a mem init file for our fft_top_tb
    #     with open('mem_init.txt', 'w') as file:
    #         for point in range(0, N, BUTTERFLY_COUNT):
    #             for col in range(BUTTERFLY_COUNT):
    #                 # Want MSB first in mem init file
    #                 file.write(f'{fp16_to_hex(linear_signal[point + (BUTTERFLY_COUNT - 1 - col)].real)}{fp16_to_hex(linear_signal[point + (BUTTERFLY_COUNT - 1 - col)].imag)}' )
    #             file.write('\n')
    #     print(run_test_case("Linear y = x", linear_signal, fft_hw, N))

if __name__ == "__main__":


    parser = argparse.ArgumentParser(
                        prog='foldedfft.py',
                        description='fft_goldenbrick',
                        epilog='teehee')

    parser.add_argument('-np', '--num_points', type=int, default=16)
    parser.add_argument('-nb', '--num_butterflys', type=int, default=4)
    parser.add_argument('-datapath_test', '--datapath_test', action='store_true')
    parser.add_argument('-fft_top_test', '--fft_top_test', action='store_true')


    options = parser.parse_args()

    main(options)