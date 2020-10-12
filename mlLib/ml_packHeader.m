function files = ml_packHeader(allowedFileTypes)

files.fileNames    = {};
files.fileContents = {};

for fileType = 1:length(allowedFileTypes)
    allFiles = dir(allowedFileTypes{fileType});
    
    for fileID = 1:length(allFiles)
        fileName = allFiles(fileID).name;
        files.fileNames     = [files.fileNames; fileName];
        files.fileContents  = [files.fileContents; getFileContents(fileName)];
    end
end
end