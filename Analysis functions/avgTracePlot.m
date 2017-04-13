function [meanTrace, h] = avgTracePlot(bl, figInfo)
%============================================================================================================================
% PLOT AVERAGE TRACES
% bl = trial block structure
% figInfo = object with (optional) properties:
%                 timeWindow = [startTime, stopTime] in seconds 
%                 figDims [X Y width height]
%                 yLims [yMin, yMax]
%============================================================================================================================

% Get correct trace data and y-axis labels
if strcmp(bl.ampMode, 'Vclamp')
    meanTrace = mean(bl.current,2)';
    figInfo.yLabel = 'Average Current (pA)';
elseif strcmp(bl.ampMode, 'Iclamp')
    meanTrace = mean(bl.voltage, 2)';
    figInfo.yLabel = 'Average Vm (mV)';
end

% Set figInfo properties
figInfo.xLabel = 'Time (sec)';
figInfo.lineWidth = 1;
figInfo.figLegend = {[],'Pinch valve open','Odor onset', 'Odor offset'};
if length(unique({bl.trialInfo.odor})) > 1
    % Omit odor name from title if there are multiple odors in the block
    figInfo.title = {[bl.date], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
else
    figInfo.title = {[bl.date ' - ' bl.odor], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
end

% Create annotation line info
annotLines = [bl.stimOnTime, bl.stimOnTime + bl.stimLength];
annotColors = [0,0,0;0,0,0];

% Plot figure
h = figure(3); clf; hold on;
plotTraces(h, bl, figInfo, meanTrace, [0 0 1], annotLines, annotColors);

end