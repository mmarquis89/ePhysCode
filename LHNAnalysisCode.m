
%% LOAD EXPERIMENT

expData = loadExperiment('2016-Dec-02', 1);
    
%% SEPARATE MASTER BLOCK LIST BY ODORS
blockLists = {12:59 75:91 122:155 185:267};
idx=[];
odors = {expData.expInfo.odor};
odors = odors(~cellfun(@isempty, odors));
odors = unique(odors,'stable');
valveIDs = [expData.expInfo.valveID];
valveIDs = num2cell(unique(valveIDs, 'stable'));
idx(:,2) = odors;
idx(:,1) = valveIDs;
odors = sortrows(idx);
odors = odors(:,2);
odorBlocks = [];
for iOdor = 1:numel(odors)    
    for iBlock = 1:numel(blockLists)
        currBl = blockLists{iBlock};
        odorBlocks{iOdor, iBlock} = currBl(strcmp({expData.expInfo(blockLists{iBlock}).odor}, odors(iOdor)));
    end
end

%% PULL OUT TRIAL BLOCK
bl = [];
odorTrials = [];

% blockNum = [4];
% odorNum = [3];
% 
% for iOdor = 1:numel(odorNum)
%     odorTrials = [odorTrials, find(cellfun(@(x) strcmp(num2str(x), num2str(odorNum(iOdor))), {expData.expInfo.valveID}))];
% end

trialList = [100:119];
% blTrials = sort(odorTrials(ismember(odorTrials,[blockLists{blockNum}])));
% trialList = blTrials(21);
block = getTrials(expData, trialList);  % Save trial data and info as "block"
for iFold = 1 % Just here so I can fold the code below

% Create global variables  
bl.trialInfo = block.trialInfo;
bl.date = block.trialInfo(1).date;
bl.trialList = trialList; 
bl.nTrials = length(block.trialInfo);                                                             % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                      % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                  % Sample duration
bl.time = bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data.scaledOut);           % Time in seconds of each sample
bl.odors = {block.trialInfo.odor};
bl.Rpipette = pipetteResistanceCalc(expData.trialData(1).scaledOut);
bl.trialDuration = block.trialInfo(1).trialduration;

% Maintain backwards-compatibility with older experiments that contained pinch valve timing info
if length(bl.trialDuration) == 4
   bl.trialDuration = [sum(bl.trialDuration(1:2)), bl.trialDuration(3), bl.trialDuration(4)]; 
end

% This stuff only applies if an odor was presented
if length(bl.trialDuration) > 1   
    % Save valve timing
    bl.stimOnTime = block.trialInfo(1).trialduration(1);                                              % Pre-stim time (sec)
    bl.stimLength = block.trialInfo(1).trialduration(2);                                               % Stim duration
else
    bl.vHolds = [];
    bl.stimOnTime = [];
    bl.stimLength = [];
end

% If iontophoresis was used, save the ionto timing info
if ~isempty(block.trialInfo(1).iontoDuration)
    bl.iontoDuration = block.trialInfo(1).iontoDuration;
elseif ~isempty(block.trialInfo(2).iontoDuration)
    bl.iontoDuration = block.trialInfo(2).iontoDuration;
else
    bl.iontoDuration = [];
end

% Save iontophoresis start and end times
if ~isempty(bl.iontoDuration)
    bl.iontoStartTime = bl.iontoDuration(1);
    bl.iontoLength = bl.iontoDuration(2);
else
    bl.iontoStartTime = [];
    bl.iontoLength = [];
end

% Save recorded data
bl.voltage = block.data.tenVm;             % 2 - 10 Vm voltage traces
bl.current = block.data.current;             % 1 - Preamp-filtered current
bl.scaledOut = block.data.scaledOut;           % 3 - Scaled Output

