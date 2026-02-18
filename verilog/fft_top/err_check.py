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

def parse_chunk_to_complex(chunk):
    imag = hex_to_fp16(chunk[0:4])
    real = hex_to_fp16(chunk[4:8])
    return real, imag

def process_log(file_path):
    point_pattern = re.compile(r"point_config:\s(\d+)")
    pass_pattern = re.compile(r"(\[\s*\d*\..*\sns\])\s\[PASS\]")
    fail_addr_pattern = re.compile(r"(\[\s*\d*\..*\sns\])\s\[FAIL\].*Address Mismatch")
    fail_data_pattern = re.compile(r"(\[\s*\d*\..*\sns\])\s\[FAIL\].*Data\sMismatch.*Expected:\s(\S{8})\s(\S{8})\s(\S{8})\s(\S{8}).*Got:\s(\S{8})\s(\S{8})\s(\S{8})\s(\S{8})")

    # Storage to keep track of expected values to compare against "Got"
    pass_count = 0
    pass_timestamps = []
    addr_err_count = 0
    data_err_count_round = 0
    data_err_count_real = 0

    max_error = 0.1
    point_configuration = 0
    num_points = 0
    largest_deltas = []
    print(f"ROUNDING MAX DELTA: {max_error}")
    with open(file_path, 'r') as f:
        for line in f:
            point_match = point_pattern.findall(line)
            pass_match = pass_pattern.findall(line)
            fail_addr_match = fail_addr_pattern.findall(line)
            fail_data_match = fail_data_pattern.findall(line)

            if point_match:
                for point_config in point_match:
                    point_configuration =int(point_config)
                    num_points = 2**(3 + point_configuration)
            elif pass_match:
                pass_count += 1
            elif fail_addr_match:
                addr_err_count += 1
                for timestamp in fail_addr_match:
                    print(f"Addr Mismatch at {timestamp}")
            elif fail_data_match:
                deltas = []
                for timestamp, exp1, exp2, exp3, exp4, got1, got2, got3, got4 in fail_data_match:
                    real_exp1, imag_exp1 = parse_chunk_to_complex(exp1)
                    real_exp2, imag_exp2 = parse_chunk_to_complex(exp2)
                    real_exp3, imag_exp3 = parse_chunk_to_complex(exp3)
                    real_exp4, imag_exp4 = parse_chunk_to_complex(exp4) 
                    real_got1, imag_got1 = parse_chunk_to_complex(got1)
                    real_got2, imag_got2 = parse_chunk_to_complex(got2)
                    real_got3, imag_got3 = parse_chunk_to_complex(got3)
                    real_got4, imag_got4 = parse_chunk_to_complex(got4) 
                    deltas.append(abs(real_exp1 - real_got1))
                    deltas.append(abs(real_exp2 - real_got2))
                    deltas.append(abs(real_exp3 - real_got3))
                    deltas.append(abs(real_exp4 - real_got4)) 
                    deltas.append(abs(imag_exp1 - imag_got1))
                    deltas.append(abs(imag_exp2 - imag_got2))
                    deltas.append(abs(imag_exp3 - imag_got3))
                    deltas.append(abs(imag_exp4 - imag_got4)) 
                    err = 0
                    largest_delta = 0
                    for delta in deltas:
                        if(delta > max_error):
                            largest_delta = max(delta, largest_delta)
                            err += 1
                    largest_deltas.append(largest_delta)
                    if(err == 0):
                        data_err_count_round += 1
                    else:
                        print(f"Delta Mismatch at {timestamp} largest delta: {largest_delta}")
                        print(f"Expected: {real_exp1}+{imag_exp1}j {real_exp2}+{imag_exp2}j  {real_exp3}+{imag_exp3}j {real_exp4}+{imag_exp4}j")
                        print(f"Got:      {real_got1}+{imag_got1}j {real_got2}+{imag_got2}j  {real_got3}+{imag_got3}j {real_got4}+{imag_got4}j")
                        data_err_count_real += 1
            
    print(f"Passes: {pass_count}")
    print(f"Address Errors: {addr_err_count}")
    print(f"Data Errors due to rounding: {data_err_count_round}")
    print(f"Data Errors that are real: {data_err_count_real}")
    print(f"Largest Delta {max(largest_deltas)}")
    num_writes = pass_count + addr_err_count + data_err_count_real + data_err_count_round
    num_stages = 3 + point_configuration
    print(f"Number of points: {num_points}")
    print(f"Number of stages: {num_stages}")
    print(f"Num writes expected {num_points//4 * (num_stages-1)}")
    print(f"Num writes done {num_writes}")
    print(f"Num writes done per port {num_writes//2}")
    print(f"Num data points processed {num_writes*4}")

    
                

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python err_check.py <log_file>")
    else:
        process_log(sys.argv[1])