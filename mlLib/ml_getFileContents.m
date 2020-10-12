function  fileContents = ml_getFileContents(filename)

filePointer   = fopen(filename, 'r');
fileContents  = fread(filePointer);
fclose(filePointer);

end
