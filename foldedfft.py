import numpy as np
from numpy.fft import fft

#NOTE: SRAM IS ACURATELY MODELED AS A 2D LIST WHERE EACH ROW IS AN ADDRESS LINE, but write and read is simplified
#doesn't coinsider activation. 

#TODO: NEED TO FIGURE OUT WHEN WE READ DO WE READ THE WHOLE LINE, so the read signal triggers the entire line.

class Reconfigurable_FFT:
    def __init__(self, point_size, butterfly_count, mult_pipeline_stages):

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


    #can read if the fft is done operating through all stages.
    def get_done(self):
        return self.done
    
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

    #function to load data into the sram banks
    #it's one the user to select which sram to load into.
    #the user has to check done and which sram is being operated on.
    #we can input 32 bits complex number so it is one entry per index.
    def load_data(self, input_arr, sram_bank, input_address):
        #the address provided will be an index.

        #Width is butterfly count
        WIDTH = self.butterfly_count


        row = input_index // WIDTH   
        col = input_index % WIDTH

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


        row = input_index // WIDTH   
        col = input_index % WIDTH
        
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
        
        #the number of ops per fft.
        total_ops = self.point_size // 2

        for stage in range(num_stages):
            # print(f"\n[Stage {stage}] Processing...")
             
            # We process data in chunks of 'butterfly_count
            for idx in range(0, total_ops, self.butterfly_count):
                
                #loading the data from the two srams take 1 cycle.
                self.total_cycles += 1
                
                #need to understand which line to read from.
                #first set of data for the butterflies.
                input_a = self.sram_a[idx : idx + self.butterfly_count]

                #need to do somemath to figure out which sram to 
                chunk_b = self.sram_b[idx : idx + self.butterfly_count]

                #our results.
                results_top = []
                results_bot = []
                
                for i in range(self.butterfly_count):
                    physical_index = idx + i
                    
                    # Twiddle Logic
                    group_len = self.point_size // (2**(stage + 1))
                    twiddle_idx = (physical_index % group_len) * (2**stage)
                    W = self.twiddle_rom[twiddle_idx]
                    
                    res_top, res_bot = self.butterfly_unit(chunk_a[i], chunk_b[i], W)
                    results_top.append(res_top)
                    results_bot.append(res_bot)

                #writeback phase
                for i in range(self.butterfly_count):
                    physical_write_addr = idx + i
                    shift_check = (self.point_size // (2**(stage + 2)))
                    if shift_check == 0: shift_check = 1
                    
                    should_swap = (physical_write_addr // shift_check) % 2 == 1
                    if stage == num_stages - 1: should_swap = False

                    if not should_swap:
                        next_sram_a[physical_write_addr] = results_top[i]
                        next_sram_b[physical_write_addr] = results_bot[i]
                    else:
                        next_sram_b[physical_write_addr] = results_top[i]
                        next_sram_a[physical_write_addr] = results_bot[i]

            # Update SRAMs
            self.sram_a = next_sram_a
            self.sram_b = next_sram_b

            total_ops = total_ops // 2

        print(f"\n--- FFT COMPLETE ---")
        print(f"Total Cycles: {self.total_cycles}")
        
        # Overhead calculation
        ideal_cycles = (self.point_size / 2 / self.butterfly_count) * num_stages
        overhead = self.total_cycles - ideal_cycles
        print(f"Pipeline Overhead: {overhead} cycles (due to stage start/stop latency)")

        return self.sram_a + self.sram_b

# --- TEST ---
N = 1024
# Simulating 8 Butterflies with a Multiplier Pipeline Depth of 4 cycles
fft_hardware = Reconfigurable_FFT(point_size=N, butterfly_count=8, mult_pipeline_stages=4)

data = np.arange(N, dtype=complex)
fft_hardware.load_data(data)

output = fft_hardware.calculate_fft()

# Verification
print("\nVerification (First 3 terms):")
print("HW:", output[:3])
print("NP:", np.fft.fft(data)[:3])