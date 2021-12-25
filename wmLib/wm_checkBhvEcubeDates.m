% Check if bhvFile,eCube wired files and eCube wireless files were recorded
% on the same day or not. This function return error if the dates are not
% matching 
%
% INPUTS:
% ******
% bhvFile           : ML file name in the format <experimentname>_<date>_<time>.bhv2
% eCubeAnalogFiles  : All analog file names, cell(n,1). Each cell contains file with names must be formatted as "AnalogPanel_<number of channel>_Channels_int16_<date as year-month-day>_<time as hr-min-sec>.bin
% ecubeDigitalFiles : All digital file names, cell(n,1).  Each cell contains files with names formatted as "DigitalPanel_<recorded bits>_Channels_bool_masked_uint64_<date as year-month-day>_<time as hr-min-sec>.bin" 
% wirelessFile      : Wireless file name in the format HSW_<date as year_month_day>__<time as hr_min_sec>__<duration as XXmin_XXsec>__hsamp_<channels recorded>ch_<sampling freq.>sps.bin
% flagWirelessData  : Expecting 1 if the wireless data is recorded.

% OUTPUT:
% experimentDate    : Date on running the experiment in year,month,day format.
%
% - 20 - Oct 2021 - Georgin and Thomas
function experimentDate = wm_checkBhvEcubeDates(bhvFile, ecubeAnalogFiles, ecubeDigitalFiles,wirelessFile,flagWirelessData)
bhvFileParts = strsplit(bhvFile, '_');
bhvFileDate  = str2double(bhvFileParts{3});

for i = 1:length(ecubeAnalogFiles)
    tempFileParts = strsplit(ecubeAnalogFiles{i}, {'int16_' '_' '-'});
    ecubeAnalogFileDate = str2double([tempFileParts{4:6}]);
    if ecubeAnalogFileDate ~= bhvFileDate
        error('FAILURE! BHV and ecube file dates MISMATCH! Please check and retry')
    end
    
    tempFileParts = strsplit(ecubeDigitalFiles{i}, {'uint64_' '_' '-'});
    ecubeDigitalFileDate = str2double([tempFileParts{6:8}]);
    if ecubeDigitalFileDate ~= bhvFileDate
        error('FAILURE! BHV and ecube file dates MISMATCH! Please check and retry')
    end
end
if(flagWirelessData==1)
    tempFileParts    = strsplit(wirelessFile, {'int16_' '_' '-'});
    wirelessFileDate = str2double([tempFileParts{2:4}]);
    if (wirelessFileDate ~=bhvFileDate)
        error('FAILURE! BHV and wireless file dates MISMATCH! Please check and retry');
    end
end
% SUCCESS message
disp('SUCCESS! BHV,ecube, wireless files dates match.')
experimentDate = bhvFileDate;
end