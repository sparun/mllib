function TrialRecord = ml_initExp(TrialRecord, MLConfig)

% CHECK if correct monkey name is entered-------------------------------------------------
if strcmpi(MLConfig.SubjectName, 'didi') ~= 1 &&...
        strcmpi(MLConfig.SubjectName, 'juju') ~= 1 &&...
        strcmpi(MLConfig.SubjectName, 'coco') ~= 1 &&...
        strcmpi(MLConfig.SubjectName, 'test') ~= 1
    error('[ERROR] - Monkey name is incorrect. It can only be: DiDi, JuJu or CoCo!');
end

% CHECK if Experiment PC------------------------------------------------------------------
if strcmpi(getenv('COMPUTERNAME'), 'EXPERIMENT-PC') == 1
    TrialRecord.User.mlPcFlag = 1;
        
    % CHECK if header info to be sent to eCube--------------------------------------------
    respGiven = 0;  
    while respGiven == 0
        fprintf('\n\n[IMPORTANT] - Do you want to send header to eCube? Y/N \n');
        ch = ml_getKey();
        
        if ch == 121
            TrialRecord.User.sendHeaderFlag = 1; respGiven = 1;
            disp('[UPDATE] - header will be sent to eCube');
        elseif ch == 110
            TrialRecord.User.sendHeaderFlag = 0; respGiven = 1;
            disp('[UPDATE] - header will be sent NOT be sent to eCube!!');
        else
            disp('[ERROR] - Sorry, choice can only be ''Y'' or ''N''. Please enter again!')
        end
    end
    
    % CHECK if netcam video to be saved---------------------------------------------------
    respGiven = 0;  
    while respGiven == 0
        fprintf('\n\n[IMPORTANT] - Do you want to record netcam videos? Y/N \n');
        ch = ml_getKey();
        
        if ch == 121
            TrialRecord.User.recordNetcamFlag = 1; respGiven = 1;
            disp('[UPDATE] - netcam recording will start automatically');
        elseif ch == 110
            TrialRecord.User.recordNetcamFlag = 0; respGiven = 1;
            disp('[UPDATE] - netcam recording will NOT start automatically!!');
        else
            disp('[ERROR] - Sorry, choice can only be ''Y'' or ''N''. Please enter again!')
        end
    end
else
    TrialRecord.User.mlPcFlag         = 0;
    TrialRecord.User.sendHeaderFlag   = 0;
    TrialRecord.User.recordNetcamFlag = 0;
end

% POPULATE TrialRecord with event codes---------------------------------------------------
[TrialRecord.User.err, TrialRecord.User.pic,...
    TrialRecord.User.aud, TrialRecord.User.bhv,...
    TrialRecord.User.rew, TrialRecord.User.exp,...
    TrialRecord.User.trl] = ml_loadEvents();

% SET initFlag----------------------------------------------------------------------------
TrialRecord.User.initFlag = 1;
end
