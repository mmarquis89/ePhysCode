
%% LOAD EXPERIMENT
disp('Loading experiment...');
expData = loadExperiment('2017-Jun-05', 3);
disp('Experiment loaded');

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

trialList = [34:41];%allTrials(optoControl)% & ch4Trials)

block = getTrials(expData, trialList);  % Save trial data and info as "block"
plotOn = 1;
if ~isempty(block)
    bl = makeBl(block, trialList);  % Reformat into more usable structure

    if plotOn
  %     PLOT EACH TRIAL VOLTAGE AND CURRENT
        f = figInfo;
        f.figDims = [10 550 1850 400];
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
    end
end
disp(['Estimated Rpipette = ', num2str(bl.Rpipette)])

    %% Estimate seal resistance
    bl.Rseal = sealResistanceCalc(bl.scaledOut, bl.voltage);
    disp(['Estimated Rseal = ', num2str(bl.Rseal)])
    %% Estimate access resistance
    bl.Raccess = accessResistanceCalc(bl.scaledOut, bl.sampRate);
    disp(['Estimated Raccess = ', num2str(bl.Raccess)])
    %% Calculate total duration of experiment
    startTime = expData.expInfo(1).sampleTime;
    endTime = expData.expInfo(end).sampleTime;

    expTime = endTime - startTime;
    expDur = expTime(4)*60 + expTime(5);
    disp(['Total experiment duration in minutes: ', num2str(expDur)])
    %% Calculate median input resistance throughout experiment
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data';
    expName = [expData.expInfo(1).date, '_E', num2str(expData.expInfo(1).expNum)];
    load(fullfile(parentDir, expName(1:end-3), [expName, '_Rinputs']));
    disp(['Median Rinput throughout experiment:  ', num2str(median(Rins))]); 
%% BASIC TRACE PLOTTING

% Set parameters
f = figInfo;
f.figDims = [10 300 1900 500];

f.timeWindow = [2 12];
f.yLims = [-70 -25];
f.lineWidth = [1];

f.xLabel = ['Time (s)'];
f.yLabel = ['Voltage (mV)'];
f.title = 'ACV e-2, Power = 5%, Duty cycle = 100%  +ND25+ND25+ND50';%['Trial #', num2str(bl.trialList(1)), ' - ', ...
%                 regexprep(bl.trialInfo(1).odor, '_e(?<num>..)', '\\_e^{$<num>}')]; %['#' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end)) '\_' ...
%regexprep(bl.trialInfo(1).odor, '_e(?<num>..)', '\\_e^{$<num>}')];
f.figLegend = {'Control', '+LED'};

traceData = [bl.scaledOut']; % rows are traces
traceColors = repmat([0,0,1;1,0,0], bl.nTrials/2, 1); % n x 3 RGB array

annotLines = {[bl.stimOnTime, bl.stimOnTime+bl.stimLength], bl.altStimStartTime, bl.altStimStartTime+bl.altStimLength}; % cell array of xLocs for annotation lines
annotColors = [0,0,0;1 0 1;1 0 1]; % m x 3 RGB array for each annotation line

% Plot traces
h = figure(1); clf; hold on;
h = plotTraces(h, bl, f, traceData, traceColors, annotLines, annotColors);
set(gca,'LooseInset',get(gca,'TightInset'))

% Format figure
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 16;

%% PLOT AVG TRACE OVERLAY
f = figInfo;
f.figDims = [10 300 1900 500];
f.timeWindow = [4 12];
f.lineWidth = 1.5;
f.yLims = [];

medfilt = 0;
offset = 0;

% Specify trial groups
traceGroups = repmat([1;1], bl.nTrials/2, 1);%[1 2]; % repmat([1],bl.nTrials, 1);%[ones(), 1), 2*ones(), 1)]; %[1:numel(trialList)]; %
% groupColors = [repmat([0 0 1], 2, 1); repmat([0 1 1], 2,1); repmat([1 0 0 ], 2,1) ; repmat([1 0.6 0],2,1)];  %[0 0 1; 1 0 0; 1 0 0; 0 0 0]; % [0 0 1; 1 0 0] %[1 0 0;1 0 1;0 0 1;0 1 0]
groupColors = [0 0 1; 1 0 0; 0.4 0.4 1; 1 0.4 0.4; 0.7 0.7 1; 1 0.7 0.7];%jet(numel(trialList));
f.figLegend = {'Control', '+LED'}; %[{'Control','Ionto'}, cell(1, length(unique(traceGroups)))];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);


