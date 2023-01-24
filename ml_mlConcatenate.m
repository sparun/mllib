% SLIGHT update to mlconcatenate 
% 
% JAEWON has corrected the mistake for NaN in touch data but keeping it here for legacy sake
% (rename to "mlconcatenate.m" if updating codein ML source folder)
%
% Thomas - 19-10-2020 - Touch points are NaN from getgo so error is thrown
           
function [val,MLConfig,TrialRecord,filename] = ml_mlConcatenate(filename)
%MLCONCATENATE combines and returns trial data as if it is continuously
%recorded in one trial.
%
%   [data,MLConfig,TrialRecord] = mlconcatenate(filename)
%   [data,MLConfig,TrialRecord,filename] = mlconcatenate
%
%   Jan 4, 2018         Written by Jaewon Hwang (jaewon.hwang@nih.gov, jaewon.hwang@hotmail.com)

TrialRecord = [];

if ~exist('filename','var') || 2~=exist(filename,'file')
    [n,p] = uigetfile({'*.bhv2;*.h5;*.bhv','MonkeyLogic Datafile (*.bhv2;*.h5;*.bhv)'});
    if isnumeric(n), error('File not selected'); end
    filename = [p n];
end
[~,~,e] = fileparts(filename);
try
    switch lower(e)
        case '.bhvz', fid = mlbhvz(filename,'r');
        case '.bhv2', fid = mlbhv2(filename,'r');
        case '.h5', fid = mlhdf5(filename,'r');
        case '.mat', fid = mlmat(filename,'r');
        otherwise, error('Unknown file format');
    end
    MLConfig = fid.read('MLConfig');
    data = fid.read_trial();
    if 2<nargout, TrialRecord = fid.read('TrialRecord'); end
    close(fid);
catch err
    close(fid);
    rethrow(err);
end

if 1000~=MLConfig.AISampleRate, error('AISampleRate must be 1000 Hz!!!'); end
if isfield(MLConfig,'NonStopRecording')
    NonStopRecording = MLConfig.NonStopRecording;
else
    NonStopRecording = false;
end

ntrial = length(data);
nsample = ceil(data(ntrial).AbsoluteTrialStartTime + data(ntrial).BehavioralCodes.CodeTimes(end) + eps);

field = {'Trial','BlockCount','TrialWithinBlock','Block','Condition','TrialError','ReactionTime','AbsoluteTrialStartTime','TrialDateTime', ...
    'BehavioralCodes','ObjectStatusRecord','RewardRecord','UserVars','VariableChanges','TaskObject','CycleRate','Ver'};
for m=field
    if ~isfield(data,m{1}), continue, end
    val.(m{1}) = vertcat(data.(m{1}));
end
for m=ntrial:-1:1
    val.BehavioralCodes(m).CodeTimes = val.BehavioralCodes(m).CodeTimes + val.AbsoluteTrialStartTime(m);
    if isfield(val.ObjectStatusRecord(m),'Time')
        val.ObjectStatusRecord(m).Time = val.ObjectStatusRecord(m).Time + val.AbsoluteTrialStartTime(m);
    else
        for n=1:length(val.ObjectStatusRecord(m).SceneParam)
            val.ObjectStatusRecord(m).SceneParam(n).Time = val.ObjectStatusRecord(m).SceneParam(n).Time + val.AbsoluteTrialStartTime(m);
        end
    end
    val.RewardRecord(m).StartTimes = val.RewardRecord(m).StartTimes + val.AbsoluteTrialStartTime(m);
    val.RewardRecord(m).EndTimes = val.RewardRecord(m).EndTimes + val.AbsoluteTrialStartTime(m);
end

AnalogData = [data.AnalogData];
val.AnalogData.SampleInterval = vertcat(AnalogData.SampleInterval);

analog = {'Eye','Eye2','EyeExtra','Joystick','Joystick2','Touch','Mouse','KeyInput','PhotoDiode'};
for m=analog
	if ~isfield(AnalogData(1),m{1}), continue, end
    if isempty(AnalogData(1).(m{1})), val.AnalogData.(m{1}) = []; continue, end
    val.AnalogData.(m{1}) = NaN(nsample,size(AnalogData(1).(m{1}),2));
    for n=1:ntrial
        t1 = ceil(val.AbsoluteTrialStartTime(n) + eps);
        if NonStopRecording
            if 1<n && isnan(val.AnalogData.(m{1})(t1-1,1)), t1 = t1 - 1; end
        end
        t2 = t1 + size(AnalogData(n).(m{1}),1) - 1;
        val.AnalogData.(m{1})(t1:t2,:) = AnalogData(n).(m{1});
    end
    if NonStopRecording
        %%%% Thomas - 19-10-2020
        if ~strcmpi(m{1}, 'Touch')% Touch points are NaN from getgo so error is thrown
            row = find(isnan(val.AnalogData.(m{1})(:,1)));
            val.AnalogData.(m{1})(row,:) = val.AnalogData.(m{1})(row-1,:);
        end%
    end
end
general = fieldnames(AnalogData(1).General)';
for m=general
    if isempty(AnalogData(1).General.(m{1})), val.AnalogData.General.(m{1}) = []; continue, end
    val.AnalogData.General.(m{1}) = NaN(nsample,size(AnalogData(1).General.(m{1}),2));
    for n=1:ntrial
        t1 = ceil(val.AbsoluteTrialStartTime(n) + eps);
        if NonStopRecording
            if 1<n && isnan(val.AnalogData.General.(m{1})(t1-1,1)), t1 = t1 - 1; end
        end
        t2 = t1 + size(AnalogData(n).General.(m{1}),1) - 1;
        val.AnalogData.General.(m{1})(t1:t2,:) = AnalogData(n).General.(m{1});
    end
    if NonStopRecording
        row = find(isnan(val.AnalogData.General.(m{1})(:,1)));
        val.AnalogData.General.(m{1})(row,:) = val.AnalogData.General.(m{1})(row-1,:);
    end
end
if isfield(AnalogData(1),'Button')
    button = fieldnames(AnalogData(1).Button)';
    for m=button
        if isempty(AnalogData(1).Button.(m{1})), val.AnalogData.Button.(m{1}) = []; continue, end
        val.AnalogData.Button.(m{1}) = NaN(nsample,size(AnalogData(1).Button.(m{1}),2));
        for n=1:ntrial
            t1 = ceil(val.AbsoluteTrialStartTime(n) + eps);
            if NonStopRecording
                if 1<n && isnan(val.AnalogData.Button.(m{1})(t1-1,1)), t1 = t1 - 1; end
            end
            t2 = t1 + size(AnalogData(n).Button.(m{1}),1) - 1;
            val.AnalogData.Button.(m{1})(t1:t2,:) = AnalogData(n).Button.(m{1});
        end
        if NonStopRecording
            row = find(isnan(val.AnalogData.Button.(m{1})(:,1)));
            val.AnalogData.Button.(m{1})(row,:) = val.AnalogData.Button.(m{1})(row-1,:);
        end
    end
end
