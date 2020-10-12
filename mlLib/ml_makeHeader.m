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