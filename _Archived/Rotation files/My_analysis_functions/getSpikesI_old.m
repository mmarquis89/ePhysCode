function spikes = getSpikesI(bl, posThresh, invert)
% Use current traces to identify spike times
% Peaks must be at least 5 ms apart
% posThresh: threshold for peak identification
% Invert: if true, valleys will be found instead of peaks

normCurrent = bl.filteredCurrent - mean(median(bl.filteredCurrent));    % Set current baseline at 0
if invert
   normCurrent = -normCurrent;                                          % Invert trace if necessary to find negative peaks
end
warning('off', 'signal:findpeaks:largeMinPeakHeight');                  % Turns off complaint if no peaks are found

for iTrial = 1:bl.nTrials
    [p, l] = findpeaks(normCurrent(:,iTrial), 'MinPeakDistance', .005 * bl.sampRate, 'MinPeakHeight', posThresh);     
    if ~isempty(p) && ~isempty(l)
        if invert
            spikes(iTrial).peakVals = -p;                               % Re-invert peak value if necessary
        else
            spikes(iTrial).peakVals = p;                                   
        end
        spikes(iTrial).locs = l;
    else 
        spikes(iTrial).peakVals = ones(0,1);
        spikes(iTrial).locs = ones(0,1);
    end
end

end