% ml_makeHeader.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Read header files and convert to a single combined array for transmission on digital
% lines to eCube
% 
% VERSION HISTORY
% - 15-Oct-2020  - Georgin - First implementation
%-----------------------------------------------------------------------------------------

function headerStr = ml_makeHeader(files)

% SAVE the header file temporarily
save('headerFile','files'); 

% READ the header file
filePointer = fopen('headerFile.mat','r');
headerStr   = fread(filePointer,'uint16');
fclose(filePointer);

% DELETE the header file 
delete('headerFile.mat')
end