odorName = strrep(bl.trialInfo(1).odor,'_','\_');
% title([odorName, '   -  LED power = 5%, DC = 1%'])
title('Avg of all odors, LED on second trial +7 uM TTX  -  LED power = 5%, DC = 1%');
% legend('off')
[~,objh,~,~] = legend(f.figLegend,'Location','Northeast', 'fontsize',22);
set(objh, 'linewidth', 4);
% legend({''; ''}, 'FontSize', 16, 'Location', 'northwest')
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 18;
ylabel('Vm (mV)');

%% OVERLAY MEAN TRACES FOR EACH ODOR
f = figInfo;
f.yLims = [];
f.figDims = [10 200 1000 600];
f.timeWindow = [5.5 10];
f.yLims = [];
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
groupColors = [0 0 1; 0 .75 0; 1 0 0; 1 .5 0; .85 0 .85; .5 0 .5; 1 .5, 0]; %jet(nOdors);
[avgTraces, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);
ax = gca;
ax.LineWidth = 3;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 16;


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

posThresh = 7; %[1.5 1.5 1.5 1.5]; % Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
invert = 1;
% spikes = getSpikesI(bl, posThresh);     % Find spike locations in all trials
spikes = getSpikesSimple(bl, posThresh(1), invert); % Use simple spike detection if spikes are very large

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
    if ~isempty(locs)'
        for iSpk = 1:length(locs)
            if locs(iSpk) > .002*bl.sampRate && locs(iSpk) < bl.sampRate*(sum(bl.trialDuration)-.006)
                plot(bl.normCurrent(locs(iSpk)-(.002*bl.sampRate):locs(iSpk)+(.006*bl.sampRate), iTrial))
            end
        end
    end
end

%% Plot current trace(s) with a marker on each peak
h = figure(7);clf;hold on
f = figInfo;
f.figDims = [10 50 1650 400];
f.yLabel = 'Current (pA)';

annotLines = {bl.stimOnTime, bl.stimOnTime + bl.stimLength};
annotColors = [0,.75,0;.75,0,0];
if bl.nTrials > 1
    cm = winter(bl.nTrials);
else
    cm = [0 0 1];
end
if invert
    traceData = -bl.normCurrent';
    disp('invert')
else
    traceData = bl.normCurrent';
    disp('No invert');
end
plotTraces(h, bl, f, traceData, cm, annotLines, annotColors);
for iTrial = 1:bl.nTrials
    plot([bl.spikes(iTrial).locs]./bl.sampRate, [bl.spikes(iTrial).peakVals], 'or')
end

%% PLOT SPIKE RASTERS FOR EACH ODOR
f = figInfo;
f.timeWindow = [5 12];
f.figDims = [10 50 1500 900];
histOverlay = 0;
nBins = (diff(f.timeWindow)+1)*3;
[h] = odorRasterPlots(bl, f, histOverlay, nBins);
suptitle('');
% tightfig;

%% PLOT RASTERS W/ARBITRARY GROUPING

f = figInfo;
f.timeWindow = [7 8];
f.figDims = [10 50 1500 900];
histOverlay = 1;
nBins = (diff(f.timeWindow)+1)*30;

rasterGroups = repmat([1; 2], bl.nTrials/2, 1);
groupNames = {'Control', '+ LED'};
[h] = groupedRasterPlots(bl, f, histOverlay, nBins, rasterGroups, groupNames);
suptitle('Farnesol');

%% COUNT AVG SPIKES IN A TIME WINDOW W/ARBITRARY GROUPING
timeWindow = [7 9];
sampWin = timeWindow * bl.sampRate;
groups = repmat([1; 2], bl.nTrials/2, 1);
spikeLocs = {bl.spikes.locs};

% Separate out spikes in specified time window
windowSpikes = [];
for iTrial = 1:length(spikeLocs)
   windowSpikes{iTrial} = spikeLocs{iTrial} > sampWin(1) & spikeLocs{iTrial} < sampWin(2);
