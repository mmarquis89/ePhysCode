
%% LOAD EXPERIMENT
disp('Loading experiment...');
expData = loadExperiment('2017-Apr-14', 1);
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

trialList = [69:70];

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

%% BASIC TRACE PLOTTING

% Set parameters
f = figInfo;
f.figDims = [10 300 1900 500];

f.timeWindow = [2 12];
f.yLims = [-60 -10];
f.lineWidth = [1];

f.xLabel = ['Time (s)'];
f.yLabel = ['Voltage (mV)'];
f.title = 'ACV e-2, Power = 100%, Duty cycle = 100% +ND25+ND25+ND50';%['Trial #', num2str(bl.trialList(1)), ' - ', ...
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
f.timeWindow = [2 12];
f.lineWidth = 1;
f.yLims = [-45 -35];

medfilt = 0;
offset = 0;

% Specify trial groups
traceGroups = repmat([1; 2], bl.nTrials/2, 1);%[1 2]; % repmat([1],bl.nTrials, 1);%[ones(), 1), 2*ones(), 1)]; %[1:numel(trialList)]; %
% groupColors = [repmat([0 0 1], 2, 1); repmat([0 1 1], 2,1); repmat([1 0 0 ], 2,1) ; repmat([1 0.6 0],2,1)];  %[0 0 1; 1 0 0; 1 0 0; 0 0 0]; % [0 0 1; 1 0 0] %[1 0 0;1 0 1;0 0 1;0 1 0]
groupColors = [0 0 1; 1 0 0; 0.4 0.4 1; 1 0.4 0.4; 0.7 0.7 1; 1 0.7 0.7];%jet(numel(trialList));
f.figLegend = {'Control', '+LED'}; %[{'Control','Ionto'}, cell(1, length(unique(traceGroups)))];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);


title(['Trial-averaged +TTX — Power = 30%, Duty Cycle = 100%'])
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
f.timeWindow = [5 10];
f.yLims = [-55 -30];
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

posThresh = [1.5 1.5 1.5 1.5]; % Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
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

annotLines = {bl.stimOnTime, bl.stimOnTime + bl.stimLength};
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
f.timeWindow = [6 9];
f.figDims = [10 50 1500 900];
histOverlay = 0;
nBins = (diff(f.timeWindow)+1)*6;
[h] = odorRasterPlots(bl, f, histOverlay, nBins);
suptitle('');
% tightfig;

%% SAVING FIGURES

tic; t = [];
filename = 'Apr_14_LED_Vs_Rinput_Plot';
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
    %% CREATE MOVIES FROM .TIF FILES
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = makeVids(expData, parentDir);
    disp(msg);

    %% CALCULATE OR LOAD MEAN OPTICAL FLOW
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

    %% CREATE COMBINED PLOTTING VIDEOS
    strDate = expData.expInfo(1).date;
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    flowDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']);
    savePath = fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']);

    msg = makePlottingVids(expData, parentDir, flowDir, savePath);
    disp(msg);

    %% CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    msg = concatenateVids(expData, parentDir);
    disp(msg);

    %% ZIP RAW VIDEO FRAMES
    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);

    zipFolders = dir(fullfile(parentDir, '*_T*'));
    zipPaths = strcat([parentDir, '\'], {zipFolders.name});
    disp('Zipping raw video data...');
    zip(fullfile(parentDir,'rawVidData'), zipPaths); 
    disp('Zipping completed');
    
    %% DELETE RAW VIDEO DATA AFTER ARCHIVING

    strDate = expData.expInfo(1).date;
    parentDir = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate);
    delFolders = dir(fullfile(parentDir, '*_T*'));
    disp('Deleting raw video frames...');
    for iFolder = 1:length(delFolders)
         disp(delFolders(iFolder).name);
         rmdir(fullfile(parentDir, delFolders(iFolder).name), 's');
    end
    disp('Raw video frames deleted');

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
title('Apr 05 Exp #1');
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


%% PLOT SPIKE RATE VS. OPTIC FLOW

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
    
    figure(iTrial); clf; hold on
    set(gcf, 'Position', [100 100 1500 400])
    nBins = sum(bl.trialDuration);
    binLength = sum(bl.trialDuration)./nBins;
    
    yyaxis left
    h = histogram(secSpikes, nBins);
    data = [data, h.Values];
    for iBin = 1:nBins
        binnedFlow(iBin) = mean(currFlow((secFlow >=(iBin - 1)*binLength)+(secFlow < iBin*binLength)==2));
    end
    concatFlow = [concatFlow, binnedFlow]; 
    yyaxis right
    plot([0:binLength:sum(bl.trialDuration)-binLength]+binLength/2, binnedFlow); ylim([0 1.5]);
end

figure(1); clf;
plot(concatFlow, data, 'o');



clear all

%% CALCULATE TOTAL DURATION OF EXPERIMENT

startTime = expData.expInfo(1).sampleTime;
endTime = expData.expInfo(end).sampleTime;

expTime = endTime - startTime;
expDur = expTime(4)*60 + expTime(5);
disp(['Total experiment duration in minutes: ', num2str(expDur)])







