import numpy as np

# thanks AI
def fp16_to_binary(input):
    return np.binary_repr(np.float16(input).view(np.uint16), width=16)