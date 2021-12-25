% "wm_readAnalogFiles"  reads the data recorded through multiple analog channels
% of eCube box with timestamp. This function is capable of extracting data
% from multiple files containing data recorded from  a continous session. 

% REQUIRED INPUTS
% ---------------
% ecubeAnalogFiles      - Filenames with extention stored as cell format. 
% ecubeFolderFullpath   - File stored path
%
% Optional Input
% expectedFileDuration  - During multiple files per recording, length each chunk of file in seconds (Typical 10 min or 600s).  
%
% OUTPUT
% ------
% analogData           - Matrix with concatenated Analog Data, nsample x nchannel
% digitalDataTimestamp - Analog time stamp represented by a 1000 Mhz
%                        clock. There will be one digital stamp per recored file.  
% 
% Credits: Georgin, Thomas, Arun
% Change Log: 
%   01-Sep-2021 (Georgin)         - First version
%   19-Oct-2021 (Georgin, Thomas) - Corrected the time stamp resolution, 
%                                   added the functionality to check the 
%                                   correctness of the recorded files based on time stamp.

function [analogData, analogDataTimestamp] = wm_readAnalogFiles(ecubeAnalogFiles,ecubeFolderFullpath,expectedFileDuration)
% defining the optional variable
if(~exist('expectedFileDuration','var'))
    % DEFINE standard ecube file duration
    expectedFileDuration = 10*60; % 10 minutes
end

% EXTRACT number of channels from filenames
tempFileParts = strsplit(ecubeAnalogFiles{1}, {'int16_' '_' '-'});
nChannels     = str2double(tempFileParts{2});


% READ ANALOG data 
ecubeAnalogVoltsPerBit = 3.0517578125e-4;
analogData             = []; 
analogDataTimestamp    = [];

for fileName = ecubeAnalogFiles'
    fid = fopen(fullfile(ecubeFolderFullpath,fileName{1}), 'r');
    
    % READ eCube 1000MHz (1 nano second resolution) timestamp
    % from start of every file and append to digitalDataTimestamp
    tA                  = fread(fid, 1, 'uint64=>uint64'); 
    analogDataTimestamp = cat(1, analogDataTimestamp, tA);
    
    % READ analog data from file and append to analogData
    dA         = fread(fid, [nChannels,inf], 'int16=>single');
    analogData = cat(2, analogData, dA*ecubeAnalogVoltsPerBit);
    fclose(fid);
end
analogData = analogData';

% CHECK if the ecube analog files are sequential and of 10min each (precision = 1s)
delayBetweenEcubeAnalogFiles = diff(double(analogDataTimestamp))*(10^-9); % in seconds
if sum(round(delayBetweenEcubeAnalogFiles,1) ~= expectedFileDuration) > 0
    error('ecube analogl file timestamps indicate missing data of atleast 1s')
end 

% SUCCESS message
disp('SUCCESS! Ecube analog data extracted. Continuing.')
end