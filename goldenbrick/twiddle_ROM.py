import numpy as np
import argparse
import sys
import os

# Add the common script to our path so we can get some epic func's
script_dir = os.path.dirname(__file__) 
scripts_path = os.path.join(script_dir, '../common') 
sys.path.append(scripts_path) 

def generate_twiddle_rom(options):
    # Divde the number of points in half to get the number of twiddle factors
    twiddle_count = (options.num_points >> 1)

    if options.verbose:
        print("Wkn = e^-2*pi*Q/N")

    for idx in range(twiddle_count):
        Q = idx
        N = options.num_points
        prefix  = ""

        if options.verbose:
            prefix = f"Q: {Q}, N: {N} "

        # Calculate twiddle factor
        real = np.exp(-2j*np.pi*Q/N).real.astype(np.float16)
        imag = np.exp(-2j*np.pi*Q/N).imag.astype(np.float16)

        # Print
        if options.binary:
            address = "@{0:08x} ".format(idx)
            print(prefix + address + "{0:04x}{1:04x}".format(real.view(np.uint16), imag.view(np.uint16)))
        else:
            print(prefix + f"{real} {imag}")
    
def main(options):
    generate_twiddle_rom(options)

parser = argparse.ArgumentParser(
                    prog='twiddle_ROM.py',
                    description='generates the the twiddle ROM',
                    epilog='teehee')

parser.add_argument('-n', '--num_points', type=int, default=8)     # the number of butterflies to do
parser.add_argument('-v', '--verbose',                   # verbose output
                    action='store_true')
parser.add_argument('-b', '--binary',                    # output in binary
                    action='store_true')


options = parser.parse_args()

main(options)
