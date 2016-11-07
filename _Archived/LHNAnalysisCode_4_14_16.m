
%% LOAD EXPERIMENT

expData = loadExperiment('2016-Apr-13',1);
    
%% PULL OUT TRIAL BLOCK
bl = [];
blockLists = {};
% Dec 02: Acetoin 7:11 55:60, 2-Butanone 27:31 43:48, 23-Butanediol 32:36 67:72
% Jan 10: Acetoin 12:16 57:61, 2-Butanone 7:11 52:56, 23-Butanediol 17:21 62:66
% 61:66

trialList = [52:63];
block = getTrials(expData, trialList);  % Save trial data and info as "block"
%block.trialInfo(1).pumpTiming = [1 .02];

for iFold = 1 % Just here so I can fold the code below

% Create global variables  
bl.trialInfo = block.trialInfo;
bl.date = block.trialInfo(1).date;
bl.trialList = trialList; 
bl.nTrials = length(block.trialInfo);                                                             % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                      % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                  % Sample duration
bl.time = bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data(:,1,1));              % Time in seconds of each sample
bl.trialDuration = block.trialInfo(1).trialduration;
% if ~isempty(block.trialInfo(1).ampMode)
%    bl.ampMode = block.trialInfo(1).ampMode; 
% end
bl.odors = {block.trialInfo.odor};
bl.Rpipette = pipetteResistanceCalc(expData.trialData(1).scaledOut);

% Get picoPump I/O data
if ~isempty(block.trialInfo(1).pumpOn)
    for iTrial = 1:bl.nTrials
        bl.pumpOn(iTrial) = block.trialInfo(iTrial).pumpOn;
    end
bl.pumpTiming = block.trialInfo(1).pumpTiming;
end

% This stuff only applies if an odor was presented
if length(bl.trialDuration) > 1   
    % Get vHolds for each trial if applicable
%      if strcmp(bl.ampMode, 'Vclamp')
%         vHolds = zeros(bl.nTrials, 1);
%         for iTrial = 1:bl.nTrials
%             vHolds(iTrial) = block.trialInfo(iTrial).vHold;
%         end
%         bl.vHolds = vHolds;
%      end    
    % Save valve timing
    bl.pinchOpen = block.trialInfo(1).trialduration(1);                                                % Pre-stim time (sec)
    bl.stimOnTime = block.trialInfo(1).trialduration(1) + block.trialInfo(1).trialduration(2);
    bl.stimLength = block.trialInfo(1).trialduration(3);                                               % Stim duration
else
    bl.vHolds = [];
    bl.pinchOpen = [];
    bl.stimOnTime = [];
    bl.stimLength = [];
end

% Save recorded data
bl.voltage = block.data(:,:,2);             % 2 - 10 Vm voltage traces
bl.current = block.data(:,:,1);             % 1 - Preamp-filtered current
bl.scaledOut = block.data(:,:,3);           % 3 - Scaled Output
end 

%% PLOT EACH TRIAL VOLTAGE AND CURRENT
f = figInfo; 
f.timeWindow = [];
f.yLims = [];
f.lineWidth = [];
[h,j] = traceOverlayPlot(bl, f, []'); %zeros(1,30) ones(1,15); zeros(1,15), ones(1,15), zeros(1,15); ones(1,15), zeros(1,30)

%% LOWPASS FILTER THE VOLTAGE TRACES
% All frequency values are in Hz.
Fs = 10000;  % Sampling Frequency
N  = 50;  % Order
Fc = 15;   % Cutoff Frequency
% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.lowpass('N,F3dB', N, Fc, Fs);
Hd = design(h, 'butter');
lpfTrials = [];
for iTrial = 1:bl.nTrials
    filt = filter(Hd,bl.scaledOut(:,iTrial)');
    filt2 = filter(Hd, filt(end:-1:1));
    lpfTrials(:, iTrial) = filt2(end:-1:1); 
end
bl.scaledOut = lpfTrials;

%% PLOT AVG TRACE OVERLAY
f = figInfo;
f.figDims = [10 200 660 400];
f.timeWindow = [];
f.lineWidth = 3;
traceGroups = [1 2 2 1 2 1 2 1 1 2 1 2]; %[ones(1,5) 2*ones(1,5) 3*ones(1,6) 4*ones(1,6)]; %bl.pumpOn; %[0 0 0 0 0 1 1 1 1 1]
groupColors = [0 0 1; 1 0 0; 1 .5 0; 0 0 0]; % [0 0 1; 1 0 0] %[1 0 0;1 0 1;0 0 1;0 1 0]
f.figLegend = {'Control trials', 'Ejection Trials'};
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors);

title([])
legend('off')
legend({'Control Trials'; 'Ejection Trials'}, 'FontSize', 16, 'Location', 'northwest')
ax = gca;
ax.LineWidth = 3;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 18;
ax.YLim = [-55 -20]; % ;[-60 -10]
ylabel('Vm (mV)');



%% OVERLAY MEAN TRACES FOR EACH ODOR
f = figInfo;
f.yLims = [];
f.figDims = [10 200 1000 600];
f.timeWindow = [12 16];
odorCell = cell(bl.nTrials,1);
for iTrial = 1:bl.nTrials
   odorCell{iTrial} = bl.trialInfo(iTrial).odor; 
end
odorList = unique(odorCell,'stable');
nOdors = length(odorList);
traceGroups = zeros(1, nOdors);
for iOdor = 1:nOdors
    traceGroups(strcmp(odorCell, odorList{iOdor})) = iOdor;
    f.figLegend{iOdor} = odorList{iOdor};
end
groupColors = [0 0 1; 0 .75 0; 1 0 0; 1 .5 0; 0 0 0]; %colormap(jet(nOdors));
f.figLegend = [f.figLegend, {'Pinch valve open', 'Ejection', 'Odor onset', 'Odor offset'}];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors);

