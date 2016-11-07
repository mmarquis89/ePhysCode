classdef figInfo
    % General information for figure plotting functions
    properties
        figDims         % position and size of figure window: [X, Y, width, height]
        xLabel          % text for x-axis label
        yLabel          % text for y-axis label
        timeWindow      % [startTime, stopTime] to plot in seconds
        yLims           % y-axis limits: [yMin, yMax]
        title           % figure title
        lineWidth       % width of plotting line
        figLegend       % cell array of legend text ([] to skip an object)
        cm              % nx3 colormap of RGB values
    end
end