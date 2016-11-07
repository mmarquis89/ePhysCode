function [xPoints, yPoints] = PlotRasterTestCode(spikes, varargin)
% PLOTSPIKERASTER Create raster plot from binary spike data or spike times
%   Efficiently creates raster plots with formatting support. Faster than
%   common implementations. Multiple plot types and parameters available!
%   Look at Parameters section below.
%
%   Inputs:
%       M x N logical array (binary spike data):
%           where M is the number of trials and N is the number of time
%           bins with maximum of 1 spike per bin. Assumes time starts at 0.
%       M x 1 cell of spike times:
%           M is the number of trials and each cell contains a 1 x N vector
%           of spike times. Units should be in seconds.
%
%   Output:
%       xPoints - vector of x points used for the plot.
%       yPoints - vector of y points used for the plot.
%
%   Parameters:
%       PlotType - default 'horzline'. Several types of plots available:
%           1. 'horzline' -     plots spikes as gray horizontal lines.
%           2. 'vertline' -     plots spikes as vertical lines, centered
%               vertically on the trial number.
%           3. 'scatter' -      plots spikes as gray dots.
%
%           ONLY FOR BINARY SPIKE DATA:
%           4. 'imagesc' -      plots using imagesc. Flips colormap so
%               black indicates a spike. Not affected by SpikeDuration,
%               RelSpikeStartTime, and similar timing parameters.
%           5. 'horzline2' -    more efficient plotting than horzline if
%               you have many timebins, few trials, and high spike density.
%               Note: SpikeDuration parameter DOES NOT WORK IF LESS THAN
%               TIME PER BIN.
%           6. 'vertline2' -    more efficient plotting than vertline if
%               you have few timebins, many trials, and high spike density.
%           Note: Horzline and vertline should be fine for most tasks.
%
%       FigHandle - default gcf (get current figure).
%           Specify a specific figure or subplot to plot in. If no figure
%           is specified, plotting will occur on the current figure. If no
%           figure is available, a new figure will be created.
%
%       LineFormat - default line is gray. Used for 'horzline' and
%           'vertline' plots only. Usage example:
%               LineFormat = struct()
%               LineFormat.Color = [0.3 0.3 0.3];
%               LineFormat.LineWidth = 0.35;
%               LineFormat.LineStyle = ':';
%               plotSpikeRaster(spikes,'LineFormat',LineFormat)
%
%       MarkerFormat - default marker is a gray dot with size 1. Used for
%           scatter type plots only. Usage is the same as LineFormat.
%
%       AutoLabel - default 0.
%           Automatically labels x-axis as 'Time (ms)' or 'Time (s)' and
%           y-axis as 'Trial'.
%
%       XLimForCell - default [NaN NaN].
%           Sets x-axis window limits if using cell spike time data. If
%           unchanged, the default limits will be 0.05% of the range. For
%           better performance, this parameter should be set.
%
%       TimePerBin - default 0.001 (1 millisecond).
%           Sets the duration of each timebin for binary spike train data.
%
%       SpikeDuration - default 0.001 (1 millisecond).
%           Sets the horizontal spike length for cell spike time data.
%
%       RelSpikeStartTime - default 0 seconds.
%           Determines the starting point of the spike relative to the time
%           indicated by spike times or time bins. For example, a relative
%           spike start time of -0.0005 would center 1ms spikes for a
%           horzline plot of binary spike data.
%
%       rasterWindowOffset - default NaN
%           Exactly the same as relSpikeStartTime, but unlike
%           relSpikeStartTime, the name implies that it can be used to make
%           x-axis start at a certain time. If set, takes precedence over
%           relSpikeStartTime.
%
%       VertSpikePosition - default 0 (centered on trial).
%           Determines where the spike position is relative to the trial. A
%           value of 0 is centered on the trial number - so a spike on
%           trial 3 would have its y-center on 3. Example: A common type of
%           spike raster plots vertical spikes from previous trial to
%           current trial. Set VertSpikePosition to -0.5 to center the
%           spike between trials.
%
%       VertSpikeHeight - default 1 (spans 1 trial).
%           Determines height of spike for 'vertline' plots. Decrease to
%           separate trials with a gap.
%
%   Examples:
%       plotSpikeRaster(spikeTimes);
%               Plots raster plot with horizontal lines.
%
%       plotSpikeRaster(spikeTimes,'PlotType','vertline');
%               Plots raster plot with vertical lines.
%
%       plotSpikeRaster(spikeTimes,'FigHandle',h,'AutoLabel',1,...
%           'XLimForCell',[0 10],'HorzSpikeLength',0.002,);
%               Plots raster plot on figure with handle h using horizontal
%               lines of length 0.002, with a window from 0 to 10 seconds,
%               and automatic labeling.
%
%       plotSpikeRaster(spikeTimes,'PlotType','scatter',...
%           'MarkerFormat',MarkerFormat);
%               Plots raster plot using dots with a format specified by
%               MarkerFormat.


