% This function converts the header content send as uint16 to doubles saved with matlab. 
% This does this indirectly by creating a temporary file with uint16 and
% reading it back as double
%
% INPUTS 
% headerContent : header content in uint16 format
%
% OUTPUT
% Files    : Decoded matlab data format
%
% Credits
% 1 Sep 2019, Georgin  Initial Version
function files=wm_headerUint16Double(header_content)
filePointer = fopen('temp_header_file_created.mat', 'w');
fwrite(filePointer, header_content,'uint16');
fclose(filePointer);
files=load('temp_header_file_created.mat');
delete('temp_header_file_created.mat')
files=files.files;
end
