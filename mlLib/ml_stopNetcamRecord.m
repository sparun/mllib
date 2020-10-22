% ml_stopNetcamRecord.m - Vision Lab, IISc
% ----------------------------------------------------------------------------------------
% Stops netcam video recording remotely on netcamPC by accessing watchtower via LAN. 
%
% REQUIRED: netcam recording being started and apitoken from current remote session
% 
% VERSION HISTORY
% - 15-Oct-2020  - Thomas - First implementation
%-----------------------------------------------------------------------------------------

function outcome= ml_stopNetcamRecord(apitoken)

try
    % Watchtower details
    watchtowerURL = 'https://10.120.10.57:4343';
    
    % Camera and Recording parameters
    cameraID     = {'e3v810f', 'e3v817d', 'e3v8191', 'e3v817a'};
    
    % STOP recording
    response = webwrite([watchtowerURL, '/api/cameras/action'], ...
        'SerialGroup[]', string([cameraID{1}; cameraID{2}; cameraID{3}; cameraID{4}])',...
        'Action', 'STOPRECORDGROUP',...
        'apitoken', apitoken,...
        weboptions('CertificateFilename','','ArrayFormat','repeating'));
    
    % DISCONNECT cameras
    for camID = 1:4
        response = webwrite([watchtowerURL, '/api/cameras/action'],...
            'Serial', cameraID{camID},...
            'Action', 'DISCONNECT', ...
            'apitoken', apitoken, weboptions('CertificateFilename',''));
    end
           
    outcome = 1;
catch
    outcome = 0;
end
end
