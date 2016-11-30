function [h] = plotRasters(h, bl, figInfo, spikeTimes, annotLines, annotColors)
% ==============================================================================================
% PLOTS SPIKE RASTER USING DATA FROM bl.spikes
% h = figure handle
% bl = trial block structure
%  figInfo is an object with properties: 
    % figDims: position and size of figure window: [X, Y, width, height]
    % xLabel:  text for x-axis label
    % yLabel:  text for y-axis label
    % timeWindow: [startTime, stopTime] to plot in seconds
    % title: figure title
% spikeTimes: cell array containing spike times (in sec) for each trial
% annotLines: vector of the xLocs for each vertical marker line
% annotColors: the color for each annotation line
% ==============================================================================================

% Initial variable setup
smpRt = bl.sampRate;    
if ~isempty(figInfo.timeWindow)
    tStart = figInfo.timeWindow(1);
    tStop = figInfo.timeWindow(2);
else
    tStart = 1 / smpRt;
    tStop = sum(bl.trialDuration);
end
lineFormat = struct();
lineFormat.Color = [0 0 0];
if ~isempty(figInfo.figDims)
    set(h,'Position',figInfo.figDims);
end
set(h, 'Color', [1 1 1]);
set(gca,'LooseInset',get(gca,'TightInset'));
box off

% Remove spikes outside the plotting time window
for iTrial = 1:length(spikeTimes)
    curSpk = spikeTimes{iTrial};
    spikeTimes{iTrial}(curSpk < tStart | curSpk > tStop) = [];
end

% Plot all trials in chronological order
plotSpikeRaster(spikeTimes, 'XLimForCell', [tStart, tStop], 'PlotType', 'Vertline', 'AutoLabel', true, 'LineFormat', lineFormat); hold on;

% Adjust x-axis limits to full time window
xlim([tStart, tStop]);

% Plot annotation lines
aH = {};
for iLine = 1:length(annotLines)
     if annotLines(iLine) >= tStart && annotLines(iLine) <= tStop
         aH{length(aH)+1} = plot([annotLines(iLine), annotLines(iLine)], ylim, 'color', annotColors(iLine, :), 'linewidth', 2);
%      else
%          if ~isempty(figInfo.figLegend)
%             figInfo.figLegend(nTraces+iLine) =  [];
%          end
     end
end

% Add title and label axes
title(figInfo.title)
xlabel(figInfo.xLabel)
ylabel(figInfo.yLabel)

end