function [data, n] = acquisitionSetup(acqSettings)
% ===========================================================================================================================
% The purpose of this function is to consolidate all the setup steps that are common across different types of acquisition 
% functions, to minimize the risk of inconsistencies when I change one function.
% 
% If trial is not using iontophoresis/light stimulus or pressure ejection, pass an empty vector for those arguments.
% ===========================================================================================================================

%%  CREATE DIRECTORIES AND UPDATE BACKUP LOG AS NEEDED
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate])
        mkdir(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate]);
        pathLog = fopen('C:/Users/Wilson Lab/Documents/MATLAB/Data/_Server backup logs/PendingBackup', 'a');
        fprintf(pathLog, ['\r\n', strDate]);
        fclose('all');
    end

%% CREATE DATA STRUCTURE AS NEEDED
    D = dir(['Data/', strDate,'/WCwaveform_',strDate,'_E',num2str(acqSettings.expNum),'.mat']);
    if isempty(D)           
        % If no saved data exists then this is the first trial
        n = 1 ;
    else
        % Load current data file
        load(['Data/', strDate,'/WCwaveform_',strDate,'_E',num2str(acqSettings.expNum),'.mat']','data');
        n = length(data)+1;
    end

%% SAVE CURRENT GIT HASH

    data(n).gitHash = getCodeStamp(mfilename('fullpath'));

%% RECORD TRIAL PARAMETERS
 
    data(n).odor = acqSettings.odor;
    data(n).trialduration = acqSettings.trialDuration;      % Trial duration in sec [pre-stim, valves open, post-stim]
    data(n).altStimDuration = acqSettings.altStimDuration;  % Non-odor stimulus (e.g. iontophoresis, LED illumination) duration in sec [pre-stim, stim on, post-stim]
    data(n).altStimType = acqSettings.altStimType;          % String describing the type of alternative stim being used (e.g. 'opto', 'ionto', 'eject', etc.)
    data(n).valveID = acqSettings.valveID;
    data(n).shutterTelegraph = [];                          % Output from shutter driver reporting physical location of shutter
    data(n).cameraStrobe = [];                              % Input from the behavior camera reporting exact integration times for each frame
    
  % Current command parameters
    data(n).Istep = acqSettings.Istep;
    data(n).Ihold = acqSettings.Ihold;
    data(n).stepStartTime = acqSettings.stepStartTime; 
    data(n).stepLength = acqSettings.stepLength;
    data(n).DAQOffset = acqSettings.DAQOffset;  % The amount of current the DAQ is injecting when the command is 0. Will be subtracted from current command to offset this.
    
  % Experiment information
    data(n).date = strDate;                     % experiment date
    data(n).expNum = acqSettings.expNum;        % experiment number
    data(n).trial = n;                          % trial number
    data(n).sampleTime = clock;
    
  % Sampling rates
    data(n).sampratein = acqSettings.sampRate;             % input sample rate
    data(n).samprateout = acqSettings.sampRate;            % output sample rate becomes input rate as well when both input and output present
        
  % Amplifier gains to be read or used
    data(n).variableGain = NaN;                % Amplifier 1 alpha
    data(n).variableOffset1 = NaN;             % Amplifier 1 variable output offset. Determined empirically.
    data(n).ImGain = 10;
    data(n).VmGain = 100;
    data(n).ImOffset1 = 0;  
    
  % Save acqSettings object itself for good measure
    data(n).acqSettings = acqSettings;
end