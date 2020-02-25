% RASTERPLOT.M Display spike rasters.
%   RASTERPLOT(T,N,L) Plots the rasters of spiketimes (T in samples) for N trials, each of length
%   L samples, Sampling rate = 1kHz. Spiketimes are hashed by the trial length.
% 
%   RASTERPLOT(T,N,L,H) Plots the rasters in the axis handle H
%
%   RASTERPLOT(T,N,L,H,FS) Plots the rasters in the axis handle H. Uses sampling rate of FS (Hz)
%
%   Example:
%          t=[10 250 9000 1300,1600,2405,2900];
%          rasterplot(t,3,1000)
%
% Rajiv Narayan
% askrajiv@gmail.com
% Boston University, Boston, MA
%
% MODIFIED 24-Feb-2020 by MM
% Added support for name-value pair arguments and outputting the plot+axes handles, and changed some 
% variable names for clarity
%
%       'plotAxes' (default: create new figure and axes)
%
%       'sampRate' (default: 1000)
%
%       'lineWidth' (default: 1)
%
%       'lineColor' (default: 'k')
%
%       'trialSpacing' (default: 1.25)
%
%
function [axesHandle, plotHandle] = rasterplot(spikeTimes, nTrials, trialLen, varargin)
%
% Parse optional arguments
p = inputParser;
addParameter(p, 'plotAxes', []);
addParameter(p, 'sampRate', 1000);
addParameter(p, 'lineWidth', 1);
addParameter(p, 'lineColor', 'k');
addParameter(p, 'trialSpacing', 1.25);
parse(p, varargin{:});
axesHandle = p.Results.plotAxes;
sampRate = p.Results.sampRate;
lineWidth = p.Results.lineWidth;
lineColor = p.Results.lineColor;
trialSpacing = p.Results.trialSpacing;

% Create figure + axes if necessary
if isempty(axesHandle)
    figure;
    axesHandle = gca();
end

% plot spikes
trials=ceil(spikeTimes/trialLen);
reltimes=mod(spikeTimes,trialLen);
reltimes(~reltimes)=trialLen;
numspikes=length(spikeTimes);
xx=ones(3*numspikes,1)*nan;
yy=ones(3*numspikes,1)*nan;
yy(1:3:3*numspikes)=(trials-1)*trialSpacing;
yy(2:3:3*numspikes)=yy(1:3:3*numspikes)+1;

% scale the time axis to seconds
xx(1:3:3*numspikes) = reltimes / sampRate;
xx(2:3:3*numspikes) = reltimes / sampRate;
xlim = [1, trialLen] / sampRate;
% xx(1:3:3*numspikes)=reltimes*1000/sampRate;
% xx(2:3:3*numspikes)=reltimes*1000/sampRate;
% xlim=[1,trialLen*1000/sampRate];
axes(axesHandle);
plotHandle = plot(xx, yy, lineColor, 'linewidth', lineWidth);
axis ([xlim, 0, (nTrials)*1.5]);  
  
ax.TickDir = 'out';
axesHandle.YTick = [];
ylabel('Trials'); 
xlabel('Time(ms)');

 
end%function