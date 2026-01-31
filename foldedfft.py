import numpy as np
from numpy.fft import fft

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

        # Initialize SRAMs (Using complex numbers for simulation simplicity)
        self.sram_a = [0+0j for _ in range(point_size // 2)]
        self.sram_b = [0+0j for _ in range(point_size // 2)]

    #function to generate twiddle factors
    def generate_twiddle_factors(self):
        twiddles = []
        for k in range(self.point_size // 2):
            W = np.exp(-2j * np.pi * k / self.point_size)
            twiddles.append(W)
        return twiddles

    #function to load data into the sram banks
    def load_data(self, input_arr):
        half = self.point_size // 2
        self.sram_a = list(input_arr[0:half])
        self.sram_b = list(input_arr[half:])
        
        # Reset cycles on new load
        self.total_cycles = 0

    #butterfly unit
    def butterfly_unit(self, val_a, val_b, twiddle):
        top_out = val_a + val_b
        bot_out = (val_a - val_b) * twiddle
        return top_out, bot_out

    def calculate_fft(self):
        num_stages = int(np.log2(self.point_size))
        
        print(f"--- STARTING FFT (N={self.point_size}) ---")
        print(f"Config: {self.butterfly_count} Parallel Units | Pipeline Depth: {self.mult_pipeline_stages}")
        
        #the number of ops per fft.
        total_ops = self.point_size // 2

        for stage in range(num_stages):
            print(f"\n[Stage {stage}] Processing...")
            
            # Prepare buffers for next stage
            next_sram_a = [0j] * len(self.sram_a)
            next_sram_b = [0j] * len(self.sram_b)
            
            # We process data in chunks of 'butterfly_count
            for idx in range(0, total_ops, self.butterfly_count):
                
                #loading the data from the two srams take 1 cycle.
                self.total_cycles += 1
                
                chunk_a = self.sram_a[idx : idx + self.butterfly_count]
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