%% AUTHOR    : Jeffrey Chiou
%% $DATE     : 07-Feb-2014 12:15:47 $
%% $Revision : 1.2 $
%% DEVELOPED : 8.1.0.604 (R2013a)
%% FILENAME  : plotSpikeRaster.m

%% Set Defaults and Load optional arguments
LineFormat.Color = [0.2 0.2 0.2];
MarkerFormat.MarkerSize = 1;
MarkerFormat.Color = [0.2 0.2 0.2];
MarkerFormat.LineStyle = 'none';

p = inputParser;
p.addRequired('spikes',@(x) islogical(x) || iscell(x));
p.addParameter('FigHandle',gcf,@isinteger);
p.addParameter('LineFormat',LineFormat,@isstruct)
p.addParameter('AutoLabel',0, @islogical);
p.addParameter('XLimForCell',[NaN NaN],@(x) isnumeric(x) && isvector(x));
p.addParameter('SpikeDuration',0.001,@(x) isnumeric(x) && isscalar(x));
p.addParameter('RelSpikeStartTime',0,@(x) isnumeric(x) && isscalar(x));
p.addParameter('RasterWindowOffset',NaN,@(x) isnumeric(x) && isscalar(x));
p.addParameter('VertSpikeHeight',1,@(x) isnumeric(x) && isscalar(x));
p.parse(spikes,varargin{:});

spikes = p.Results.spikes;
figH = p.Results.FigHandle;
lineFormat = struct2opt(p.Results.LineFormat);
autoLabel = p.Results.AutoLabel;
xLimForCell = p.Results.XLimForCell;
spikeDuration = p.Results.SpikeDuration;
relSpikeStartTime = p.Results.RelSpikeStartTime;
rasterWindowOffset = p.Results.RasterWindowOffset;
vertSpikeHeight = p.Results.VertSpikeHeight;

if ~isnan(rasterWindowOffset) && relSpikeStartTime==0
    relSpikeStartTime = rasterWindowOffset;
elseif ~isnan(rasterWindowOffset) && relSpikeStartTime~=0
    disp(['Warning: RasterWindoWOffset and RelSpikeStartTime perform the same function. '...
        'The value set in RasterWindowOffset will be used over RelSpikesStartTime']);
    relSpikeStartTime = rasterWindowOffset;
end

%% Initialize figure and begin plotting logic
figure(figH);
hold on;

% Equivalent if iscell(spikes).
%% Cell case

% Validation: First check to see if cell array is a vector, and each
% trial within is a vector.
if ~isvector(spikes)
    error('Spike cell array must be an M x 1 vector.')
end
trialIsVector = cellfun(@isvector,spikes);
if sum(trialIsVector) < length(spikes)
    error('Cells must contain 1 x N vectors of spike times.');
end

% Now make sure cell array is M x 1 and not 1 x M.
if size(spikes,2) > 1 && size(spikes,1) == 1
    spikes = spikes';
end

% Make sure each trial is 1 x N and not N x 1
nRowsInTrial = cellfun(@(x) size(x,1),spikes);
% If there is more than 1 row in any trial, add a warning, and
% transpose those trials. Allows for empty trials/cells (nRows > 1
% instead of > 0).
if sum(nRowsInTrial > 1) > 0
    trialsToReformat = find(nRowsInTrial > 1);
    disp('Warning - some cells (trials) have more than 1 row. Those trials will be transposed.');
    for t = trialsToReformat
        spikes{trialsToReformat} = spikes{trialsToReformat}';
    end
