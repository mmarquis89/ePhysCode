setLED(10)
%%
expNum = 1; 
trialDuration = [7 1 7];    % [pre-stim, clean valve open, post-stim]
Istep = [];
Ihold = 0;

% ODORS MUST BE LISTED IN ORDER OF VALVE NUMBER!!!
odors = {'EthylAcetate_e-2', 'cVA_e-2', 'IsobutyricAcid_e-2', 'ParaffinOil'};


%% DELETE ALL DATA FROM THE CURRENT EXPERIMENT

strDate = datestr(now, 'yyyy-mmm-dd');
dList = dir(['C:/Users/Wilson Lab/Dropbox (HMS)/data/', strDate,'/Raw_WCwaveform_',strDate,'_E',num2str(expNum),'*.mat']);
if numel(dList) < 10
    delete(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate,'/*_E',num2str(expNum),'*']);
    rmdir(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/_Movies/', strDate, '/E', num2str(expNum), '*'], 's');
else
    disp('Too many trials for automatic deletion');
end
 
%% ACQUIRE TRACE

traceDuration = 10; % Time to acquire in seconds

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = traceDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
%     aS.stepLength = 3;
end
tic
[~] = Acquire_Trial(aS);
disp(['Total time elapsed: ', num2str(toc), ' sec']);

%% RUN ODOR TRIAL(S)

% Setup odor and valve list manually
% odorList = odors([1 1 2 2 3 3 4 4]);

% Create shuffled trial order
nReps = 2;
odorPanel = [1:4];
odorList = shuffleTrials(odors(odorPanel), nReps);
disp('Shuffle complete')

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = trialDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
%     aS.stepLength = 2;
end

% Setup list of valves to use for each trial 
nTrials = length(odorList);
valveList = zeros(1,nTrials);
for iOdor = 1:length(odors)
    valveList(strcmp(odorList, odors(iOdor))) = iOdor;
end

% Run Trials
for iTrial = 1:nTrials
    aS.odor = odorList{iTrial};
    aS.valveID = valveList(iTrial);
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' odorList{iTrial}])
    tic
    [~] = Acquire_Trial(aS);
    disp(['Total time elapsed: ', num2str(toc), ' sec']);
end 
disp('End of block');

%% RUN PAIRS OF OPTO STIM TRIALS

optoDuration = [6 3 6];
LEDpower = 5; % 1-100
dutyCycle = 5; % 1-100
odorPanel = [1:4];
nReps = 1;

% Make sure opto and trial durations sum to the same number
if sum(trialDuration) ~= sum(optoDuration)
    disp('Duration mismatch!')
    return
end

% Set general acquisition parameters
setLED(LEDpower); 
for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = trialDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
    aS.altStimParam = dutyCycle;
%     aS.stepStartTime = 4;
    aS.metadata.LEDpower = LEDpower;
end

% Setup odor trials with alternating light stim
if length(odorPanel) > 1
    odorList = shuffleTrials(odors(odorPanel), nReps);
    disp('Shuffle complete')
else
    odorList = repmat(odors(odorPanel), nReps,1);
end
nTrials = length(odorList);
valveList = zeros(1,nTrials);
for iOdor = 1:length(odors)
    valveList(strcmp(odorList, odors(iOdor))) = iOdor;
end

% Duplicate each odor in the list
repValveList = repmat(valveList, [2 1]); 
repValveList = repValveList(:)';
repOdorList = repmat(odorList, [2 1]);
repOdorList = repOdorList(:)';
optoDurationList = repmat({[];optoDuration}, length(repValveList)/2, 1);

% Run Trials
nTrials = length(optoDurationList);
for iTrial = 1:nTrials
    aS.altStimDuration = optoDurationList{iTrial};
    aS.odor = repOdorList{iTrial};
    aS.valveID = repValveList(iTrial);
    if ~isempty(aS.altStimDuration)
        aS.altStimType = 'opto';
    end
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' repOdorList{iTrial}])
    tic
    Acquire_Trial(aS);
    disp(['Total time elapsed: ', num2str(toc), ' sec']);
end 
disp('End of block');

%% RUN TRIAL(S) WITH LED STIMULUS ONLY

stimDuration = [6 3 6];
traceDuration = sum(stimDuration);
LEDpower = 10; % 1-100
dutyCycle = 100; % 1-100
nReps = 1;

% Set general acquisition parameters
setLED(LEDpower); 
for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = traceDuration;
    aS.altStimDuration = stimDuration;
    aS.altStimType = 'opto';
    aS.Istep = Istep;
    aS.Ihold = Ihold;
    aS.altStimParam = dutyCycle;
    aS.metadata.LEDpower = LEDpower;
end
for iTrial = 1:nReps
    [~] = Acquire_Trial(aS);
end
%% RUN IONTOPHORESIS TRIAL(S)

iontoDuration = [5 7 18];

% Setup trials of a single odor with alternating iontophoresis (ionto on first trial)
valveNum = 2;
nReps = 1;
trialOdor = odors{valveNum};
iontoDurationList = repmat({[] ; iontoDuration}, nReps, 1);
 
% Make sure ionto and trial durations sum to the same number
if sum(trialDuration) ~= sum(iontoDuration)
    disp('Duration mismatch!')
    return
end

% Run Trials
nTrials = length(iontoDurationList);
for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' trialOdor])
    Acquire_Trial(expNum, trialDuration, iontoDurationList{iTrial}, 'ionto', trialOdor, valveNum, Istep, Ihold);
end 
disp('End of block');

%% RUN EJECTION TRIALS
 
nReps = 1;
ejectDuration = [5 0.05 4.95];      % [pre-ejection time, ejection duration, post-ejection time] in seconds

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = sum(ejectDuration);
    aS.altStimDuration = ejectDuration;
    aS.altStimType = 'eject';
    aS.Istep = Istep;
    aS.Ihold = Ihold;
end

for iTrial = 1:nReps
   Aquire_Trial(aS)
   disp(['iTrial = ', num2str(iTrial)])
end
disp('End of block');
