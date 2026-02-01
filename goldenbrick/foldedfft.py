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
        
        #the stride starts at N/2
        stride = self.point_size // 2

        #the total number of butterflies
        total_num_butterflies = self.point_size // 2


        #need to get operating sram
        current_sram = self.get_operating_sram()

        for stage in range(num_stages):
            #so this idx is accurate of the cycles -> each idx would ideally be a cycle.
            #this is the number of butterflies per stage.

            #every cycle we will always do butterfly_count amount of calculations.
            for idx in range(0, total_num_butterflies, self.butterfly_count):
                #inter-row butterfly processing
                if stride >= self.butterfly_count:
                    #the row that we want.
                    row = idx // self.butterfly_count

                    input_top = current_sram[row]
                    input_bot = current_sram[row + stride]

                    #next need to feed into the butterfly units.
                #intra-row butterfly processing.
                else:

            
            #ping pong effect to switch sram banks after each stage.
            if(self.operating_sram == 'a'):
                self.operating_sram = 'b'
                current_sram = self.sram_b
            else:
                self.operating_sram = 'a'
                current_sram = self.sram_a


                        

            #update stride for the next cycle.
            stride = stride // 2
        return self.sram_a + self.sram_b

