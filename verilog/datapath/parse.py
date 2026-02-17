import numpy as np
import re
import sys

def hex_to_fp16(hex_16):
    """Converts a 4-digit hex string to a numpy float16 value."""
    try:
        bits = np.uint16(int(hex_16, 16))
        return bits.view(np.float16)
    except ValueError:
        return np.nan

def parse_line_to_complex(hex_str):
    """
    Takes a string of hex and breaks it into 32-bit complex chunks.
    Assumes [Imag(16) | Real(16)]
    """
    # Remove whitespace and '0x'
    clean = hex_str.replace(" ", "").replace("0x", "")
    
    # Split into 32-bit (8 hex char) chunks
    chunks = [clean[i:i+8] for i in range(0, len(clean), 8)]
    
    results = []
    for chunk in chunks:
        if len(chunk) == 8:
            imag = hex_to_fp16(chunk[0:4])
            real = hex_to_fp16(chunk[4:8])
            results.append(complex(real, imag))
    return results

def process_log(file_path):
    # Regex to find timestamps and the hex data after "Expected" or "Got"
    # Matches strings like "Expected1: a7cf4c0e..." or "Got: a8004c0f..."
    pattern = re.compile(r"(Expected\d*|Got):\s*([0-9a-fA-F\s]+)")
    
    try:
        with open(file_path, 'r') as f:
            for line in f:
                if "Time" in line:
                    time_match = re.search(r"Time\s+([\d\.]+)\s*ns", line)
                    timestamp = time_match.group(1) if time_match else "Unknown"
                    
                    print(f"\n{'='*60}")
                    print(f" TIME: {timestamp} ns")
                    print(f"{'='*60}")
                    
                    matches = pattern.findall(line)
                    for label, hex_data in matches:
                        complex_nums = parse_line_to_complex(hex_data)
                        print(f"\n  {label}:")
                        for i, c in enumerate(complex_nums):
                            print(f"    Slot {i}: {c.real:>8.4f} + {c.imag:>8.4f}j")
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python log_parser.py <your_log_file.txt>")
    else:
        process_log(sys.argv[1])