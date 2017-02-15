function bl = makeBl(block, trialList)
%====================================================================================================
% This function takes an experimental block and reformats it to make it easier to reference frequently
% used fields, and calculates some variables that will be used by later analysis functions.

%   block: a structure created with the getTrials() function that contains data for a set of trials
%   trialList: the list of trials that were used to create the block
%====================================================================================================

% Create global variables
bl.trialInfo = block.trialInfo;
bl.date = block.trialInfo(1).date;
bl.trialList = trialList;
bl.nTrials = length(block.trialInfo);                                                             % Number of trials in block
bl.sampRate = block.trialInfo(1).sampratein;                                                      % Sampling rate
bl.sampleLength = 1/bl.sampRate;                                                                  % Sample duration
bl.time = bl.sampleLength:bl.sampleLength:bl.sampleLength*length(block.data.scaledOut);           % Time in seconds of each sample
bl.odors = {block.trialInfo.odor};
bl.Rpipette = block.trialInfo(1).Rpipette;
bl.trialDuration = block.trialInfo(1).trialduration;
bl.frameRate = block.trialInfo(1).acqSettings.frameRate;

% Maintain backwards-compatibility with older experiments that contained pinch valve timing info
if length(bl.trialDuration) == 4
    bl.trialDuration = [sum(bl.trialDuration(1:2)), bl.trialDuration(3), bl.trialDuration(4)];
end

% This stuff only applies if an odor was presented
if length(bl.trialDuration) > 1
    % Save valve timing
    bl.stimOnTime = block.trialInfo(1).trialduration(1);                                              % Pre-stim time (sec)
    bl.stimLength = block.trialInfo(1).trialduration(2);                                               % Stim duration
else
    bl.vHolds = [];
    bl.stimOnTime = [];
    bl.stimLength = [];
end

% To maintain backwards-compatability with older data
if isfield(block.trialInfo, 'altStimDuration')
    stimCell = {block.trialInfo.altStimDuration};
else
    stimCell = {block.trialInfo.iontoDuration};
    stimCell = stimCell(~cellfun(@isempty, stimCell));
end

% If non-odor stimulus was used, save the timing info
bl.altStimDuration = stimCell{1};
if ~isempty(bl.altStimDuration)
    bl.altStimStartTime = bl.altStimDuration(1);
    bl.altStimLength = bl.altStimDuration(2);
else
    bl.altStimStartTime = [];
    bl.altStimLength = [];
end

% Save recorded data
bl.voltage = block.data.tenVm;             % 2 - 10 Vm voltage traces
bl.current = block.data.current;             % 1 - Preamp-filtered current
bl.scaledOut = block.data.scaledOut;           % 3 - Scaled Output

end