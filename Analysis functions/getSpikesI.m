function spikes = getSpikesI(bl, posThresh)
%=============================================================================================================
% Use current traces to identify spike times
% Peaks must be at least 5 ms apart
% posThresh: Minimum values in Std Devs to be counted as a spike: [peak amp, AHP amp, peak window, AHP window]
%=============================================================================================================

% Center current at 0 and invert since initial peaks are negative
normCurrent = bl.current - mean(median(bl.current));
normCurrent = -normCurrent;

% Find standard dev of all current data
bl.posThresh = posThresh;
currSTD = std(normCurrent(:));
posThresh = posThresh.*currSTD

warning('off', 'signal:findpeaks:largeMinPeakHeight');  % Turns off complaint if no peaks are found
for iTrial = 1:bl.nTrials
    [p, l] = findpeaks(normCurrent(:,iTrial), 'MinPeakDistance', .003 * bl.sampRate, 'MinPeakHeight', posThresh(1));
    
    % If any large peaks are found, validate shape with other metrics
    if ~isempty(p) && ~isempty(l)
        AHPmag = [];
        pkMed = [];
        AHPmed = [];
        for iPeak = 1:length(p)
            % Initial Peak Window
            pkWin = [l(iPeak)-.0001*bl.sampRate:l(iPeak)+.0001*bl.sampRate];
            pkWin(pkWin>size(normCurrent,1)) = size(normCurrent,1);
            pkWin(pkWin < 1) = 1;
            
            % AHP Window
            AHPwin = [l(iPeak)+.001*bl.sampRate:l(iPeak)+.003*bl.sampRate];
            AHPwin(AHPwin>size(normCurrent,1)) = size(normCurrent,1);
            AHPwin(AHPwin < 1) = 1;
            
            % Calculate median value in peak windows
            pkMed(iPeak) = abs(median(normCurrent(pkWin, iTrial)));
            AHPmed(iPeak) = -median(normCurrent(AHPwin, iTrial));
            
            % AHP peak magnitude
            AHPmag(iPeak) = abs(min(normCurrent(AHPwin,iTrial)));                        
        end
        
        % Identify good peaks
        x1 = AHPmag > posThresh(2);
        x2 = pkMed > posThresh(3);
        x3 = AHPmed > posThresh(4);
        validPeaks = (x1+x2+x3) == 3;
        
        % Save validated peaks
        spikes(iTrial).peakVals = p(validPeaks); %-p(AHPmag < -posThresh(2));
        spikes(iTrial).locs = l(validPeaks); %l(AHPmag < -posThresh(2));
        
        % Fill with empty array if there are no valid peaks
        if isempty(spikes(iTrial).peakVals)
            spikes(iTrial).peakVals = ones(0,1);
            spikes(iTrial).locs = ones(0,1);
        end
    else
        % Fill with empty array if there are no valid peaks
        spikes(iTrial).peakVals = ones(0,1);
        spikes(iTrial).locs = ones(0,1);
    end
end
end