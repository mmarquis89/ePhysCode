function [h] = ejectionRasterPlot(bl, figInfo)
% PLOTS RASTERS FOR EJECTION AND CONTROL TRIALS
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds
                % figDims [X Y width height]
                
% Convert spike locations to seconds and save in cell array
spikeTimes = cell(bl.nTrials, 1);
for iTrial = 1:bl.nTrials
    spikeTimes{iTrial} = (bl.spikes(iTrial).locs ./ bl.sampRate)';     
end

% Separate spike data
controlTrials = spikeTimes(bl.pumpOn == 0);  
ejectTrials = spikeTimes(bl.pumpOn == 1);
                
% Set figInfo properties
figInfo.yLabel = 'Trial Number';
figInfo.xLabel = 'Time (sec)';
figInfo.title = {[bl.date], ['Control trials'], ['n = ', num2str(length(controlTrials))]};

% Create annotation line info
annotLines = [bl.pinchOpen, bl.stimOnTime, bl.stimOnTime + bl.stimLength];
annotColors = [0,0,0;0,1,0;1,0,0];

% Set up figure
h = figure(7);clf; hold on
subplot(2,1,1);

% Plot control trials
plotRasters(h, bl, figInfo, controlTrials, annotLines, annotColors);

% Update title, figDims, and annotation lines
figInfo.title = {[bl.date], ['Ejection trials'], ['n = ', num2str(length(ejectTrials))]};
annotLines = [bl.pinchOpen, (bl.stimOnTime - bl.pumpTiming(1)), bl.stimOnTime, bl.stimOnTime + bl.stimLength];
annotColors = [0,0,0; 1,0,1; 0,1,0; 1,0,0];

% Plot ejection trials
subplot(2,1,2);
plotRasters(h, bl, figInfo, ejectTrials, annotLines, annotColors); 

end