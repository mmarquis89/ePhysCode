function [meanTraces, h] = avgTraceOverlay(bl, figInfo, traceGroups, groupColors, medfilt, offset)
%=========================================================================================================
% Plots an overlay of the average voltage traces from a block of mixed trial groups
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds 
                % figDims [X Y width height]
                % yLims [yMin, yMax]
% traceGroups = a vector with the desired trace groups (e.g. [1 2 2 1 3])      
% medfilt = 1 to remove spikes with a median filter before averaging, 0 to skip this step.
% offset = 1 to add an offset to align all traces to the most hyperpolarized one, 0 to skip this step.
%========================================================================================================= 

% Setup variables
groupList = unique(traceGroups);
nGroups = length(groupList);
scaledOut = bl.scaledOut;

% Offset traces if necessary
if offset
    for iGroup = 1:nGroups
        means(iGroup) = mean(mean(scaledOut(:,traceGroups==iGroup)));
    end
    minMean = min(means);
    for iGroup = 1:nGroups
        scaledOut(:,traceGroups==iGroup) = scaledOut(:,traceGroups==iGroup) + diff([means(iGroup), minMean]);
    end
end

% Get correct trace data
for iGroup = 1:nGroups
    if medfilt
        meanTraces(iGroup, :) = mean(medfilt1(scaledOut(:, traceGroups == groupList(iGroup)), 800), 2)';
    else
        meanTraces(iGroup, :) = mean(scaledOut(:, traceGroups == groupList(iGroup)), 2)';
    end
end

% Set figInfo properties
figInfo.xLabel = 'Time (sec)';
figInfo.yLabel = 'Average Vm (mV)';
if length(unique({bl.trialInfo.odor})) > 1
    % Omit odor name from title if there are multiple odors in the block
    figInfo.title = {[bl.date], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
else
    figInfo.title = {[bl.date ' - ' bl.trialInfo(1).odor], ['Average traces for trials: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
end

% Create annotation line info
annotLines = [bl.stimOnTime, bl.stimOnTime + bl.stimLength];    
annotColors = [0,0,0; 0,0,0];

% Plot mean traces
h = figure(3); clf; hold on;
plotTraces(h, bl, figInfo, meanTraces, groupColors, annotLines, annotColors);

end