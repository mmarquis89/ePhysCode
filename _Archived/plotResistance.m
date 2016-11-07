function [AX, Ra, Rin] = plotResistance(bl, figDims, yLims)
% Uses a plot with 2 Y-axes to plot access and input resistances for all
% trials in the current block
%   figDims (optional, [] for default) = position and size of figure window: [X, Y, width, height]
%   yLims (optional, [] for default) = [yMin, yMax]

% Make plot
[AX, Ra, Rin] = plotyy(1:bl.nTrials, [bl.trialInfo(:).Ra], 1:bl.nTrials, [bl.trialInfo(:).Rin] / 1000);

% Set optional parameters
if ~isempty(figDims)
   set(gcf,'Position',figDims,'Color',[1 1 1]);  
end
if ~isempty(yLims)
   ylim(yLims); 
end

% Adjust plot style
Ra.LineStyle = 'none';
Ra.Marker = 'o';
Rin.LineStyle = 'none';
Rin.Marker = '*';
ylabel(AX(1), 'Access Resistance (MOhm)')
ylabel(AX(2), 'Input Resistance (GOhm)')
xlabel('Trial Number')

end