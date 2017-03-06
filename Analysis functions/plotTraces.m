function [plotHandle] = plotTraces(plotHandle, bl, figInfo, traceData, traceColors, annotLines, annotColors)
% =============================================================================================================
% Takes a figure or axes handle, formats it using the figInfo object and block structure, and plots one 
% or more traces and/or vertical marker lines
% plotHandle = handle of the figure or axes to plot in
% figInfo is an object with (optional) properties: 
    % figDims: position and size of figure window: [X, Y, width, height]
    % xLabel:  text for x-axis label
    % yLabel:  text for y-axis label
    % timeWindow: [startTime, stopTime] to plot in seconds
    % yLims:   y-axis limits: [yMin, yMax]
    % title:   figure title
    % lineWidth: width of plotting line
    % figLegend: cell array of legend text ([] to skip an object)
% traceData: array, each row is a trace to be plotted
% traceColors: nx3 array, each row is the color for one trace
% annotLines: cell array with the xLoc(s) for each stimulus marker line
    % Use a single number to plot a vertical line at the xLoc. 
    % Use a 2-number vector for a horizontal line above the plot between the pair of xLocs.
% annotLineType: character vector with one letter for each xLoc in annotLines

% annotColors: the color for each annotation line. xLocs that are part of a horizontal line must be same color
% =============================================================================================================

% Initial variable setup
smpRt = bl.sampRate;    
nTraces = size(traceData, 1);
if ~isempty(figInfo.timeWindow)
    if figInfo.timeWindow(1)*smpRt < length(bl.time)
        tStart = figInfo.timeWindow(1);       
    else
        tStart = 1 / smpRt;
    end
    if figInfo.timeWindow(2)*smpRt < length(bl.time)
        tStop = figInfo.timeWindow(2);
    else
        tStop = length(bl.time)/smpRt;
    end
else
    tStart = 1 / smpRt;
    tStop = sum(bl.trialDuration);
end

% Activate and format figure/axes
if strcmp(plotHandle.Type, 'figure')
    figure(plotHandle);
    if ~isempty(figInfo.figDims)
        set(gcf,'Position',figInfo.figDims);
    end
    set(gcf, 'Color', [1 1 1]);
else
    axes(plotHandle)
end
box off


% Determine plotting line width
if ~isempty(figInfo.lineWidth)
    LW = figInfo.lineWidth;
else
    LW = 0.5;
end

% Plot each trace
tH = {};
for iTrace = 1:nTraces
    tH{iTrace} = plot(bl.time(tStart*smpRt:tStop*smpRt), traceData(iTrace, tStart*smpRt:tStop*smpRt), 'color', traceColors(iTrace, :), 'linewidth', LW);
end

% Update yLims if necessary
if ~isempty(figInfo.yLims)
   yLims = figInfo.yLims;
else
   yLims = ylim;
end

% Plot annotation lines
for iLine = 1:length(annotLines)
    if ~isempty(annotLines{iLine})
    if min(annotLines{iLine}) >= tStart && max(annotLines{iLine}) <= tStop
        if length(annotLines{iLine}) == 1
            plot([annotLines{iLine}, annotLines{iLine}], yLims, 'color', annotColors(iLine, :), 'linewidth', 2);
        elseif length(annotLines{iLine}) == 2
            yLen = abs(yLims(1)-yLims(2));
            rectangle('Position', [annotLines{iLine}(1), (yLims(2)-0.08*yLen), diff(annotLines{iLine}), 0.025*yLen], ...
                'FaceColor', annotColors(iLine, :), 'EdgeColor', annotColors(iLine, :))
        end
    end
    end
end
ylim(yLims);

% Add legend if provided, skipping empty array entries (i.e. [])
allObj = [tH];
if ~isempty(figInfo.figLegend)
    entries = allObj(~cellfun(@isempty, figInfo.figLegend));
    legend([entries{:}], figInfo.figLegend(~cellfun(@isempty, figInfo.figLegend)));
end

% Add title and label axes
title(figInfo.title)
xlabel(figInfo.xLabel)
ylabel(figInfo.yLabel)

end