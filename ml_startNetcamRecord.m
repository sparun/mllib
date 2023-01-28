% START NETCAM RECORD - NIMH MonkeyLogic - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Records netcam video remotely on netcamPC by accessing watchtower via LAN and
% connecting to cameras, renaming the storage folder based on exp name
%
% REQUIRED
%   Starting watchtower on netcamPC and logging in and binding the cameras.
%
% INPUT
%   MLConfig - Structure with details of bhv filename
%
% OUTPUT
%   outcome  - logical, indicates if recording was started successfully
%   apitoken - unique token generated for this session that can be used to close recording
%              later (via ml_stopNetcamRecord)
% 
% VERSION HISTORY
%   15-Oct-2020 - Thomas - First implementation
%-----------------------------------------------------------------------------------------

function [outcome, apitoken] = ml_startNetcamRecord(MLConfig)

% FOLDER name for recording the video files on Netcam PC
folderName    = ['D:\series4\' MLConfig.MLPath.DataFile '_netcam'];

try
    % WATCHTOWER details (on Netcam PC)
    watchtowerURL = 'https://10.120.10.57:4343';
    username      = 'admin';
    password      = 'admin';
    
    % PARAMETERS for camera and recording
    cameraID     = {'e3v810f', 'e3v817d', 'e3v8191', 'e3v817a'};
    watchtowerIP = '10.120.10.57';
    resolution   = '720p30';
    codec        = 'H264';
    annotation   = 'Name+Time';
    segment      = '15m';
    
    % LOGIN and get API token
    loginresponse = webwrite([watchtowerURL, '/api/login'],...
        'username', username,...
        'password', password,...
        weboptions('CertificateFilename',''));
    apitoken      = loginresponse.apitoken;
    
    % SET global filepath
    response = webwrite([watchtowerURL, '/api/sessions/rename'], ...
        'Filepath', folderName,...
        'apitoken', apitoken,...
        weboptions('CertificateFilename',''));
    
    % CONNECT cameras
    for camID = 1:4
        response = webwrite([watchtowerURL, '/api/cameras/action'],...
            'Serial', cameraID{camID},...
            'Action', 'CONNECT',...
            'Iface', watchtowerIP,...
            'Config', resolution,...
            'Codec', codec,...
            'Annotation', annotation,...
            'Segtime', segment,...
            'apitoken', apitoken,...
            weboptions('CertificateFilename',''));
    end
    
    % PAUSE to let all cameras sync
    pause(10)
    
    % START recording
    response = webwrite([watchtowerURL, '/api/cameras/action'], ...
        'SerialGroup[]', string([cameraID{1}; cameraID{2}; cameraID{3}; cameraID{4}])',...
        'Action', 'RECORDGROUP',...
        'apitoken', apitoken,...
        weboptions('CertificateFilename','','ArrayFormat','repeating'));
    
    outcome = 1;
catch
    % ERROR
    outcome = 0;
end
end
