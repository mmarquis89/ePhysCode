
expNum = 2; 
trialDuration = [10 1 9];    % [pre-stim, clean valve open, post-stim]
Istep = [12];
Ihold = 0;

% ODORS MUST BE LISTED IN ORDER OF VALVE NUMBER!!!
odors =  {'cVA_e-2', 'GeranylAcetate_e-2', 'ACV_e-3', 'ParaffinOil'};

%% DELETE ALL DATA FROM THE CURRENT EXPERIMENT

strDate = datestr(now, 'yyyy-mmm-dd');
dList = dir(['data/', strDate,'/Raw_WCwaveform_',strDate,'_E',num2str(expNum),'*.mat']);
if numel(dList) < 10
    delete(['Data/', strDate,'/*_E',num2str(expNum),'*']);
    rmdir(['Data/_Movies/', strDate, '/E', num2str(expNum), '*'], 's');
else
    disp('Too many trials for automatic deletion');
end



%% ACQUIRE INITIAL PATCHING DATA

aS = acqSettings;
aS.expNum = expNum;
initialPatchingAcq(aS);

%% ACQUIRE TRACE

traceDuration = 10; % Time to acquire in seconds

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = traceDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
end

Acquire_Trial(aS);

%% RUN ODOR TRIAL(S)

% Create shuffled trial order
nReps = 2;
odorList = shuffleTrials(odors(1:4), nReps);
disp('Shuffle complete')

%Setup odor and valve list manually
% odorList = odors([1]);

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = trialDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
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
    Acquire_Trial(aS);
end 
disp('End of block');

%% RUN OPTO STIM TRIAL(S)

optoDuration = [8 3 9];

% Setup trials of a single odor with alternating light stim (opto on second trial)
valveNum = 3;
nReps = 1;
trialOdor = odors{valveNum};
optoDurationList = repmat({[] ; optoDuration}, nReps, 1);

for iFold = 1
    aS = acqSettings;
    aS.expNum = expNum;
    aS.trialDuration = trialDuration;
    aS.Istep = Istep;
    aS.Ihold = Ihold;
end

% Make sure opto and trial durations sum to the same number
if sum(trialDuration) ~= sum(optoDuration)
    disp('Duration mismatch!')
    return
end

% Run Trials
nTrials = length(optoDurationList);
for iTrial = 1:nTrials
    aS.altStimDuration = optoDurationList{iTrial};
    aS.odor = trialOdor;
    as.valveID = valveNum;
    if ~isempty(aS.altStimDuration)
        aS.altStimType = 'opto';
    end
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' trialOdor])
    Acquire_Trial(aS);
end 
disp('End of block');

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