% PLOT EACH TRIAL VOLTAGE AND CURRENT
f = figInfo; 
f.timeWindow = [];
f.yLims = [];
f.lineWidth = [];
f.cm = winter(bl.nTrials);
[h,j] = traceOverlayPlot(bl, f);
legend off
figure(h);
legend off

% Include odor name in title if block is a single trial
if bl.nTrials == 1
    if ~isempty(bl.trialInfo.odor)
        ax = gca;
        titleStr = ax.Title.String;
        titleStr{2} = ['Trial ', num2str(bl.trialList(1)), ': ', strrep(bl.trialInfo.odor,'_','\_')];
        title(titleStr{2});
    end
end
% legend({'Baseline', 'First Ejection', 'Last Ejection'})
end 
    %% Calculate seal resistance
    bl.Rseal = sealResistanceCalc(bl.scaledOut, bl.voltage)
    
    %% Calculate access resistance
    bl.Raccess = accessResistanceCalc(bl.scaledOut, bl.sampRate)

%% PLOT AVG TRACE OVERLAY
f = figInfo;
f.figDims = [10 200 1000 600];
f.timeWindow = [2 14];
f.lineWidth = 1;
f.yLims = [-55 -30]; 

medfilt = 1;
offset = 0;

% Specify trial groups
traceGroups = repmat([1 2],1,10);%[ones(), 1), 2*ones(), 1)]; %[1:numel(trialList)]; %
% groupColors = [repmat([0 0 1], 2, 1); repmat([0 1 1], 2,1); repmat([1 0 0 ], 2,1) ; repmat([1 0.6 0],2,1)];  %[0 0 1; 1 0 0; 1 0 0; 0 0 0]; % [0 0 1; 1 0 0] %[1 0 0;1 0 1;0 0 1;0 1 0]
groupColors = [0 0 1; 1 0 0];%jet(numel(trialList));
f.figLegend = [{'Ionto', 'Control'}, cell(1, length(unique(traceGroups)))];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);

title([])
% legend('off')
% legend({''; ''}, 'FontSize', 16, 'Location', 'northwest')
ax = gca;
ax.LineWidth = 3;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 18;
ylabel('Vm (mV)');

%% OVERLAY MEAN TRACES FOR EACH ODOR
f = figInfo;
f.yLims = []; 
f.figDims = [10 200 1000 600];
f.timeWindow = [2 15]; 
f.yLims = [-55 -35]; 
f.lineWidth = 1.5;

medfilt = 1;
offset = 0;

valveList = unique([bl.trialInfo.valveID], 'stable');
odors = unique(bl.odors,'stable');

nOdors = length(odors);
traceGroups = zeros(1, nOdors);
for iOdor = valveList;
    traceGroups(strcmp(bl.odors, odors{find(valveList == iOdor)})) = iOdor;
    f.figLegend{iOdor} = strrep(odors{find(valveList == iOdor)},'_','\_');
end
f.figLegend = f.figLegend(~cellfun('isempty',f.figLegend));
groupColors = [0 0 1; 0 .75 0; 1 0 0; 1 .5 0; .85 0 .85]; %jet(nOdors);
[avgTraces, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);                                   
ax = gca;
ax.LineWidth = 3;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 16;

    %% Calculate input resistances
    sR = bl.sampRate;
    Istep = 1;
    calcWin = 0.2;
    stepStart = 1; % Note hardcoded value
    stepLength = 1; % Note hardcoded value
    
    inputResistances = [];
    inputResistances(1,1) = calcRinput(avgTraces(1,:), sR, Istep, stepStart, stepLength, calcWin);
%     inputResistances(2,1) = calcRinput(avgTraces(2,:), sR, Istep, stepStart, stepLength, calcWin);
    stepStart = 9.1;
    stepLength = 0.5;
    inputResistances(1,2) = calcRinput(avgTraces(1,:), sR, Istep, stepStart, stepLength, calcWin);
