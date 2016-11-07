%%
expNum = 1;
trialDuration = [5 .2 10];    % [pre-stim, stim, post-stim]
stimVolts = 10;	   % Intensity in volts to supply to LED ranging from 3-10
stimDutyCyc = 50;    % Number of time points out of every 100 that LED should be on

%% Acquire Trace
AcquireTrial_MM(expNum, [4 1 5], 0, stimDutyCyc);

%% Single trial test
AcquireTrial_MM(expNum, trialDuration, stimVolts, stimDutyCyc);

%% Loop through different intensities
rStim = @(stims) stims(randperm(length(stims)));
stims = [0.1:1:10]*10;
stims = [stims, stims, stims, stims];
stims = [rStim(stims),rStim(stims),rStim(stims),rStim(stims),rStim(stims)];

for iTrial = 1:length(stims)
   stimDutyCyc = stims(iTrial)
   AcquireTrial_MM(expNum, trialDuration, stimVolts, stimDutyCyc);
end   

%% Repeat trial

for iTrial = 1:10
    AcquireTrial_MM(expNum, trialDuration, stimVolts, stimDutyCyc);
end

%% Plot a voltage trace from a specific trial
trialNum = 15;
expNum = 1;
expDate = '10-Mar-2015';
plotVoltage(trialNum, expNum, expDate);