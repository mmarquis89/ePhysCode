parentDir = 'D:\Dropbox (HMS)\Behavior_Experiments';

expDate = '2019_03_04_exp_1'; 

trialDuration = 10;
stimOnsets = [1 5 7];
stimDurs = [2 1 1];

SAMP_RATE = 10000;
FRAME_RATE = 25;

%% SETUP TRIAL PARAMETERS

% Determine trial number
expDir = fullfile(parentDir, expDate);
if ~isdir(expDir)
    mkdir(expDir);
end
dataFiles = dir(fullfile(expDir, '*metadata.mat'));

if isempty(dataFiles)
    tid = 0;
else
    fileNames = string({dataFiles.name});
    trialNums = str2double(regexp(fileNames, '(?<=trial_).*(?=_metadata)', 'match'));
    tid = max(trialNums) + 1;
end

% Create session
s = daq.createSession('ni');

% Setup output channels
s.addDigitalChannel('Dev1', 'port0/line20', 'OutputOnly'); % Camera trigger
s.addDigitalChannel('Dev1', 'port0/line14', 'OutputOnly'); % LED trigger
s.addAnalogInputChannel('Dev1', 0,'Voltage'); % just to use the clock

% Setup output data
zeroStim = zeros(SAMP_RATE * trialDuration, 1);
cameraTrigger = zeroStim; LEDtrigger = zeroStim;

% Camera trigger
triggerInterval = SAMP_RATE / FRAME_RATE;
framesPerTrial = (trialDuration * SAMP_RATE) / triggerInterval;
if mod(triggerInterval, 1) || mod(framesPerTrial, 1)
    disp('WARNING: frame count errors due to camera trigger timing are likely!')
end
cameraTrigger(1:round(triggerInterval):end) = 1;

% LED trigger
stimStartFrames = round(stimOnsets * SAMP_RATE);
stimEndFrames = round((stimOnsets + stimDurs) * SAMP_RATE);
for iStim = 1:numel(stimStartFrames)
    LEDtrigger(stimStartFrames(iStim):stimEndFrames(iStim)) = 1;
end

% Setup acquisition
s.Rate = SAMP_RATE;
outputData = [cameraTrigger, LEDtrigger];
outputData(end, :) = 0;
s.queueOutputData(outputData);

% Load output data and start trial
startForeground(s);

% Save output and metadata
save(fullfile(parentDir, ['tid_', num2str(tid), 'metadata.mat']), 'outputData', 'SAMP_RATE', 'FRAME_RATE', 'expDate', ...
            'trialDuration', 'stimOnsets', 'stimDurs', 'tid');

    