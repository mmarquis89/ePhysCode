
expNum = 1; 
trialDuration = [11 1 8];    % [pre-stim, clean valve open, post-stim]
Istep = [];
Ihold = 0;

% ODORS MUST BE LISTED IN ORDER OF VALVE NUMBER!!!
odors = {'PentylAcetate_e-6', 'Farnesol_e-2', 'EthylAcetate_e-7', 'ParaffinOil'};

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
for iTrial = 1
Acquire_Trial_Odor(expNum, traceDuration, [], [], Istep, Ihold); 
end
        
%% RUN ODOR TRIAL(S)

% Create shuffled trial order
nReps = 1;
odorList = shuffleTrials(odors(1:4), nReps);
disp('Shuffle complete')
%Setup odor and valve list manually
% odorList = odors([2 3 2 3 2 3 2 3]);

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

iontoDuration = [8 5 7];

% Setup trials of a single odor with alternating iontophoresis (ionto on first trial)
valveNum = 1;
nReps = 1;
trialOdor = odors{valveNum};
iontoDurationList = repmat({iontoDuration ;[]}, nReps, 1);
 
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
 
nReps = 2;
ejectTrialDuration = [2 2];   % [pre-ejection time, post-ejection time]
ejectDuration = 100;           % [ejection duration in milliseconds]

for iTrial = 1:nReps
   pressureEject(expNum, ejectTrialDuration, ejectDuration, Ihold); 
   disp(['iTrial = ', num2str(iTrial)])
end
disp('End of block');
