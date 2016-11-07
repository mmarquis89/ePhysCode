
expNum = 1; 
ampMode = 'Iclamp';  % 'Vclamp' or 'Iclamp'
trialDuration = [7 6 1 6];    % [pre-stim, pinch valve acclimation, clean valve open, post-stim]
pumpTiming = [1, .03];        % [seconds before odor presentation to eject blockers, duration of ejection in sec]
odor = 'NA';  
% Use 'NA', 'EmptyVial', 'ParaffinOil', or the odor name
 
%% Delete all data from an experiment
delExp = 1;
strDate = datestr(now, 'yyyy-mmm-dd');
delete([strDate,'\*_E',num2str(delExp),'*']);


%% Acquire Trace 
traceDuration = 10; % Time to acquire in seconds
Acquire_Trial_Odor(expNum, traceDuration, [], [], ampMode, 'NA'); 


%% Run Trial(s)
nTrials = 5;
pumpOn = 0;
for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial)])
    Acquire_Trial_Odor(expNum, trialDuration, pumpTiming, pumpOn, ampMode, odor);
end 
disp('End of block');

%% Run Block of Trials
nTrials = 6;
% pumpBlock = zeros(1, nTrials);
pumpBlock = [0, ones(1, nTrials-1)];
% pumpBlock = pumpBlock(randperm(length(pumpBlock)));

for iTrial = 1:nTrials
    disp(['iTrial = ', num2str(iTrial), ', pumpOn = ', num2str(pumpBlock(iTrial))])
    Acquire_Trial_Odor(expNum, trialDuration, pumpTiming, pumpBlock(iTrial), ampMode, odor);
    
end


%% Single I = 0 Trial

ampMode = 'Iclamp';  % 'Vclamp' or 'Iclamp'
Acquire_Trial_Odor(expNum, trialDuration, ampMode, 'NA', odor);


%% Single V-clamp Trial
ampMode = 'Vclamp';
vHold = -45;
Acquire_Trial_Odor(expNum, trialDuration, ampMode, vHold, odor);
