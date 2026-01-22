%Input is in Q8.8 fixed point and so will output.
function [X_out, Y_out] = ...
    cordic_model(Z_in, X_in, Y_in)
    
    %This is our arctan lut. Shifting will result in loss of
    %precision/freeze 
    %beyond shift of 8, if we continue to use 16 bits, so we increase the
    %intermediate operations to be Q8.24. also in Q8.8, the smallest
    %possible is 0.00039 which is not small enough for rotations at
    %iteration 15, 16, etc.

    atan_val = int32([ ...
        13176795;  % i=0:  atan(2^-0)  = 45.000 deg = 0.7854 rad
         7778660;  % i=1:  atan(2^-1)  = 26.565 deg = 0.4636 rad
         4109848;  % i=2:  atan(2^-2)  = 14.036 deg = 0.2450 rad
         2086331;  % i=3:  atan(2^-3)  =  7.125 deg = 0.1244 rad
         1047214;  % i=4:  atan(2^-4)  =  3.576 deg = 0.0624 rad
          524046;  % i=5:  atan(2^-5)  =  1.790 deg = 0.0312 rad
          262097;  % i=6:  atan(2^-6)  =  0.895 deg = 0.0156 rad
          131061;  % i=7:  atan(2^-7)  =  0.448 deg = 0.0078 rad
           65533;  % i=8:  atan(2^-8)  =  0.224 deg = 0.0039 rad
           32767;  % i=9:  atan(2^-9)  =  0.112 deg
           16384;  % i=10: atan(2^-10) =  0.056 deg
            8192;  % i=11: atan(2^-11)
            4096;  % i=12: atan(2^-12)
            2048;  % i=13: atan(2^-13)
            1024;  % i=14: atan(2^-14)
             512;  % i=15: atan(2^-15)
             256;  % i=16: atan(2^-16)
    ]);


    % Cast 16 bit (8,8) inputs to 32-bit integers to prevent overflow during calc
    % This would result in Q8.24.
    
    X = bitshift(int32(X_in), 16);
    Y = bitshift(int32(Y_in), 16);
    Z = bitshift(int32(Z_in), 16);
   

    %the rotations.
    for i = 0:15
        % Shifters (Arithmetic Right Shift)
        % Verilog: x_shift = X[i] >>> i;
        x_shift = bitshift(X, -i); 
        y_shift = bitshift(Y, -i);
        
        current_atan = atan_val(i + 1); % MATLAB is 1-indexed
        
        X_old = X;
        Y_old = Y;
        Z_old = Z;
        
        %rotation direction.
        if (Z >= 0)
             X = X_old - y_shift;
             Y = Y_old + x_shift;
             Z = Z_old - current_atan; 
        else
            X = X_old + y_shift;
            Y = Y_old - x_shift;
            Z = Z_old + current_atan;
        end
    end

    %Scaling by 0.6072529.
    % Factor 0.5 (>>1)
    X = bitshift(X, -1);
    Y = bitshift(Y, -1);
    
    % Factor (1 + 2^-3)
    X = X + bitshift(X, -3);
    Y = Y + bitshift(Y, -3);
    
    % Factor (1 + 2^-4)
    X = X + bitshift(X, -4);
    Y = Y + bitshift(Y, -4);
    
    % Factor (1 + 2^-6)
    X = X + bitshift(X, -6);
    Y = Y + bitshift(Y, -6);
    
    % Factor (1 + 2^-9)
    X = X + bitshift(X, -9);
    Y = Y + bitshift(Y, -9);
    
    % Factor (1 - 2^-10) -- SUBTRACT
    X = X - bitshift(X, -10);
    Y = Y - bitshift(Y, -10);
    
    % Factor (1 - 2^-11) -- SUBTRACT
    X = X - bitshift(X, -11);
    Y = Y - bitshift(Y, -11);
    
    % Factor (1 - 2^-14) -- SUBTRACT
    X = X - bitshift(X, -14);
    Y = Y - bitshift(Y, -14);
    
   
    %returning back to 8Q8.
    X_out  = double(bitshift(X_mult, -24));
    
    Y_out  = double(bitshift(Y_mult, -24));
   
end