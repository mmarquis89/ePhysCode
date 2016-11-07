%% LOAD EXPERIMENT

expDate = '2016-Jun-23';
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
trialList = [13:16];

expName = 'Jun-23_PID_';
figTitle = [''];
yL = [-.9 -.4];
fd = [10 150 850 800];

rotationMode = 0; % If true, colors traces by inlet location rather than channel/vial number
blockNum =[1];

% for iBlock = 1:length(blockNum)
%     trialList = [trialList, 8*blockNum(iBlock)-7:8*blockNum(iBlock)];
% end

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
    bl.pinchOpen = block.trialInfo(1).trialduration(1);                                                % Pre-stim time (sec)
    bl.stimOnTime = block.trialInfo(1).trialduration(1) + block.trialInfo(1).trialduration(2);
    bl.stimLength = block.trialInfo(1).trialduration(3);                                               % Stim duration
else
    bl.pinchOpen = [];
    bl.stimOnTime = [];
    bl.stimLength = [];
end

% Save recorded data
bl.voltage = block.data;             % 2 - 10 Vm voltage traces
end 

% Average traces together
meanV = mean(bl.voltage, 2);

% Smooth traces
meanV = smooth(meanV, 101);
% for iTrial = 1:bl.nTrials
%     bl.voltage(:,iTrial) = smooth(bl.voltage(:,iTrial), 101);
% end

% PLOT EACH TRIAL VOLTAGE AND CURRENT
f = figInfo; 
f.timeWindow = [sum(bl.trialDuration(1:2)), sum(bl.trialDuration(1:3))];
f.yLims = yL;
f.lineWidth = 2;
cm = []';
           
% Create colormap                
% tRange = [1:bl.nTrials];
% cm = colormap(jet(length(tRange)));
% if isempty(cm)
%     if bl.nTrials > 1
%                 cm = colormap(jet(length(tRange)));        
%         nReps = 2;
%         if rotationMode
%             % Group according to vial location
%             cm1 = [repmat([0 0 1],nReps,1); repmat([0 1 0],nReps,1); repmat([1 0 0],nReps,1); repmat([.5 0 .5],nReps,1)];
%             cm2 = [repmat([0 1 0],nReps,1); repmat([1 0 0],nReps,1); repmat([.5 0 .5],nReps,1); repmat([0 0 1],nReps,1)];
%             cm3 = [repmat([1 0 0],nReps,1); repmat([.5 0 .5],nReps,1); repmat([0 0 1],nReps,1); repmat([0 1 0],nReps,1)];
%             cm4 = [repmat([.5 0 .5],nReps,1); repmat([0 0 1],nReps,1); repmat([0 1 0],nReps,1); repmat([1 0 0],nReps,1)];
%             cm = [cm1;cm2;cm3;cm4;cm1]; %[cm1;cm2*.8;cm3*.6;cm4*.4;cm1];            
%         else
%             % Group according to valve channel/vial identity
%             nReps = 2;
%             cm = [repmat([0 0 1],nReps,1); repmat([0 1 0],nReps,1); repmat([1 0 0],nReps,1); repmat([.5 0 .5],nReps,1)];
%             % Repeat if plotting more than one block
% %             cm = [cm; cm*.6];
%             cm = repmat(cm, bl.nTrials/8, 1);
%         end        
%         %            cm = cmCell{iFig};
%     else
%         cm = [0 0 1];
%     end
% end

% Set shared parameters
traceColors = [0 0 1]; %cm;
annotLines = [bl.pinchOpen, bl.stimOnTime, bl.stimOnTime + bl.stimLength];
annotColors = [0,0,0;0,1,0;1,0,0];
f.xLabel = 'Time (sec)';

% % Set legend entries
% if ~isempty(annotLines)
%     f.figLegend = cell(1, bl.nTrials + 3);
%     f.figLegend(bl.nTrials+1:end) = {'Pinch valve open', 'Odor onset' 'Odor offset'};
% end

% Voltage plot
h = figure(1); clf; hold on;
f.figDims = fd; %[10 150 1450 800]; %[10 150 1450 800];
traceData = meanV'; %bl.voltage';
f.title = {[bl.date, ' - ', figTitle], ['Trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
f.yLabel = 'Vm (mV)';
plotTraces(h, bl, f, traceData, traceColors, annotLines, annotColors);

%% Save figure
tic; t = [];
filename = [expName, figTitle ]; %figTitles{iFig}];
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
