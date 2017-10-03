function spikes = get_spikes_simple(bl, threshold, invert)
%============================================================================================================================
% Apply a simple threshold to the raw current trace to identify spikes 
% Peaks must be at least 3 ms apart
%       bl: the block object containing the trials to be analyzed
%       threshold: the peak height threshold in Std Dev for a peak to be considered a spike
%       invert: pass 1 to flip the current trace and use negative peaks instead of positive, 0 otherwise
%============================================================================================================================

% Center current at 0 and invert if necessary
normCurrent = bl.current - mean(median(bl.current));
if invert
    normCurrent = -normCurrent;
end

% Find standard dev of all current data
bl.threshold = threshold;
currSTD = std(normCurrent(:));
threshold = threshold.*currSTD

warning('off', 'signal:findpeaks:largeMinPeakHeight');  % Turns off complaint if no peaks are found
for iTrial = 1:bl.nTrials
    [p, l] = findpeaks(normCurrent(:,iTrial), 'MinPeakDistance', .003 * bl.sampRate, 'MinPeakHeight', threshold);
    
    % If any large peaks are found, save their sizes and locations
    if ~isempty(p) && ~isempty(l)
        spikes(iTrial).peakVals = p;
        spikes(iTrial).locs = l;
    else
        % Fill with empty array if there are no valid peaks
        spikes(iTrial).peakVals = ones(0,1);
        spikes(iTrial).locs = ones(0,1);
    end%if
end%for
end%function