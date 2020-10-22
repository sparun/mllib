% ml_packHeader.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Unpacks the dependent files (either from TrialRecord or after decoding from eCube file)
% for ML template experiments into 'unpackedFiles'
% 
% VERSION HISTORY
% - 15-Oct-2020  - Georgin - First implementation
%-----------------------------------------------------------------------------------------

function ml_unpackHeader(files)
fileNames = files.fileNames;
contents  = files.fileContents;

if ~exist('unpackedFiles', 'dir')
    mkdir('unpackedFiles')
end

unpackDirName = './unpackedFiles/';

for ind = 1:length(fileNames)
    filePointer = fopen([unpackDirName fileNames{ind}], 'w');
    fwrite(filePointer, contents{ind});
    fclose(filePointer);
end
end