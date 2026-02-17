import numpy as np
import re
import sys

# thanks gemini
def hex_to_fp16(hex_16):
    try:
        bits = np.uint16(int(hex_16, 16))
        return bits.view(np.float16)
    except:
        return np.nan

def parse_line_to_complex(hex_str):
    clean = hex_str.replace(" ", "").replace("0x", "")
    chunks = [clean[i:i+8] for i in range(0, len(clean), 8)]
    results = []
    for chunk in chunks:
        if len(chunk) == 8:
            imag = hex_to_fp16(chunk[0:4])
            real = hex_to_fp16(chunk[4:8])
            results.append(complex(real, imag))
    return results

def process_log(file_path):
    pattern = re.compile(r"(Expected\d*|Got):\s*([0-9a-fA-F\s]+)")
    # Storage to keep track of expected values to compare against "Got"
    expected_store = {} 

    try:
        with open(file_path, 'r') as f:
            for line in f:
                time_match = re.search(r"Time\s+([\d\.]+)\s*ns", line)
                if not time_match: continue
                
                timestamp = time_match.group(1)
                matches = pattern.findall(line)
                
                for label, hex_data in matches:
                    complex_nums = parse_line_to_complex(hex_data)
                    
                    if "Expected" in label:
                        # Store expected values for this time and bus (Expected1 or Expected2)
                        expected_store[(timestamp, label)] = complex_nums
                        print(f"\n[{timestamp}ns] Parsed {label}")
                    
                    elif "Got" in label:
                        # Determine which Expected bus to compare against 
                        # (Usually the log prints Exp1 then Got, then Exp2 then Got)
                        # We look for the most recent Expected entry that hasn't been "consumed"
                        exp_label = "Expected1" if "Expected1" in line or "115.00" in timestamp else "Expected2"
                        # Fallback logic: check if this follows an Expected1 or Expected2 print
                        
                        print(f"\n[{timestamp}ns] --- Comparison for {label} ---")
                        print(f"{'Slot':<8} | {'Got Value':<25} | {'Delta (Real)':<12} | {'Delta (Imag)':<12} | {'Status'}")
                        print("-" * 85)

                        # Match with Expected1 or Expected2 based on context
                        # Note: You may need to adjust the logic below if your log format 
                        # pairs Got lines differently
                        target_exp = expected_store.get((timestamp, "Expected1")) if "Expected1" in line else expected_store.get((timestamp, "Expected2"))
                        
                        if not target_exp:
                            # Try simple fallback if explicit label not in line
                            target_exp = expected_store.get((timestamp, "Expected1"))

                        if target_exp:
                            for i, got_val in enumerate(complex_nums):
                                if i < len(target_exp):
                                    exp_val = target_exp[i]
                                    d_real = abs(got_val.real - exp_val.real)
                                    d_imag = abs(got_val.imag - exp_val.imag)
                                    
                                    # Threshold for rounding error (FP16 has ~3 decimal digits of precision)
                                    # Anything larger than 0.01 is likely a logic/shuffling issue
                                    status = "OK"
                                    if d_real > 0.1 or d_imag > 0.1:
                                        status = "!! SHUFFLE/LOGIC !!"
                                    elif d_real > 0 or d_imag > 0:
                                        status = "Rounding Error"
                                    
                                    print(f"Slot {i:<3} | {str(got_val):<25} | {d_real:<12.6f} | {d_imag:<12.6f} | {status}")
                        else:
                            print("    (No matching Expected data found in log for this Got line)")

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python log_parser.py <log_file>")
    else:
        process_log(sys.argv[1])