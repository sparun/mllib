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