end

nTrials = length(spikes);

% Find x-axis limits that aren't manually set (default [NaN NaN]), and
% automatically set them. This is because we don't assume spikes start
% at 0 - we can have negative spike times.
limitsToSet = isnan(xLimForCell);
if sum(limitsToSet) > 0
    % First find range of spike times
    minTimes = cellfun(@min,spikes,'UniformOutput',false);
    minTime = min( [ minTimes{:} ] );
    maxTimes = cellfun(@max,spikes,'UniformOutput',false);
    maxTime = max( [ maxTimes{:} ] );
    timeRange = maxTime - minTime;
    
    % Find 0.05% of the range.
    xStartOffset = relSpikeStartTime - 0.0005*timeRange;
    xEndOffset = relSpikeStartTime + 0.0005*timeRange + spikeDuration;
    newLim = [ minTime+xStartOffset, maxTime+xEndOffset ];
    xLimForCell(limitsToSet) = newLim(limitsToSet);
    % End result, if both limits are automatically set, is that the x
    % axis is expanded 0.1%, so you can see initial and final spikes.
end
xlim(xLimForCell);
ylim([0 nTrials+1]);

%% Vertical or horizontal line logic
nTotalSpikes = sum(cellfun(@length,spikes));

% Preallocation is possible since we know how many points to
% plot, unlike discrete case. 3 points per spike - the top pt,
% bottom pt, and NaN.
xPoints = NaN(nTotalSpikes*3,1);
yPoints = xPoints;
currentInd = 1;

%% Vertical Lines
halfSpikeHeight = vertSpikeHeight/2;
for trials = 1:nTrials
    nSpikes = length(spikes{trials});
    nanSeparator = NaN(1,nSpikes);
    
    trialXPoints = [ spikes{trials} + relSpikeStartTime;...
        spikes{trials} + relSpikeStartTime; nanSeparator ];
    trialXPoints = trialXPoints(:);
    
    trialYPoints = [ (trials-halfSpikeHeight)*ones(1,nSpikes);...
        (trials+halfSpikeHeight)*ones(1,nSpikes); nanSeparator ];
    trialYPoints = trialYPoints(:);
    
    % Save points and update current index
    xPoints(currentInd:currentInd+nSpikes*3-1) = trialXPoints;
    yPoints(currentInd:currentInd+nSpikes*3-1) = trialYPoints;
    currentInd = currentInd + nSpikes*3;
end

% Plot everything at once! We will reverse y-axis direction later.
plot(xPoints, yPoints, 'k', lineFormat{:});

%% Reverse y-axis direction and label
set(gca,'YDir','reverse');
if autoLabel
    xlabel('Time (s)');
    ylabel('Trial');
end

%% Figure formatting
% Draw the tick marks on the outside
set(gca,'TickDir','out')

% Use special formatting if there is only a single trial.
% Source - http://labrigger.com/blog/2011/12/05/raster-plots-and-matlab/
if size(spikes,1) == 1
    set(gca,'YTick', [])                        % don't draw y-axis ticks
    set(gca,'PlotBoxAspectRatio',[1 0.05 1])    % short and wide
    set(gca,'YColor',get(gcf,'Color'))          % hide the y axis
    ylim([0.5 1.5])
end

hold off;

end % main function

function paramCell = struct2opt(paramStruct)
% Converts structure to parameter-value pairs
%   Example usage:
%       formatting = struct()
%       formatting.color = 'black';
%       formatting.fontweight = 'bold';
%       formatting.fontsize = 24;
%       formatting = struct2opt(formatting);
%       xlabel('Distance', formatting{:});
% Adapted from:
% http://stackoverflow.com/questions/15013026/how-can-i-unpack-a-matlab-structure-into-function-arguments
% by user 'yuk'

fname = fieldnames(paramStruct);
fval = struct2cell(paramStruct);
paramCell = [fname, fval]';
paramCell = paramCell(:);

end % struct2opt