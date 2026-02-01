import numpy as np
import argparse
import sys
import os

# Add the common script to our path so we can get some epic func's
script_dir = os.path.dirname(__file__) 
scripts_path = os.path.join(script_dir, '../common') 
sys.path.append(scripts_path) 

from common import fp16_to_binary

r_idx = 0
i_idx = 1

def complex_mult(inputs):
    r_mcand  = inputs[r_idx]   # a
    i_mcand  = inputs[i_idx]   # b
    r_mplier = inputs[r_idx+2] # c
    i_mplier = inputs[i_idx+2] # d

    result = np.zeros(2)
    # (a + bi)(c + di)
    # real = ac - bd
    # imag = ad + bc
    result[r_idx] = (r_mcand * r_mplier) - (i_mcand * i_mplier)
    result[i_idx] = (r_mcand * i_mplier) + (i_mcand * r_mplier)

    return result

def main(options):
    
    # Generate random inputs 
    arr_dim = (options.num_inputs, 4)
    rng   = np.random.default_rng(options.seed)
    test_inputs  = rng.uniform(options.lower, options.upper, arr_dim).astype(np.float16)

    if options.verbose:
        print(options)
        print(test_inputs)

    inputs  = np.zeros(4) # input latch reg
    reg1    = np.zeros(4) # input reg
    reg2    = np.zeros(2) # intermeditate reg
    reg3    = np.zeros(2) # output reg
    outputs = np.zeros(2) # output latch reg

    if(options.verbose):
        print("IN:   real_a   imag_a   real_b   imag_b   |   OUT:   real_a   imag_a   real_b   imag_b")

    # Run all the inputs through the butterfly
    # Butterfly has an implied input and output register
    for test in test_inputs:
        if options.binary:
            r_mcand  = fp16_to_binary(test[r_idx])
            i_mcand  = fp16_to_binary(test[i_idx])
            r_mplier = fp16_to_binary(test[r_idx + 2])
            i_mplier = fp16_to_binary(test[i_idx + 2])
            r_result = fp16_to_binary(outputs[r_idx])
            i_result = fp16_to_binary(outputs[i_idx])
            print('{0} {1} {2} {3}'.format(r_mcand, i_mcand, r_mplier, i_mplier)
                + ' | '
                + '{0} {1}'.format(r_result, i_result))

        else:
            print('{0:16.8f} {1:16.8f} {2:16.8f} {3:16.8f}'.format(test[r_idx], test[i_idx], test[r_idx+2], test[i_idx+2])
                + '        | '
                + '{0:16.8f} {1:16.8f}'.format(outputs[r_idx], outputs[i_idx]))
        outputs = reg3
        reg3 = reg2
        reg2 = complex_mult(reg1)
        reg1 = inputs
        inputs = test




parser = argparse.ArgumentParser(
                    prog='butterfly_gb.py',
                    description='generates the goldenbrick for the butterfly unit',
                    epilog='teehee')

# parser.add_argument('output_file')                      # positional arg for the output file
parser.add_argument('-n', '--num_inputs', default=8)     # the number of butterflies to do
parser.add_argument('-s', '--seed', default=42)           # rng seed
parser.add_argument('-v', '--verbose',                    # verbose output or not
                    action='store_true')
parser.add_argument('-b', '--binary',                     # output in binary
                    action='store_true')
parser.add_argument('-u', '--upper', default=10.0)        # the upper bound of inputs
parser.add_argument('-l', '--lower', default=-10.0)       # the lower bound of inputs


options = parser.parse_args()

main(options)