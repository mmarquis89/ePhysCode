
expNum = 1; 
trialDuration = [8 3 1 8];    % [pre-stim, pinch valve acclimation, clean valve open, post-stim]
Istep = [];
Ihold = 0;

% ODORS MUST BE LISTED IN ORDER OF VALVE NUMBER!!!
odors = {'PentylAcetate_e-6', '2-butanone_e-6', 'EthylAcetate_e-7', 'Farnesol_e-2'};

%% DELETE ALL DATA FROM THE CURRENT EXPERIMENT

strDate = datestr(now, 'yyyy-mmm-dd');
dList = dir(['data/', strDate,'/Raw_WCwaveform_',strDate,'_E',num2str(expNum),'*.mat']);
if numel(dList) < 10
    delete(['data/', strDate,'\*_E',num2str(expNum),'*']);
else
    disp('Too many trials for automatic deletion');
end

%% ACQUIRE TRACE
traceDuration = 10; % Time to acquire in seconds
Acquire_Trial_Odor(expNum, traceDuration, [], [], Istep, Ihold); 
        
%% RUN ODOR TRIAL(S)

% Create shuffled trial order
nReps = 8;
odorList = shuffleTrials(odors, nReps);

% Setup odor and valve list manually
% odorList = odors([1 2 3 1 2 3 1 2 3 1 2 3]);

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

%% RUN IONTOPHORESIS TRIAL(S)

iontoDuration = [7 6 7];

% Setup for alternating trials (ionto on first trial)
valveList = [];
iontoDurationList = repmat({iontoDuration;[]}, 4, 1);

% Make sure ionto and trial durations match up
if sum(trialDuration) ~= sum(iontoDuration)
    disp('Duration mismatch!')
    return
end

% Run Trials
nTrials = length(valveList);
for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial), ', Odor = ' odors{valveList(iTrial)}])
    Acquire_Trial_Odor_Ionto(expNum, trialDuration, iontoDurationList{iTrial}, odors{valveList(iTrial)}, valveList(iTrial), Istep, Ihold);
end 
disp('End of block');

%% RUN EJECTION TRIALS
 
nReps = 2;
ejectTrialDuration = [2 2];   % [pre-ejection time, post-ejection time]
ejectDuration = 100;           % [ejection duration in milliseconds]

for iTrial = 1:nReps
   pressureEject(expNum, ejectTrialDuration, ejectDuration, Ihold); 
   disp(['iTrial = ', num2str(iTrial)])
end
disp('End of block');