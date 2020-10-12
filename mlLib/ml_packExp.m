function  TrialRecord = ml_packExp(TrialRecord)

%allowedFileTypes = {'*.bmp' '*.m' '*.wav' '*.mat' '*.txt'};
allowedFileTypes = {'*.m' '*.mat' '*.txt'};

for fileType = 1:length(allowedFileTypes)
    files = dir(allowedFileTypes{fileType});
    
    for fileID = 1:length(files)
        fileName = files(fileID).name;       
        TrialRecord.User.specs.files.fileNames     = [TrialRecord.User.specs.files.fileNames; fileName];
        TrialRecord.User.specs.files.fileContents  = [TrialRecord.User.specs.files.fileContents; getFileContents(fileName)];
    end        
end
end
