function value = wm_extractDigitalBits(data, bitPosition)
% This function extracts single bits from 64 bit representations.

% INPUTS
% data        =  (nSamples x 1) Vector of integers between 0 and 2^64-1. Each integer represents a 64 bit number.  
% bitPosition = Scalar value indicating the position of bit to be extracted.
%
% OUTPUT
% value       =  (nSamples x 1) vector indicating the value of the bit in the requested position. Values of this vector will be 0 or 1.    
%
% Credits
% 1-Sep-2021: Georgin - First Version

if(bitPosition > 1)
    data = bitshift(data, -(bitPosition-1)); % Ignoring the the first two bit
end

value = bitand(data,1);% Selecting the first bit
value = double(value);
end