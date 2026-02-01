import numpy as np

def fp16_to_binary(input):
    return np.binary_repr(np.float16(input).view(np.int16), width=16)