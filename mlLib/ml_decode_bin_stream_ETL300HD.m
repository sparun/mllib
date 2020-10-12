% -------------------------------------------------------------------
% This function decodes the binary stream of data received from ISCAN
% It returns the parameters and a count of the samples received.
% -------------------------------------------------------------------
% [param_table, params] = decode_bin_stream_ETL300HD(data_stream)
% REQUIRED INPUTS
%  data_stream = ISCAN data stream
% OPTIONAL INPUTS
%  None
% OUTPUTS
%  param_table = decoded parameters
%  params      = number of parameters
% METHOD
%     
% NOTES
% 
% EXAMPLE
%  psy_decode_bin_stream(d_stream);
%  will decode the parameter values in d_stream
% REQUIRED SUBROUTINES
%  None
%
% Zhivago KA
% 07 Dec 2010

function [param_table, params] = decode_bin_stream_ETL300HD(data_stream)
global iscan;
ss = iscan.sample_size;

try
    % Discarding any incomplete sample at the beginning of the stream
    head_index = find(data_stream == 68, 3, 'first');
    diff_head = diff(head_index);
    if (diff_head(1) == diff_head(2) == 1) || ((diff_head(1) == 1) && (diff_head(2) ~= 1))
        head_index(3) = [];
    elseif (diff_head(1) ~= 1) && (diff_head(2) == 1)
        head_index(1) = [];
    end
    if ~isempty(head_index) && (head_index(end) ~= ss)
        data_stream(1:head_index(end)) = [];
    end

    % Discarding any incomplete sample at the end of the stream
    tail_index = find(data_stream == 68, 3, 'last');
    if (tail_index(2) - tail_index(1) == 1)
        tail_index(3) = [];
    else
        tail_index(1) = [];
    end
    if ~isempty(tail_index) && (tail_index(end) ~= length(data_stream) - 4)
        data_stream(tail_index(1):end) = [];
    end

    data_stream(end+1) = 68;
    data_stream(end+1) = 68;
    [~,bytes] = size(data_stream);
    bytes = floor(bytes/ss) * ss;
    params = 0;
    param_table = zeros(0,0);
    nparams = iscan.max_params;

    % Decoding the data stream, one sample at a time
    for byte = 1:ss:bytes
        params = params + 1;
        % decoding each parameter
        for p = 1:nparams
            bindx = byte+ (p-1)*2;
            param_table(params, p) = (data_stream(bindx) + (256 * data_stream(bindx+1)))/10;

        end
    end    
catch me
    param_table=[];
    params=[];
end