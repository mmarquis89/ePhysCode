
%% LOAD EXPERIMENT

expData = loadExperiment('2017-Mar-11', 1);

% Start background process to backup all data that is at least a day old
backupLogTransfer();

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

trialList = [16:31 33:40];

block = getTrials(expData, trialList);  % Save trial data and info as "block"
if ~isempty(block)
    bl = makeBl(block, trialList);  % Reformat into more usable structure
       
    % PLOT EACH TRIAL VOLTAGE AND CURRENT
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
    % legend({'Baseline', 'First Ejection', 'Last Ejection'})
end
end

%% Estimate seal resistance
bl.Rseal = sealResistanceCalc(bl.scaledOut, bl.voltage)

%% Estimate access resistance
bl.Raccess = accessResistanceCalc(bl.scaledOut, bl.sampRate)

%% BASIC TRACE PLOTTING

% Set parameters
f = figInfo;
f.figDims = [10 300 1900 500];

f.timeWindow = [4 11];
f.yLims = [-65  -45];
f.lineWidth = [1];

f.xLabel = ['Time (s)'];
f.yLabel = ['Voltage (mV)'];
f.title = ['Trial #', num2str(bl.trialList(1)), ' - ', ...
                regexprep(bl.trialInfo(1).odor, '_e(?<num>..)', '\\_e^{$<num>}')]; %['#' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end)) '\_' ...
%regexprep(bl.trialInfo(1).odor, '_e(?<num>..)', '\\_e^{$<num>}')];
f.figLegend = {};

traceData = [bl.scaledOut']; % rows are traces
traceColors = [0,0,1;1,0,0]; % n x 3 RGB array

annotLines = {[bl.stimOnTime, bl.stimOnTime+bl.stimLength]}; % cell array of xLocs for annotation lines
annotColors = [0,0,0]; % m x 3 RGB array for each annotation line

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
f.timeWindow = [7 12];
f.lineWidth = 1;
f.yLims = [-45 -40];

medfilt = 1;
offset = 0;

% Specify trial groups
traceGroups = repmat([1],bl.nTrials, 1);%[ones(), 1), 2*ones(), 1)]; %[1:numel(trialList)]; %
% groupColors = [repmat([0 0 1], 2, 1); repmat([0 1 1], 2,1); repmat([1 0 0 ], 2,1) ; repmat([1 0.6 0],2,1)];  %[0 0 1; 1 0 0; 1 0 0; 0 0 0]; % [0 0 1; 1 0 0] %[1 0 0;1 0 1;0 0 1;0 1 0]
groupColors = [0 0 1; 1 0 0];%jet(numel(trialList));
f.figLegend = []; %[{'Control','Ionto'}, cell(1, length(unique(traceGroups)))];
[~, h] = avgTraceOverlay(bl, f, traceGroups, groupColors, medfilt, offset);

title([])
% legend('off')
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
f.timeWindow = [4 11];
f.yLims = [-65 -45];
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

posThresh = [2 2 2 2]; % Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
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
f.timeWindow = [5 10];
f.figDims = [10 50 1500 900];
histOverlay = 1;
nBins = (diff(f.timeWindow)+1)*4;
[h] = odorRasterPlots(bl, f, histOverlay, nBins);
suptitle('');
% tightfig;

%% SAVING FIGURES