%     inputResistances(2,2) = calcRinput(avgTraces(2,:), sR, Istep, stepStart, stepLength, calcWin);
    stepStart = 12.5;
    inputResistances(1,3) = calcRinput(avgTraces(1,:), sR, Istep, stepStart, stepLength, calcWin);
%     inputResistances(2,3) = calcRinput(avgTraces(2,:), sR, Istep, stepStart, stepLength, calcWin);

%% OVERLAY MEAN TRACES FOR A SINGLE ODOR ACROSS BLOCKS
f = figInfo;
f.figDims = [10 200 1000 600];
f.timeWindow = [10 14];
f.lineWidth = 1.5;
f.yLims = [-60 -30]; 

medfilt = 1;
offset = 1;

% Specify one group from each block
traceGroups = [];
nBlocks = size(odorBlocks,2);
for iBlock = 1:nBlocks
        traceGroups(end+1:end+numel(odorBlocks{odorNum, iBlock})) = iBlock;
end

groupColors = winter(nBlocks);
f.figLegend = [{'Baseline','High Mg/Ca','Washout','High Mg only'}, cell(1, length(unique(traceGroups)))];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);

title(strrep(odors(odorNum), '_', ' '))
% legend('off')
ax = gca;
ax.LineWidth = 3;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 18;
ylabel('Vm (mV)');

%% GET SPIKE TIMES FROM CURRENT

posThresh = [3 3 2 2]; % Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
invert = 1;
spikes = getSpikesI(bl, posThresh);     % Find spike locations in all trials
bl.spikes = spikes;                     % Save to data structure
bl.normCurrent = bl.current - mean(median(bl.current));

% Look at histogram of peak heights to evaluate choice of threshold
allPks = [];
for iTrial = 1:bl.nTrials
    allPks = [allPks; bl.spikes(iTrial).peakVals];
end
figure(4), hist(allPks,30); title(['n = ', num2str(length(allPks))]);
    
    %% Plot all spikes centered on peak
    figure(6);clf;hold all
    for iTrial = 1:size(bl.spikes, 2)
        locs = bl.spikes(iTrial).locs;
        if ~isempty(locs)
            for iSpk = 1:length(locs)
                plot(bl.normCurrent(locs(iSpk)-(.002*bl.sampRate):locs(iSpk)+(.006*bl.sampRate), iTrial))
            end
        end
    end
    
    %% Plot inverted current trace(s) with a marker on each peak
    h = figure(7);clf;hold on
    f = figInfo;
    f.figDims = [10 50 1650 400];
    f.yLabel = 'Current (pA)';
    
    annotLines = [bl.stimOnTime, bl.stimOnTime + bl.stimLength];
    annotColors = [0,.75,0;.75,0,0];
    if bl.nTrials > 1
        cm = winter(bl.nTrials);
    else
        cm = [0 0 1];
    end
    traceData = bl.normCurrent';
    plotTraces(h, bl, f, -traceData, cm, annotLines, annotColors);
    for iTrial = 1:bl.nTrials
        plot([bl.spikes(iTrial).locs]./bl.sampRate, [bl.spikes(iTrial).peakVals], 'or')
    end
    
%% PLOT SPIKE RASTERS
f = figInfo;
f.timeWindow = [9 14];
f.figDims = [10 50 1500 900];
histOverlay = 1;
nBins = (diff(f.timeWindow)+1)*4;
[h] = odorRasterPlots(bl, f, histOverlay, nBins);
suptitle('');
% tightfig;

%% SAVING FIGURES

