
expNum = 1; 
trialDuration = [10 1 9];    % [pre-stim, clean valve open, post-stim]
Istep = [];
Ihold = 0;

% ODORS MUST BE LISTED IN ORDER OF VALVE NUMBER!!!
odors = {'EthylAcetate_e-7', 'Farnesol_e-3', 'Farnesol_e-2', 'ParaffinOil'};

%% DELETE ALL DATA FROM THE CURRENT EXPERIMENT

strDate = datestr(now, 'yyyy-mmm-dd');
dList = dir(['data/', strDate,'/Raw_WCwaveform_',strDate,'_E',num2str(expNum),'*.mat']);
if numel(dList) < 10
    delete(['data/', strDate,'\*_E',num2str(expNum),'*']);
else
    disp('Too many trials for automatic deletion');
end

%% ACQUIRE INITIAL PATCHING DATA

initialPatchingAcq(expNum);

%% ACQUIRE TRACE
traceDuration = 10; % Time to acquire in seconds
for iTrial = 1
    Acquire_Trial_Odor(expNum, traceDuration, [], [], Istep, Ihold);
end

%% RUN ODOR TRIAL(S)

% Create shuffled trial order
nReps = 2;
odorList = shuffleTrials(odors(1:4), nReps);
disp('Shuffle complete')
%Setup odor and valve list manually
% odorList = odors([2 2]);

% Setup list of valves to use for each trial 
nTrials = length(odorList);
valveList = zeros(1,nTrials);
for iOdor = 1:length(odors)
    valveList(strcmp(odorList, odors(iOdor))) = iOdor;
end

% Run Trials
for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' odorList{iTrial}])
    Acquire_Trial_Odor(expNum, trialDuration, odorList{iTrial}, valveList(iTrial), Istep, Ihold);
end 
disp('End of block');

%% RUN OPTO STIM TRIAL(S)

optoDuration = [8 3 9];

% Setup trials of a single odor with alternating light stim (opto on  trial)
valveNum = 3;
nReps = 1;
trialOdor = odors{valveNum};
optoDurationList = repmat({[] ; optoDuration}, nReps, 1);
 
% Make sure opto and trial durations sum to the same number
if sum(trialDuration) ~= sum(optoDuration)
    disp('Duration mismatch!')
    return
end

% Run Trials
nTrials = length(optoDurationList);
for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' trialOdor])
    Acquire_Trial_Odor_Opto(expNum, trialDuration, optoDurationList{iTrial}, trialOdor, valveNum, Istep, Ihold);
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
    Acquire_Trial_Odor_Ionto(expNum, trialDuration, iontoDurationList{iTrial}, trialOdor, valveNum, Istep, Ihold);
end 
disp('End of block');


%% RUN EJECTION TRIALS
 
nReps = 1;
ejectTrialDuration = [2 2];   % [pre-ejection time, post-ejection time]
ejectDuration = 100;           % [ejection duration in milliseconds]

for iTrial = 1:nReps
   pressureEject(expNum, ejectTrialDuration, ejectDuration, Ihold); 
   disp(['iTrial = ', num2str(iTrial)])
end
disp('End of block');
