% GET FILE CONTENTS - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Reads a file and returns the info
%
% INPUT
%   fileName     - file name to be deciphered
%
% OUTPUT
%   fileContents - values of the entries in the file
%
% VERSION HISTORY
%   15-Oct-2020 - Thomas  - Initial implementation
%                 Georgin  
% ----------------------------------------------------------------------------------------

function  fileContents = ml_getFileContents(fileName)
% OPEN the file
filePointer   = fopen(fileName, 'r');

% READ file contents
fileContents  = fread(filePointer);

% CLOSE opened file
fclose(filePointer);
end
