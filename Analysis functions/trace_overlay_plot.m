 function [h, j] = trace_overlay_plot(bl, figInfo)
 %==============================================================================================
% PLOT EACH TRIAL VOLTAGE AND CURRENT
% bl = trial block structure
% figInfo = object with (optional) properties:
                % timeWindow = [startTime, stopTime] in seconds 
                % yLims [yMin, yMax]
                % cm = (optional) colormap for traces, each row is RGB for one trace. 
                %       Default of empty array will color them chronologically using jet
%================================================================================================

% Create colormap                
tRange = [1:bl.nTrials];
if isempty(figInfo.cm)
    if bl.nTrials > 1
        cm = jet(length(tRange)).*.85;
    else
        cm = [0 0 1];
    end
else
    cm = figInfo.cm;
end

% Set shared parameters
traceColors = cm;
if ~isempty(bl.altStimDuration)
    annotLines = {bl.altStimStartTime, bl.stimOnTime, bl.stimOnTime + bl.stimLength, bl.altStimStartTime + bl.altStimLength};    
    annotColors = [1,0,1; 0,0,0; 0,0,0; 1,0,1];
else
    annotLines = {bl.stimOnTime, bl.stimOnTime + bl.stimLength};    
    annotColors = [0,0,0; 0,0,0];
end



figInfo.xLabel = 'Time (sec)';

% Set legend entries
if ~isempty(annotLines)
    figInfo.figLegend = {'Odor Stimulus'};
end

% Voltage plot
h = figure(1); clf; hold on;
figInfo.figDims = [10 550 1850 400];
if strcmp(bl.trialInfo(1).scaledOutMode, 'V')
    traceData = bl.scaledOut';
else
    traceData = bl.voltage';
end
figInfo.title = {[bl.date], ['Voltage traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
figInfo.yLabel = 'Vm (mV)';
plot_traces(h, bl, figInfo, traceData, traceColors, annotLines, annotColors);
%tightfig; set(gcf, 'Position', figInfo.figDims);
set(gca,'LooseInset',get(gca,'TightInset'))

% Current plot
j = figure(2); clf; hold on;
figInfo.figDims = [10 50 1850 400];
if strcmp(bl.trialInfo(1).scaledOutMode, 'I')
    traceData = bl.scaledOut';
else
    traceData = bl.current';
end
figInfo.title = {[bl.date], ['Current traces for trial numbers: ' num2str(bl.trialList(1)) '-' num2str(bl.trialList(end))]};
figInfo.yLabel = 'Current (pA)';
plot_traces(j, bl, figInfo, traceData, traceColors, annotLines, annotColors);
set(gca,'LooseInset',get(gca,'TightInset'))

end