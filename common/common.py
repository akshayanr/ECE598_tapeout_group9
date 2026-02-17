import numpy as np

# thanks AI
def fp16_to_binary(input):
    return np.binary_repr(np.float16(input).view(np.uint16), width=16)

def fp16_to_hex(val):
    # Ensure the input is a numpy float16
    fp_val = np.float16(val)
    
    # View the raw bits as a 16-bit unsigned integer
    raw_bits = fp_val.view(np.uint16)
    
    # Format as a hex string with leading zeros and '0x' prefix
    return f"{raw_bits:04x}"