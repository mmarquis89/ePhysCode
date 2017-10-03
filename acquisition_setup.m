function [data, trialNum] = acquisition_setup(acqSettings)
% ===========================================================================================================================
% The purpose of this function is to consolidate all the setup steps that are common across different types of acquisition 
% functions, to minimize the risk of inconsistencies when I change one function.
% 
% If trial is not using iontophoresis/light stimulus or pressure ejection, pass an empty vector for those arguments.
% ===========================================================================================================================

%%  CREATE DIRECTORIES AND UPDATE BACKUP LOG AS NEEDED
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate])
        mkdir(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate]);
    end

%% DETERMINE TRIAL NUMBER

    D = dir(['C:/Users/Wilson Lab/Dropbox (HMS)/Data/', strDate,'/WCwaveform_',strDate,'_E',num2str(acqSettings.expNum),'*.mat']);
    trialNum = length(D) + 1;

%% SAVE CURRENT GIT HASH

    data.gitHash = get_code_stamp(mfilename('fullpath'));

%% RECORD TRIAL PARAMETERS
 
    data.odor = acqSettings.odor;
    data.trialduration = acqSettings.trialDuration;      % Trial duration in sec [pre-stim, valves open, post-stim]
    data.altStimDuration = acqSettings.altStimDuration;  % Non-odor stimulus (e.g. iontophoresis, LED illumination) duration in sec [pre-stim, stim on, post-stim]
    data.altStimType = acqSettings.altStimType;          % String describing the type of alternative stim being used (e.g. 'opto', 'ionto', 'eject', etc.)
    data.valveID = acqSettings.valveID;
    data.shutterTelegraph = [];                          % Output from shutter driver reporting physical location of shutter
    data.cameraStrobe = [];                              % Input from the behavior camera reporting exact integration times for each frame
   
  % Current command parameters
    data.Istep = acqSettings.Istep;
    data.Ihold = acqSettings.Ihold;
    data.stepStartTime = acqSettings.stepStartTime; 
    data.stepLength = acqSettings.stepLength;
    data.DAQOffset = acqSettings.DAQOffset;  % The amount of current the DAQ is injecting when the command is 0. Will be subtracted from current command to offset this.
    
  % Experiment information
    data.trial = trialNum;
    data.date = strDate;                     % experiment date
    data.expNum = acqSettings.expNum;        % experiment number
    data.sampleTime = clock;
    
  % Sampling rates
    data.sampratein = acqSettings.sampRate;             % input sample rate
    data.samprateout = acqSettings.sampRate;            % output sample rate becomes input rate as well when both input and output present
        
  % Amplifier gains to be read or used
    data.variableGain = NaN;                % Amplifier 1 alpha
    data.variableOffset1 = NaN;             % Amplifier 1 variable output offset. Determined empirically.
    data.ImGain = 10;
    data.VmGain = 100;
    data.ImOffset1 = 0;  
    
  % Save acqSettings object itself for good measure
    warning off
    data.acqSettings = struct(acqSettings);
    warning on
end