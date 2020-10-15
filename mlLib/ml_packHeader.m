function files = ml_packHeader(allowedFileTypes,mlLibFolderName)
% Pack the dependent fiels in the current folder and specified mlLib folder
% OPTIONAL INPUTS
% allowedFileTypes: Cell array of allowed file types. Eg.{'*.m','*.mat','*.txt'}
% mlLibFolderName : String specifying the folder name of monkey-logic lib which is
%                   added to the current path 

if(~exist('mlLibFolderName'))      
    mlLibFolderName=['mlLib'];
end
if(~exist('allowedFileTypes'))
    allowedFileTypes={'*.m','*.mat','*.txt'};
end

%% From current path find the mlLib path 
current_path=path; % Current Matlab Path 
current_path=strsplit(current_path,';');
libFlag=0; % Flag to detect correct lib path
for i=1:size(current_path,2)
    index=strfind(current_path{i},mlLibFolderName);
    if (~isempty(index))
        lib_path=current_path{i};
        libFlag=1;
        break;
    end
end

%% Extract the file names and contents from the current folder
files.fileNames    = {};
files.fileDates    = {}; 
files.fileContents = {};

for fileType = 1:length(allowedFileTypes)
    allFiles = dir(allowedFileTypes{fileType});
    for fileID = 1:length(allFiles)
        fileName = allFiles(fileID).name;
        filedate = allFiles(fileID).date; 
        files.fileNames     = [files.fileNames; fileName];
        files.fileDates     = [files.fileDates; filedate]; 
        files.fileContents  = [files.fileContents; ml_getFileContents(fileName)];
    end
end

%% Fetching the file name and content from the mlLib folder
if (libFlag==1)
    for fileType = 1:length(allowedFileTypes)
        allFiles = dir([lib_path,'\',allowedFileTypes{fileType}]);
        
        for fileID = 1:length(allFiles)
            fileName = allFiles(fileID).name;

            files.fileNames     = [files.fileNames; fileName];
            files.fileContents  = [files.fileContents; ml_getFileContents(fileName)];
        end
    end
end
end