end
winSpikeCounts = cellfun(@sum, windowSpikes);

% Separate spike counts for each group
meanSpikes = [];
for iGroup = 1:length(unique(groups))
    meanSpikes(iGroup) = mean(winSpikeCounts(groups==iGroup))
end

%% SAVING FIGURES

tic; t = [];
filename = 'Jun_05_Exp_2_Averaged_Odor_Responses';
savefig(h, ['C:\Users\Wilson Lab\Dropbox (HMS)\Figs\', filename])
t(1) = toc; tL{1} = 'Local save';
if exist('f', 'var')
    set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
else
    set(h,'PaperUnits','inches')
end
export_fig(['C:\Users\Wilson Lab\Dropbox (HMS)\Figs\PNG files\', filename], '-png');
t(2) = toc; tL{2} = 'Local PNG save';
dispStr = '';
for iToc = 1:length(t)
    dispStr = [dispStr, tL{iToc}, ': ', num2str(t(iToc), 2), '  '];
end
disp(dispStr)


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

%% VIDEO PROCESSING
    % CREATE MOVIES FROM .TIF FILES
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = makeVids(expData, parentDir);
    disp(msg);

    % CALCULATE OR LOAD MEAN OPTICAL FLOW
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    savePath = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);

    if isempty(dir(savePath))
        disp('Calculating optic flow...')
        allFlow = opticFlowCalc(expData, parentDir, savePath);
        disp('Optic flow calculated successfully')
    else
        disp('Loading optic flow...')
        load(savePath);
        disp('Optic flow data loaded')
    end
    
    % CREATE COMBINED PLOTTING VIDEOS
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    flowDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);
    savePath = fullfile(parentDir, 'Combined videos', strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']);

    msg = makePlottingVids(expData, parentDir, flowDir, savePath);
    disp(msg);

   % CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = concatenateVids(expData, parentDir);
    disp(msg);

    % ZIP RAW VIDEO FRAMES
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

    zipFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipPaths = strcat([parentDir, '\'], {zipFolders.name});
    disp('Zipping raw video data...');
    zip(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum)]), zipPaths); 
    disp('Zipping completed');
    
    % DELETE RAW VIDEO DATA AFTER ARCHIVING
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);
    delFolders = dir(fullfile(parentDir, ['*', num2str(expData.expInfo(1).expNum), '_T*']));
    zipDir = dir(fullfile(parentDir,['rawVidData_E', num2str(expData.expInfo(1).expNum), '.zip']));
    if isempty(zipDir)
        disp('Error — no zipped folder was found for this experiment');
    else
        disp('Deleting raw video frames...');
        for iFolder = 1:length(delFolders)
            disp(delFolders(iFolder).name);
            rmdir(fullfile(parentDir, delFolders(iFolder).name), 's');
        end
        disp('Raw video frames deleted');  
    end%if

%% PLOT Vm VS. OPTIC FLOW ACROSS TRIALS

% Load parameters
strDate = expData.expInfo(1).date;
rate = bl.sampRate;
stepStart = bl.trialInfo(1).stepStartTime;
stepLen = bl.trialInfo(1).stepLength;
trialDuration = bl.trialInfo(1).trialduration;

% Load optic flow data
load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');

% Separate out optic flow data from the current block
blFlow = allFlow(trialList);

avgVm = [];
avgFlow = [];
for iTrial = 1:bl.nTrials
    
    % Compute mean Vm for the trial, excluding the test step and odor response period
    preStep = 1:rate*stepStart;
    preOdor = rate*(stepStart+stepLen):rate*trialDuration(1);
    postOdor = rate*(sum(trialDuration(1:2))+1):rate*sum(trialDuration);
    avgTimes = [preStep, preOdor, postOdor];
    avgVm(iTrial) = mean(bl.scaledOut([avgTimes], iTrial));
    
    % Compute mean optic flow for the trial from the same time periods
    rate = bl.trialInfo(1).acqSettings.frameRate;
    preStep = 1:rate*stepStart;
    preOdor = rate*(stepStart+stepLen):rate*trialDuration(1);
    postOdor = rate*(sum(trialDuration(1:2))+1):rate*sum(trialDuration);
    avgTimes = [preStep, preOdor, postOdor];    
    avgFlow(iTrial) = mean(blFlow{iTrial}(avgTimes));
end

% Make scatterplot
cm = winter(bl.nTrials);
h = figure(1); clf;
scatter(avgVm, avgFlow, [], cm, 'o', 'filled');
xlabel('Average Vm (mV)');
ylabel('Average optic flow (AU)');
title('DA #1 + DA #2');

% Format figure
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 12;
set(gcf, 'Color', [1 1 1]);

%% PLOT Vm VS. OPTIC FLOW FOR EACH VIDEO FRAME

% Load parameters
strDate = expData.expInfo(1).date;
sR = bl.sampRate;
fR = bl.trialInfo(1).acqSettings.frameRate;
stepStart = bl.trialInfo(1).stepStartTime;
stepLen = bl.trialInfo(1).stepLength;
trialDuration = bl.trialInfo(1).trialduration;

% Load optic flow data
load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');

% Separate out optic flow data from the current block
blFlow = allFlow(trialList);

plotVm = [];
plotFlow = [];
for iTrial = 1:bl.nTrials
    
    % Load optic flow data for current trial
    currFlow = blFlow{iTrial};
    
    % Compute mean Vm for each frame of video
    currVm = [];
    for iFrame = 1:length(currFlow)
        sampPerFrame = sR/fR;
        sampStart = (floor((iFrame-1)*sampPerFrame))+1;
        sampEnd = floor(iFrame*sampPerFrame);
        currVm(iFrame) = mean(bl.scaledOut(sampStart:sampEnd, iTrial));
        end
    
    % Remove frames from the test step and odor response period and add to plotting data
    preStep = 2:fR*stepStart; % Starting at 2 because the first optic flow measurement is invalid
    preOdor = fR*(stepStart+stepLen):fR*trialDuration(1);
    postOdor = fR*(sum(trialDuration(1:2))+1):fR*sum(trialDuration);
    goodFrames = [preStep, preOdor, postOdor]';
    plotVm = [plotVm; currVm(goodFrames)'];
    plotFlow = [plotFlow; blFlow{iTrial}(goodFrames)];
    
end

% Make scatter plot of all datapoints
cm = winter(numel(plotVm));
h = figure(1); clf;
scatter(plotVm, plotFlow, [20], cm, 'filled');
xlabel('Average Vm (mV)');
ylabel('Average optic flow (AU)');
title('TH-Gal4 Feb 20 Exp 2');

% Format figure
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 12;
set(gcf, 'Color', [1 1 1]);
set(gcf, 'Position', [100 100 1000 800])

%% PLOT 2D HISTOGRAM OF Vm VS. OPTIC FLOW FOR EACH FRAME

% Load parameters
strDate = expData.expInfo(1).date;
sR = bl.sampRate;
fR = bl.trialInfo(1).acqSettings.frameRate;
stepStart = bl.trialInfo(1).stepStartTime;
stepLen = bl.trialInfo(1).stepLength;
trialDuration = bl.trialInfo(1).trialduration;

% Load optic flow data
load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');

% Separate out optic flow data from the current block
blFlow = allFlow(trialList);

plotVm = [];
plotFlow = [];
for iTrial = 1:bl.nTrials
    
    % Load optic flow data for current trial
    currFlow = blFlow{iTrial};
    
    % Compute mean Vm for each frame of video
    currVm = [];
    for iFrame = 1:length(currFlow)
        sampPerFrame = sR/fR;
        sampStart = (floor((iFrame-1)*sampPerFrame))+1;
        sampEnd = floor(iFrame*sampPerFrame);
        currVm(iFrame) = mean(bl.scaledOut(sampStart:sampEnd, iTrial));
    end
    
    % Remove frames from the test step and odor response period and add to plotting data
    preStep = 2:fR*stepStart; % Starting at 2 because the first optic flow measurement is invalid
    preOdor = fR*(stepStart+stepLen):fR*trialDuration(1);
    postOdor = fR*(sum(trialDuration(1:2))+1):fR*sum(trialDuration);
    goodFrames = [preStep, preOdor, postOdor]';
    plotVm = [plotVm; currVm(goodFrames)'];
    plotFlow = [plotFlow; blFlow{iTrial}(goodFrames)];
    
end

% Make 2D histogram
histData = [plotVm, plotFlow];
nBins = 100;
[N,C] = hist3(histData, [nBins, nBins]);
myHist = N';
myHist(size(N,1) + 1, size(N,2) + 1) = 0; % Pad edges w/zeros to for pcolor() plotting
xBins = linspace(min(histData(:,1)*0.99),max(histData(:,1)*1.01),size(N,1)+1);
yBins = linspace(min(histData(:,2)*0.99),max(histData(:,2)*1.01),size(N,1)+1);

% Plot pseudocolor image of histogram data
close all; h = figure(1); clf;
sf = pcolor(xBins,yBins,myHist);
xlabel('Average Vm (mV)');
ylabel('Average optic flow (AU)');
title('');
colormap([1,1,1 ; parula(max(max(myHist)))]);
% Format figure
sf.EdgeColor = 'none';
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 12;
set(gcf, 'Color', [1 1 1]);
set(gcf, 'Position', [50 50 900 800])

%% PLOT 2D HISTOGRAM OF SPIKE RATE VS. OPTIC FLOW FOR CURRENT TRIAL BLOCK

% Load parameters
strDate = expData.expInfo(1).date;
sR = bl.sampRate;
fR = bl.trialInfo(1).acqSettings.frameRate;
stepStart = bl.trialInfo(1).stepStartTime;
stepLen = bl.trialInfo(1).stepLength;
trialDuration = bl.trialInfo(1).trialduration;
nBins = sum(trialDuration)*2.5;
binLength = sum(bl.trialDuration)./nBins;

% Load optic flow data
load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');

% Separate out optic flow data from the current block
blFlow = allFlow(trialList);

plotSpikes = [];
plotFlow = [];
for iTrial = 1:bl.nTrials
    
    % Load spikes and optic flow for the current trial
    currSpikes = bl.spikes(iTrial).locs;
    currFlow = blFlow{iTrial};

    % Convert spikes to seconds and calculate time points for optic flow
    secSpikes = currSpikes ./ bl.sampRate;
    secFlow = (1:length(currFlow)) * (1/bl.frameRate);
        
    % Remove flow data from the test step and odor response period
    stepFrames = secFlow > stepStart & secFlow < (stepStart + stepLen);
    odorFrames = secFlow > trialDuration(1) & secFlow < sum(trialDuration(1:2));
    rmFrames = logical(stepSpikes+odorSpikes);
    currFlow(rmFrames) = [];
    secFlow(rmFrames) = [];
    
    % Remove spikes from the test step and odor response period
    stepSpikes = secSpikes > stepStart & secSpikes < (stepStart+stepLen);
    odorSpikes = secSpikes > trialDuration(1) & secSpikes < sum(trialDuration(1:2));
    rmSpikes = logical(stepSpikes+odorSpikes);
    secSpikes(rmSpikes) = [];
    
    % Calculate spike rate within the specified bins
    hst = histogram(secSpikes, nBins);
    histSpikes = hst.Values;
    binEdges = hst.BinEdges;
    lowerEdges = hst.BinEdges(1:end-1);
    upperEdges = hst.BinEdges(2:end);
    
    % Calculate mean optic flow within the bins
    histFlow = zeros(1,nBins);
    for iBin = 1:nBins
       histFlow(iBin) = mean(currFlow(secFlow>binEdges(iBin) & secFlow < binEdges(iBin+1))); 
    end
    
    
    stepBins = upperEdges > stepStart & lowerEdges < (stepStart+stepLen);
    odorBins = upperEdges > trialDuration(1) & lowerEdges < sum(trialDuration(1:2));
    rmBins = logical(stepBins+odorBins);
    histSpikes(rmBins) = [];
    histFlow(rmBins) = [];
    
    % Add new points to plotting data
    plotSpikes = [plotSpikes; histSpikes'];
    plotFlow = [plotFlow; histFlow'];

end%for


% Make 2D histogram
histData = [plotSpikes, plotFlow];
nBins = 10;
[N,C] = hist3(histData, [nBins, nBins]);
myHist = N';
myHist(size(N,1) + 1, size(N,2) + 1) = 0; % Pad edges w/zeros to for pcolor() plotting
xBins = linspace(min(histData(:,1)*0.99),max(histData(:,1)*1.01),size(N,1)+1);
yBins = linspace(min(histData(:,2)*0.99),max(histData(:,2)*1.01),size(N,1)+1);

limit = mean(myHist(:))*1.5
myHist(myHist>limit) = limit;

% Plot pseudocolor image of histogram data
close all; h = figure(1); clf;
sf = pcolor(xBins,yBins,myHist);
xlabel('Spike Rate (AU)');
ylabel('Average optic flow (AU)');
title('Feb 20, Exp 1');
colormap([1,1,1 ; parula(max(max(myHist)))]);

% Format figure
sf.EdgeColor = 'none';
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 12;
set(gcf, 'Color', [1 1 1]);
set(gcf, 'Position', [50 50 900 800])

%% PLOT SPIKE RATE VS. OPTIC FLOW FOR CURRENT TRIAL BLOCK

strDate = expData.expInfo(1).date;

% Load optic flow data
load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');

% Separate out optic flow data from the current block
blFlow = allFlow(trialList);
data = [];
concatFlow = [];
binnedFlow = [];
for iTrial = 1:bl.nTrials
    currSpikes = bl.spikes(iTrial).locs;
    currFlow = blFlow{iTrial};
    
    % Convert spikes to seconds and calculate time points for optic flow
    secSpikes = currSpikes ./ bl.sampRate;
    secFlow = (1:length(currFlow)) * (1/bl.frameRate);
    
%     figure(iTrial); clf; hold on
%     set(gcf, 'Position', [100 100 1500 400])
    nBins = sum(bl.trialDuration);
    binLength = sum(bl.trialDuration)./nBins;
    
%     yyaxis left
    h = histogram(secSpikes, nBins);
    data = [data, h.Values];
    for iBin = 1:nBins
        binnedFlow(iBin) = mean(currFlow((secFlow >=(iBin - 1)*binLength)+(secFlow < iBin*binLength)==2));
    end
    concatFlow = [concatFlow, binnedFlow]; 
%     yyaxis right
%     plot([0:binLength:sum(bl.trialDuration)-binLength]+binLength/2, binnedFlow); ylim([0 1.5]);
end

figure(1); clf;
plot(concatFlow, data, 'o');

%% BREAK OPTO TRIALS DOWN BY ODOR
odorData = {expData.expInfo.odor};
altStimData = {expData.expInfo.altStimDuration};
nTrials = length(odorData);

optoTrials = cellfun(@isequal, altStimData, repmat({[6 3 6]}, 1, nTrials));
controlTrials =  [optoTrials(2:end), 0]%[0,optoTrials(1:end-1)];%;%%%
ch1Trials = cellfun(@strcmp, odorData, repmat({['EthylAcetate_e-6']}, 1, nTrials));
ch2Trials = cellfun(@strcmp, odorData, repmat({['cVA_e-5']}, 1, nTrials));
ch3Trials = cellfun(@strcmp, odorData, repmat({['IsobutyricAcid_e-6']}, 1, nTrials));
ch4Trials = cellfun(@strcmp, odorData, repmat({['ParaffinOil']}, 1, nTrials));

optoControl = optoTrials | controlTrials;
optoControl([1:69]) = 0;




% First removed: [24:31 40:47 56:63 72:79]
% Second removed: [16:23 32:39 48:55 64:71]

% TTX first removed: [88:95 104:111]
% TTX second removed: [80:87 96:103]

allTrials = 1:length(expData.expInfo);

    %% Plot Rinputs vs. LED duty cycle
h = figure(1); clf
Rinputs = [bl.trialInfo.Rin];
LEDpowers = [1:4, 10 25 50 100];
plot(LEDpowers, Rinputs, '.', 'MarkerSize', 40);

title('Power = 5%, +ND25+ND25+ND50');
xlabel('LED duty cycle');
ylabel('Input resistance (GOhm)');

set(gcf, 'Color', [1 1 1]);
% Format figure
ax = gca;
ax.LineWidth = 2;
ax.XColor = 'k';
ax.YColor = 'k';
ax.FontSize = 16;
