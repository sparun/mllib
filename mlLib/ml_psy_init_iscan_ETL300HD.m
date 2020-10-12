% -------------------------------------------------------------------
% This function initializes ISCAN and serial port
% -------------------------------------------------------------------
% psy_init_iscan()
% REQUIRED INPUTS
%  None
% OPTIONAL INPUTS
%  None
% OUTPUTS
%  None
% METHOD
%     
% NOTES
% 
% EXAMPLE
%  psy_init_iscan();
%  will initialize ISCAN and serial port
% REQUIRED SUBROUTINES
%  None
%
% Zhivago KA
% 07 Dec 2010

function iscan = psy_init_iscan_ETL300HD()

serport_str = struct(...
'com_port', [],...
'baud_rate', [],...
'terminator', [],...
'sndrcv_timeout', [],...
'poll_latency', [],...
'bytes_to_read', [],...
'max_bkgrnd_read_time', [],...
'input_buffer_size', [],...
'spl_settings', []);
% ----------------------------------------------------------------------------------
n=0; 
n=n+1; serport_str.fields{n,1} = 'com_port             = comport name';
n=n+1; serport_str.fields{n,1} = 'baud_rate            = baud rate';
n=n+1; serport_str.fields{n,1} = 'terminator           = delimiter';
n=n+1; serport_str.fields{n,1} = 'sndrcv_timeout       = timeout for send/receive operations';
n=n+1; serport_str.fields{n,1} = 'poll_latency         = poll period for background read';
n=n+1; serport_str.fields{n,1} = 'bytes_to_read        = bytes to read during each background read';
n=n+1; serport_str.fields{n,1} = 'max_bkgrnd_read_time = maximum time to wait for background read';
n=n+1; serport_str.fields{n,1} = 'input_buffer_size    = buffer size for background read';
n=n+1; serport_str.fields{n,1} = 'spl_settings         = special settings';
% ----------------------------------------------------------------------------------

iscan = struct(...
'port', [],...
'serport',  struct(serport_str),...
'sample_freq', [],...
'max_params', [],...
'sample_size', [],...
'track_on_code', [],...
'track_off_code', [],...
'fields', []);
% ----------------------------------------------------------------------------------
n=0; 
n=n+1; iscan.fields{n,1} = 'port                        = port ID to which ISCAN is connected';
n=n+1; iscan.fields{n,1} = 'serport                     = serial port information';
n=n+1; iscan.fields{n,1} = 'sample_freq                 = ISCAN sampling frequency';
n=n+1; iscan.fields{n,1} = 'max_params                  = number of parameters sent from ISCAN';
n=n+1; iscan.fields{n,1} = 'sample_size                 = size (in bytes) of 1 ISCAN sample';
n=n+1; iscan.fields{n,1} = 'track_on_code               = code for turning on Track Active';
n=n+1; iscan.fields{n,1} = 'track_off_code              = code for turning off Track Active';
% ----------------------------------------------------------------------------------

iscan.sample_freq     = 120;
iscan.max_params      = 6; % can send upto 6 parameters on serial port
iscan.sample_size     = (iscan.max_params * 2 + 2);
iscan.track_on_code   = uint8(hex2dec('80'));
iscan.track_off_code  = uint8(hex2dec('81'));
% codes for calibration
iscan.POR_reset_mode_code  = uint8(hex2dec('92'));
iscan.POR_calib_mode_code  = uint8(hex2dec('93'));
iscan.POR_output_mode_code  = uint8(hex2dec('94'));
iscan.POR_select_point_code  = uint8(hex2dec('96'));
iscan.POR_enter_point_code  = uint8(hex2dec('97'));
% new code added to choose specific point
iscan.POR_specific_point_code  = uint8(hex2dec('98'));
% this code should be followed by an index byte 0x00, 0x01, .. 0x04

iscan.serport.com_port          = 'COM1';
iscan.serport.baud_rate         = 115200;
iscan.serport.terminator        = 10;
iscan.serport.sndrcv_timeout    = 15;
iscan.serport.poll_latency      = 1/iscan.sample_freq;
iscan.serport.bytes_to_read     = iscan.sample_size;iscan.serport.max_bkgrnd_read_time = 3600;
iscan.serport.input_buffer_size = ceil(iscan.sample_freq * iscan.serport.max_bkgrnd_read_time * iscan.sample_size);
iscan.serport.spl_settings      = [];

port_settings = sprintf('%s BaudRate=%i InputBufferSize=%i Terminator=%i ReceiveTimeout=%f',...
                         iscan.serport.spl_settings,...
                         iscan.serport.baud_rate,...
                         iscan.serport.input_buffer_size,...
                         iscan.serport.terminator,...
                         iscan.serport.sndrcv_timeout);

% Opening serial port
iscan.port = IOPort('OpenSerialPort', iscan.serport.com_port, port_settings);

% Purging the read/write buffers
IOPort('Purge', iscan.port);

% Turning ON Track Active on ISCAN
IOPort('Write', iscan.port, iscan.track_on_code); WaitSecs(1e-10);

% Starting asynchronous background data collection
async_setting = sprintf('PollLatency=%f StartBackgroundRead=%i',...
                         iscan.serport.poll_latency,...
                         iscan.serport.bytes_to_read);
IOPort('ConfigureSerialPort', iscan.port, async_setting);

return;