tic; t = [];
filename = 'Dec_02_Final_Acetoin_Block';
savefig(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\', filename])
t(1) = toc; tL{1} = 'Local save';
savefig(h, ['U:\Data Backup\Figs\', filename])
t(2) = toc; tL{2} = 'Server save';
f.figDims = [10 550 1650 400];
set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
export_fig(['C:\Users\Wilson Lab\Documents\MATLAB\Figs\PNG files\', filename], '-png')
t(3) = toc; tL{3} = 'Local PNG save';

dispStr = '';
for iToc = 1:length(t)
    dispStr = [dispStr, tL{iToc}, ': ', num2str(t(iToc), 2), '  '];
end
disp(dispStr)

%%
figDims = [10 550 1650 400];
filename = 'May_13_R01_Voltage'
savefig(h, ['C:\Users\Wilson Lab\Desktop\', filename])
set(h,'PaperUnits','inches','PaperPosition',[10 550 figDims(3)/100 figDims(4)/100])
print(h, ['C:\Users\Wilson Lab\Desktop\', filename], '-depsc')

figDims = [10 50 1650 400];
filename = 'May_13_R01_Current'
set(j,'PaperUnits','inches','PaperPosition',[10 50 figDims(3)/100 figDims(4)/100])
print(j, ['C:\Users\Wilson Lab\Desktop\', filename], '-depsc')

%% COMPARE TOTAL SPIKES ACROSS CONDITIONS

timeWin = [bl.trialDuration(1), sum(bl.trialDuration(1:2))];

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

%% Filter current
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
if strcmp(bl.trialInfo(1).scaledOutMode, 'I')
    [pfftV, fValsV] = getFreqContent(bl.voltage(:,1),bl.sampRate);
    [pfftC, fValsC] = getFreqContent(bl.scaledOut(:,1),bl.sampRate);
elseif strcmp(bl.trialInfo(1).scaledOutMode, 'V')
    [pfftV, fValsV] = getFreqContent(bl.scaledOut(:,1),bl.sampRate);
    [pfftC, fValsC] = getFreqContent(bl.current(:,1),bl.sampRate);    
end

% Plot them each on a log scale
figure(1);clf;subplot(211)
plot(fValsV, 10*log10(pfftV));
title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);
ylim([-100 0]);

subplot(212)
plot(fValsV, 10*log10(pfftC));
title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);
ylim([-100 0]);

%% USE A 60+120 HZ FILTER TO REMOVE LINE NOISE
freq = 60;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
    bl.scaledOut(:,iTrial) = notchFilter(bl.scaledOut(:,iTrial), bl.sampRate, freq, bWidth);
end

freq = 120;                                                                                      % Set filter parameters
bWidth = 40;
for iTrial = 1:bl.nTrials
    bl.voltage(:,iTrial) = notchFilter(bl.voltage(:,iTrial),bl.sampRate, freq, bWidth);       % Apply to each trial
    bl.current(:,iTrial) = notchFilter(bl.current(:,iTrial),bl.sampRate, freq, bWidth);
    bl.scaledOut(:,iTrial) = notchFilter(bl.scaledOut(:,iTrial), bl.sampRate, freq, bWidth);
end

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

%% Plot iontophoresis figs for each odor
for iOdor = 1:4
    h = figure(iOdor); clf; hold on
    f = figInfo;
    f.figDims = [10 200 660 400];
    f.timeWindow = [7 13];
    f.lineWidth = 1.5;
    f.yLims = [-55 -25]; 
    
    traceData = [bl.scaledOut(:, 2*iOdor - 1:2*iOdor)]';
    traceColors = [1 0 0; 0 0 1];

    plotTraces(h, bl, f, traceData, traceColors, [], []);
    plot([8 8], [-55 -25], 'Color', 'm', 'linewidth', 2)
    plot([11 12;11 12], [-55 -55; -25 -25], 'Color', 'k', 'linewidth', 2)
    legend({'Iontophoresis'; 'Control'},'Location', 'northwest')
    
    tic; t = [];
    filename = ['May_01_', bl.odors{2*iOdor}];
    savefig(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\', filename])
    t(1) = toc; tL{1} = 'Local save';
    savefig(h, ['U:\Data Backup\Figs\', filename])
    t(2) = toc; tL{2} = 'Server save';
    set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
    print(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\PNG files\', filename], '-dpng') 
    t(3) = toc; tL{3} = 'Local PNG save';
    
end

