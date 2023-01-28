% UNPACK HEADER - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Unpacks the dependent files (either from TrialRecord or after decoding from eCube file)
% for ML template experiments into 'unpackedFiles'
% 
% VERSION HISTORY
%   15-Oct-2020 - Georgin - First implementation
%-----------------------------------------------------------------------------------------

function ml_unpackHeader(files)
% GET file names and file contents
fileNames = files.fileNames;
contents  = files.fileContents;

% CHECK if directory for unpack exists else create
if ~exist('unpackedFiles', 'dir')
    mkdir('unpackedFiles')
end

unpackDirName = './unpackedFiles/';

% UNPACK header
for ind = 1:length(fileNames)
    % OPEN file contents
    filePointer = fopen([unpackDirName fileNames{ind}], 'w');
    
    % WRITE the file to the folder
    fwrite(filePointer, contents{ind});
    
    % CLOSE file
    fclose(filePointer);
end
end