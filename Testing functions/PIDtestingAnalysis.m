%% LOAD EXPERIMENT

expDate = '2016-Jun-22';
expNumber = 1;

% Load the master file and add experiment info
load([expDate,'/WCwaveform_',expDate,'_E',num2str(expNumber),'.mat']','data');
expData.expInfo = data;   

% Add the raw data from each trial
for iTrial = 1:length(data)     
    load([expDate,'/Raw_WCwaveform_',expDate,'_E',num2str(expNumber), '_', num2str(iTrial),'.mat']');
    expData.trialData(iTrial).voltage = PID_Out;
end

%% PULL OUT TRIAL BLOCK

bl = [];
% AKM Pinene B: [53:56 49:52 45:48 41:44]
trialList = [61:64 57:60];
nBlocks = 2;

expName = 'Jun-22_PID_';
figTitle = [''];
yL = [-.9 .6];
fd = [10 150 850 800];

% Pulls out data and information about a specified block of trials
block = [];
for iTrial = 1:length(trialList)
    block.data(:,iTrial) = expData.trialData(trialList(iTrial)).voltage;
    block.trialInfo(iTrial) = expData.expInfo(trialList(iTrial));
end    

for iFold = 1 % Just here so I can fold the code below

% Create global variables  
bl.trialInfo = block.trialInfo;
bl.date = block.trialInfo(1).date;
bl.trialList = trialList; 
bl.nTrials = length(block.trialInfo);                                                             % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                      % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                  % Sample duration
bl.time = bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data(:,1));                % Time in seconds of each sample
bl.trialDuration = block.trialInfo(1).trialduration;


% This stuff only applies if an odor was presented
if length(bl.trialDuration) > 1       
    % Save valve timing                                            
    bl.stimOnTime = block.trialInfo(1).trialduration(1);
    bl.stimLength = block.trialInfo(1).trialduration(2);                                               % Stim duration
else
    bl.stimOnTime = [];
    bl.stimLength = [];
end

% Save recorded data
bl.voltage = block.data;             % 2 - 10 Vm voltage traces
end 

% Average and smooth traces from each block
meanV = [];
for iBlock = 1:nBlocks
    meanV(:, iBlock) = smooth(mean(bl.voltage(:,iBlock*4-3:iBlock*4),2),101);
end

% PLOT EACH TRIAL VOLTAGE AND CURRENT
f = figInfo; 
f.timeWindow = [bl.trialDuration(1), sum(bl.trialDuration(1:2))];
f.yLims = yL;
f.lineWidth = 2;
           
% Create colormap                
cm = colormap(winter(nBlocks));
if isempty(cm)
    if nBlocks > 1
                cm = colormap(jet(nBlocks));        
    else
        cm = [0 0 1];
    end
end

% Set shared parameters
traceColors = cm;
annotLines = [bl.stimOnTime, bl.stimOnTime + bl.stimLength];
annotColors = [0,0,0;0,1,0;1,0,0];
f.xLabel = 'Time (sec)';

% Set legend entries
if ~isempty(annotLines)
    f.figLegend = cell(1, nBlocks + numel(annotLines));
    f.figLegend(1:nBlocks) = {'Neat' '10-1'};%{'10^-1', '10^-2', '10^-3', '10^-4'};
end

% Voltage plot
h = figure(1); clf; hold on;
f.figDims = fd; %[10 150 1450 800]; %[10 150 1450 800];
traceData = meanV'; %bl.voltage';
f.title = {[bl.date, '', figTitle], ['']};
f.yLabel = 'Vm (mV)';
plotTraces(h, bl, f, traceData, traceColors, annotLines, annotColors);

%% Save figure
tic; t = [];
filename = [expName, 'AKM_Pinene_HighConc' ]; %figTitles{iFig}];
savefig(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\', filename])
t(1) = toc; tL{1} = 'Local save';
savefig(h, ['U:\Data Backup\Figs\', filename])
t(2) = toc; tL{2} = 'Server save';
set(h,'PaperUnits','inches','PaperPosition',[0 0 f.figDims(3)/100 f.figDims(4)/100])
print(h, ['C:\Users\Wilson Lab\Documents\MATLAB\Figs\PNG files\', filename], '-dpng') 
t(3) = toc; tL{3} = 'Local PNG save';

dispStr = '';
for iToc = 1:length(t)
    dispStr = [dispStr, tL{iToc}, ': ', num2str(t(iToc), 2), '  '];
end
disp(dispStr)
