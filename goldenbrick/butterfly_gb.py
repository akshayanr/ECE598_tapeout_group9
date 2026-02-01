import numpy as np
import argparse
import sys
import os

# Add the common script to our path so we can get some epic func's
script_dir = os.path.dirname(__file__) 
scripts_path = os.path.join(script_dir, '../common') 
sys.path.append(scripts_path) 

from common import fp16_to_binary

r_a_idx = 0
i_a_idx = 1
r_b_idx = 2
i_b_idx = 3

def calc_butterfly (inputs):
    outputs = np.zeros(4)
    outputs[r_a_idx] = inputs[r_a_idx] + inputs[r_b_idx]
    outputs[i_a_idx] = inputs[i_a_idx] + inputs[i_b_idx]
    outputs[r_b_idx] = inputs[r_a_idx] - inputs[r_b_idx]
    outputs[i_b_idx] = inputs[i_a_idx] - inputs[i_b_idx]

    return outputs

def main(options):
    # Generate random inputs 

    arr_dim = (options.num_inputs, 4)
    rng = np.random.default_rng(options.seed)
    test_inputs =  rng.uniform(options.lower, options.upper, arr_dim).astype(np.float16)

    if options.verbose:
        print(options)
        print(test_inputs)

    inputs  = np.zeros(4) # input latch reg
    reg1    = np.zeros(4) # input reg
    reg2    = np.zeros(4) # output reg
    outputs = np.zeros(4) # output latch reg

    if(options.verbose):
        print("IN:   real_a   imag_a   real_b   imag_b   |   OUT:   real_a   imag_a   real_b   imag_b")

    # Run all the inputs through the butterfly
    # Butterfly has an implied input and output register
    for test in test_inputs:
        if options.binary:
            in_tmp1  = fp16_to_binary(test[r_a_idx])
            in_tmp2  = fp16_to_binary(test[i_a_idx])
            in_tmp3  = fp16_to_binary(test[r_b_idx])
            in_tmp4  = fp16_to_binary(test[i_b_idx])
            out_tmp1 = fp16_to_binary(outputs[r_a_idx])
            out_tmp2 = fp16_to_binary(outputs[i_a_idx])
            out_tmp3 = fp16_to_binary(outputs[r_b_idx])
            out_tmp4 = fp16_to_binary(outputs[i_b_idx])
            print('{0} {1} {2} {3}'.format(in_tmp1, in_tmp2, in_tmp3, in_tmp4)
                + ' | '
                + '{0} {1} {2} {3}'.format(out_tmp1, out_tmp2, out_tmp3, out_tmp4))

        else:
            print('{0:16.8f} {1:16.8f} {2:16.8f} {3:16.8f}'.format(test[r_a_idx], test[i_a_idx], test[r_b_idx], test[i_b_idx])
                + '        | '
                + '{0:16.8f} {1:16.8f} {2:16.8f} {3:16.8f}'.format(outputs[r_a_idx], outputs[i_a_idx], outputs[r_b_idx], outputs[i_b_idx]))
        outputs = reg2
        reg2 = calc_butterfly(reg1)
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