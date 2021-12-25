% "wm_readDigitalFiles"  reads the data recorded through digital channels
% of eCube box with timestamp. This function is capable of extracting data
% from multiple files containing data recorded from  a continous session. 

% REQUIRED INPUTS
% ---------------
% ecubeDigitalFiles     - Filenames with extention stored as cell format. 
% ecubeFolderFullpath   - File stored path
%
% Optional Input
% expectedFileDuration  - During multiple files per recording, length each chunk of file in seconds (Typical 10 min or 600s).  
%
% OUTPUT
% ------
% digitalData          - Concatenated digital data
% digitalDataTimestamp - Digital time stamp represented by a 1000 Mhz
%                        clock. There will be one digital stamp per recored file.  
% 
% Credits: Georgin, Thomas, Arun
% Change Log: 
%   01-Sep-2021 (Georgin)         - First version
%   19-Oct-2021 (Georgin, Thomas) - Corrected the time stamp resolution, 
%                                   added the functionality to check the 
%                                   correctness of the recorded files based on time stamp.

function [digitalData, digitalDataTimestamp] = wm_readDigitalFiles(ecubeDigitalFiles,ecubeFolderFullpath,expectedFileDuration)

% defining the optional variable
if(~exist('expectedFileDuration','var'))
    % DEFINE standard ecube file duration
    expectedFileDuration = 10*60; % 10 minutes
end

digitalData          = []; 
digitalDataTimestamp = [];

for fileName = ecubeDigitalFiles'
    fid = fopen(fullfile(ecubeFolderFullpath,fileName{1}), 'r');
    
    % READ eCube 1000MHz (1 nano second resolution) timestamp
    % from start of every file and append to digitalDataTimestamp
    tD                   = fread(fid,1,'uint64=>uint64'); 
    digitalDataTimestamp = cat(1,digitalDataTimestamp,tD);
    
    % READ digital data from file and append to digitalData
    dD          = fread(fid,'uint64=>uint64');
    digitalData = cat(1,digitalData,dD);
    
    fclose(fid);
end


% CHECK if the ecube digital files are sequential and of 10min each (precision = 1s)
delayBetweenEcubeDigitalFiles = diff(double(digitalDataTimestamp))*(10^-9); % in seconds
if sum(round(delayBetweenEcubeDigitalFiles,1) ~= expectedFileDuration) > 0
    error('ecube digital file timestamps indicate missing data of atleast 1s')
end 

% SUCCESS message
disp('SUCCESS! Ecube digital data extracted. Continuing.')
end