%% GET SPIKE TIMES FROM CURRENT

posThresh = [3 2 2 2]; % Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
invert = 1;
spikes = getSpikesI(bl, posThresh);     % Find spike locations in all trials
bl.spikes = spikes;                     % Save to data structure
normCurrent = bl.current - mean(median(bl.current));

% Look at histogram of peak heights to evaluate choice of threshold
allPks = [];
for iTrial = 1:bl.nTrials
    allPks = [allPks; bl.spikes(iTrial).peakVals];
end
figure(4), hist(allPks,30)

    %% Plot current traces centered at zero to help choose threshold
    figure(5);plot(bl.time, normCurrent)
    set(gcf,'Position',[10 50 1650 800]);
    
    %% Plot all spikes centered on peak
    figure(6);clf;hold all
    for iTrial = 1:size(bl.spikes, 2)
        locs = bl.spikes(iTrial).locs;
        if ~isempty(locs)
            for iSpk = 1:length(locs)
                plot(normCurrent(locs(iSpk)-(.002*bl.sampRate):locs(iSpk)+(.006*bl.sampRate), iTrial))
            end
        end
    end
    
%% PLOT SPIKE RASTERS
f = figInfo;
f.timeWindow = [];
figInfo.figDims = [10 50 1000 900];
[h] = ejectionRasterPlot(bl, f);
%tightfig;

%% SAVING FIGURES
%h = [h1, h2];
filename = 'Jan-10_InsertionControlOdorComparison';
savefig(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\', filename])

set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
print(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\PNG files\', filename], '-dpng') 

%% COMPARE TOTAL SPIKES ACROSS CONDITIONS

timeWin = [sum(bl.trialDuration(1:2)), sum(bl.trialDuration(1:3))];

% Convert spike locations to seconds and save in cell array
spikeTimes = cell(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spikeTimes{iTrial} = (bl.spikes(iTrial).locs ./ bl.sampRate)';     
end

% Separate spike data
controlTrials = spikeTimes(bl.pumpOn == 0);  
ejectTrials = spikeTimes(bl.pumpOn == 1);

% Calculate avg total spikes
ctlSpks = [controlTrials{:}];
ejtSpks = [ejectTrials{:}];
ctlSpkMean = mean(ctlSpks(ctlSpks > timeWin(1) & ctlSpks < timeWin(2)));
ejtSpkMean = mean(ejtSpks(ejtSpks > timeWin(1) & ejtSpks < timeWin(2)));


%% PLOT ACCESS AND INPUT RESISTANCES
figure(3); clf; hold all 
figDims = [];
yLims = [];
plotResistance(bl, figDims, yLims);

%%
[b,a] = butter(2,.004,'low');
D = designfilt('lowpassiir', ...
    'PassbandFrequency', 15, ...
    'StopbandFrequency', 100, ...
    'StopbandAttenuation', 100, ...
    'SampleRate', 10000);
fvtool(D)
bl.voltage(:,1) = filtfilt(b,a, bl.current(:,1));

%% PLOT FREQUENCY CONTENT OF FIRST TRIAL
 
% Calulate frequency power spectrum for each data type
[pfftV, fValsV] = getFreqContent(bl.voltage(:,1),bl.sampRate);    
[pfftC, fValsC] = getFreqContent(bl.current(:,1),bl.sampRate);

% Plot them each on a log scale
figure(1);clf;subplot(211)
plot(fValsV, 10*log10(pfftV));
title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);

subplot(212)
plot(fValsV, 10*log10(pfftC));
title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);

%% USE A 60+120 HZ FILTER TO REMOVE LINE NOISE
freq = 60;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
end

freq = 120;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
end

