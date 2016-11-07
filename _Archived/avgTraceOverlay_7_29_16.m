function [meanTraces, h] = avgTraceOverlay(bl, figInfo, traceGroups, groupColors)
% Plots an overlay of the average voltage traces from a block of mixed trial groups
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds 
                % figDims [X Y width height]
                % yLims [yMin, yMax]
% traceGroups = a vector with the desired trace groups (e.g. [1 2 2 1 3])               
                
% Get correct trace data and y-axis labels
groupList = unique(traceGroups);
nGroups = length(groupList);
for iGroup = 1:nGroups
   meanTraces(iGroup, :) = mean(bl.voltage(:, traceGroups == groupList(iGroup)), 2)';  
end 
figInfo.yLabel = 'Average Vm (mV)';

% Set figInfo properties
figInfo.xLabel = 'Time (sec)';
if length(unique({bl.trialInfo.odor})) > 1
    % Omit odor name from title if there are multiple odors in the block
    figInfo.title = {[bl.date], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
else
    figInfo.title = {[bl.date ' - ' bl.trialInfo(1).odor], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
end

% Create annotation line info
annotLines = [bl.pinchOpen, bl.stimOnTime, bl.stimOnTime + bl.stimLength];    
annotColors = [0,0,0; 0,0,0; 0,0,0];

% Plot mean traces
h = figure(3); clf; hold on;
plotTraces(h, bl, figInfo, meanTraces, groupColors, annotLines, annotColors);

end