tic; t = [];
filename = 'Mar_09_Rasters';
savefig(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\', filename])
t(1) = toc; tL{1} = 'Local save';
savefig(h, ['U:\Data Backup\Figs\', filename])
t(2) = toc; tL{2} = 'Server save';
if exist('f', 'var')
    set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
else
    set(h,'PaperUnits','inches')
end
export_fig(['C:\Users\Wilson Lab\Documents\MATLAB\Figs\PNG files\', filename], '-png')
t(3) = toc; tL{3} = 'Local PNG save';

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


%% Filter current
[b,a] = butter(2,.004,'low');
D = designfilt('lowpassiir', ...
    'PassbandFrequency', 15, ...
    'StopbandFrequency', 100, ...
    'StopbandAttenuation', 100, ...
    'SampleRate', 10000);
fvtool(D)
bl.voltage(:,1) = filtfilt(b,a, bl.current(:,1));

%% CREATE MOVIES FROM .TIF FILES

strDate = expData.expInfo(1).date;
nTrials = length(expData.expInfo);
        
for iTrial = 1:nTrials
    % Get name of current trial
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];   
    disp(trialStr)
    savePath = fullfile('C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies', strDate, trialStr);
    currFiles = dir(fullfile(savePath, '*.tif'));
    
    if ~isempty(currFiles) && isempty(dir(fullfile(savePath, '*.avi'))) % Make sure there's at least one image file and no .avi file already in this trial's directory
        currFrames = {currFiles.name}';
        
        % Create video writer object
        outputVid = VideoWriter([fullfile(savePath, [trialStr, '.avi'])]);
        outputVid.FrameRate = expData.expInfo(1).acqSettings.frameRate;
        open(outputVid)
        
        % Write each .tif file to video
        for iFrame = 1:length(currFrames)
            currImg = imread(fullfile(savePath, currFrames{iFrame}));
            writeVideo(outputVid, currImg);
        end
        close(outputVid)
    end   
end

% CALCULATE OR LOAD MEAN OPTICAL FLOW

nTrials = length(expData.expInfo);
strDate = expData.expInfo(1).date;
parentDir = 'C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies';
allFlow = cell(nTrials, 1);

if isempty(dir(fullfile('C:\Users\Wilson Lab\Documents\MATLAB\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat'])))
    for iTrial = 1:nTrials
        % Get trial name
        trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
        disp(trialStr)
        
        if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
            
            % Load movie for the current trial
            myMovie = [];
            myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
            while hasFrame(myVid)
                currFrame = readFrame(myVid);
                myMovie(:,:,end+1) = rgb2gray(currFrame);
            end
            myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
            
            % Calculate mean optical flow magnitude across frames for each trial
            opticFlow = opticalFlowFarneback;
            currFlow = []; flowMag = zeros(size(myMovie, 3),1);
            for iFrame = 1:size(myMovie, 3)
                currFlow = estimateFlow(opticFlow, myMovie(:,:,iFrame));
                flowMag(iFrame) = mean(mean(currFlow.Magnitude));
            end
            allFlow{iTrial} = flowMag;
        end
    end
    
    % Save data to disk for future use
    save(fullfile('C:\Users\Wilson Lab\Documents\MATLAB\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
    try
        save(fullfile('U:\Data Backup', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
    catch
        disp('Warning: server backup folder does not exist. Skipping server backup save.')
    end
else
    load(fullfile('C:\Users\Wilson Lab\Documents\MATLAB\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
end

% CREATE COMBINED PLOTTING VIDEOS

frameRate = expData.expInfo(1).acqSettings.frameRate;
for iTrial = 1:length(expData.expInfo);
        
    parentDir = 'C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies';
    strDate = expData.expInfo(1).date;
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = [];
        myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(:,:,end+1) = rgb2gray(currFrame);
        end
        myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
        
        % Load trial data
        currVm = expData.trialData(iTrial).scaledOut;
        trialDuration = sum(expData.expInfo(iTrial).trialduration);
        
        % Load optic flow data
        load(fullfile('C:\Users\Wilson Lab\Documents\MATLAB\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
        
        % Create save directory and open video writer
        if ~isdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']))
            mkdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']));
        end
        myVid = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], [trialStr, '_With_Plots.avi']));
        myVid.FrameRate = frameRate;
        open(myVid)
        
        % Make temporary block structure to get plotting data from
        blTemp = makeBl(getTrials(expData, iTrial), iTrial);
        if ~isempty(blTemp.odors{1})
            annotLines = {[blTemp.stimOnTime, blTemp.stimOnTime+blTemp.stimLength]};
        else
            annotLines = {};
        end
        
        % Create and save each frame
        for iFrame = 1:size(myMovie, 3)
            
            currFrame = myMovie(:,:,iFrame);
            
            % Create figure
            h = figure(10); clf
            set(h, 'Position', [50 100 1800 700])
            
            % Movie frame plot
            axes('Units', 'Pixels', 'Position', [50 225 300 300])
            imshow(currFrame)
            axis image
            axis off
            if ~isempty(annotLines)
                title({strrep(blTemp.odors{1}, '_', '\_'), '',['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            else
                title({['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            end
            
            % Vm plot
            ax = axes('Units', 'Pixels', 'Position', [425 380 1330 300]);
            hold on
            fTemp = figInfo;
            yRange = max(currVm) - min(currVm);
            fTemp.yLims = [min(currVm)-0.1*yRange, max(currVm)+0.2*yRange] 
            plotTraces(ax, blTemp, fTemp, currVm', [0 0 1], annotLines, [0 0 0])         
%             t = (1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein)*length(currVm);
%             plot(t, currVm)
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],[ylim()], 'LineWidth', 1, 'color', 'r')
            xlabel('Time (sec)');
            ylabel('Vm (mV)');
            
            % Optic flow plot
            axes('Units', 'Pixels', 'Position', [425 20 1330 300])
            hold on
            frameTimes = (1:1:length(allFlow{iTrial}))./ frameRate;
            ylim([0, 1.5]);
            plot(frameTimes(2:end), allFlow{iTrial}(2:end))
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],[ylim()],'LineWidth', 1, 'color', 'r')
            % set(gca,'ytick',[])
            set(gca,'xticklabel',[])
            ylabel('Optic flow (au)')
            
            % Write frame to video
            writeFrame = getframe(h);
            writeVideo(myVid, writeFrame)
        end
        close(myVid)
    end
end

% CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT

parentDir = 'C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies';
strDate = expData.expInfo(1).date;
frameRate = expData.expInfo(1).acqSettings.frameRate;
nTrials = length(expData.expInfo);

% Create videowriter 
myVidWriter = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], ['E', num2str(expData.expInfo(1).expNum),'_AllTrials.avi']));
myVidWriter.FrameRate = frameRate;
open(myVidWriter)

for iTrial = 1:nTrials
    
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = {};
        myVid = VideoReader(fullfile(parentDir, strDate,['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'] ,[trialStr '_With_Plots.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(end+1) = {uint8(currFrame)};
        end
        
        % Add frames to movie
        for iFrame = 1:length(myMovie)
            writeVideo(myVidWriter, myMovie{iFrame});
        end
    end
end
close(myVidWriter)
clear('myMovie')


%% PLOT SPIKE RATE VS. OPTIC FLOW

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
    nBins = sum(bl.trialDuration)*.5;
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




