function [responses] = responseCalc(bl, responseLength, minLatency)

% CALCULATE SPIKE COUNT IN RESPONSE PERIOD
% responseLength: time post-stim (in milliseconds) to collect spikes from
% minLatency: minimum time (in milliseconds) after stim to count spike in response

responseWindow = bl.sampRate * .001 * responseLength;       % Convert unites of input times from ms to samples
minLat = bl.sampRate * .001 * minLatency;
responses = zeros(bl.nTrials,2);

for iTrial = 1:bl.nTrials
    stimTime = bl.stimOnTime * bl.sampRate;               % Index of stimulus onset  
    peakLocs = bl.spikes(iTrial).locs;                    % Save peak indices
  
    bl.spikes(iTrial).response = sum(peakLocs > stimTime + minLat & peakLocs < stimTime+ responseWindow);   % Total spikes in response
    
    responses(iTrial,1) = bl.intensities(iTrial);         % First column - duty cycle
    responses(iTrial,2) = bl.spikes(iTrial).response;     % Second column - spikes in period after stim onset
end

end