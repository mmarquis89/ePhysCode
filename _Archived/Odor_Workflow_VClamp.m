%%

expNum = 2; 
trialDuration = [7 6 1 6];    % [pre-stim, pinch valve acclimation, clean valve open, post-stim]
odor = 'Geranyl Acetate'; % Use 'NA', 'EmptyVial', 'ParaffinOil', or the odor name


%% Acquire Trace

traceDuration = 10; % Time to acquire in seconds
Acquire_Trace(expNum, traceDuration, 'NA');  
 
%% Single I = 0 Trial

ampMode = 'Iclamp';  % 'Vclamp' or 'Iclamp'
Acquire_Trial_Odor(expNum, trialDuration, ampMode, 'NA', odor);

%% Run Block of Trials

ampMode = 'Vclamp';  % 'Vclamp' or 'Iclamp'
vCommands = [-55, -75]; 
trialsPerVcom = 10;

trials = ones(1, trialsPerVcom);
vHolds = [];
for iVc = 1:length(vCommands)
    vHolds = [vHolds, trials*vCommands(iVc)];
end
vHolds = vHolds(randperm(length(vHolds)));
for iTrial = 1:length(vHolds)
    Acquire_Trial_Odor(expNum, trialDuration, ampMode, vHolds(iTrial), odor);
    disp(length(vHolds) - iTrial)
end




%% Single V-clamp Trial
ampMode = 'Vclamp';
vHold = -45;
Acquire_Trial_Odor(expNum, trialDuration, ampMode, vHold, odor);
