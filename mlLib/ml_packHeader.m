% ml_packHeader.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Pack the dependent files for ML template experiments from the current folder (timing,
% condition and configuration files) and lib functions from the specified mlLib folder
% 
% OPTIONAL INPUTS
%  allowedFileTypes: Cell array of allowed file types. Eg.{'*.m','*.mat','*.txt'}
%  mlLibFolderName : String specifying the folder name of monkey-logic lib which is
%                    added to the current path
% 
% VERSION HISTORY
% - 15-Oct-2020  - Georgin - First implementation
%-----------------------------------------------------------------------------------------

function files = ml_packHeader(allowedFileTypes,mlLibFolderName)
if(~exist('mlLibFolderName','var')),  mlLibFolderName  = 'mlLib'; end
if(~exist('allowedFileTypes','var')), allowedFileTypes = {'*.m','*.mat','*.txt'}; end

% From current path find the mlLib path
currentPath = path; % Current Matlab Path
currentPath = strsplit(currentPath,';');
libFlag     = 0; % Flag to detect correct lib path

for i = 1:size(currentPath, 2)
    index = strfind(currentPath{i}, mlLibFolderName);
    if (~isempty(index))
        libPath = currentPath{i};
        libFlag = 1;
        break;
    end
end

% Extract the file names and contents from the current folder
files.fileNames    = {};
files.fileDates    = {};
files.fileContents = {};

for fileType = 1:length(allowedFileTypes)
    allFiles = dir(allowedFileTypes{fileType});
    for fileID = 1:length(allFiles)
        fileName            = allFiles(fileID).name;
        filedate            = allFiles(fileID).date;
        files.fileNames     = [files.fileNames;    fileName];
        files.fileDates     = [files.fileDates;    filedate];
        files.fileContents  = [files.fileContents; ml_getFileContents(fileName)];
    end
end

% Fetching the file name and content from the mlLib folder
if (libFlag == 1)
    for fileType = 1:length(allowedFileTypes)
        allFiles = dir([libPath '\' allowedFileTypes{fileType}]);
        
        for fileID = 1:length(allFiles)
            fileName            = allFiles(fileID).name;
            files.fileNames     = [files.fileNames; fileName];
            files.fileContents  = [files.fileContents; ml_getFileContents(fileName)];
        end
    end
end
end
