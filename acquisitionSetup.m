function [data, n] = acquisitionSetup(expNumber, trialDuration, iontoDuration, ejectionDuration, odor, valveID, Istep, Ihold)
% ===========================================================================================================================
% The purpose of this function is to consolidate all the setup steps that are common across different types of acquisition 
% functions, to minimize the risk of inconsistencies when I change one function.
% 
% If trial is not using iontophoresis or pressure ejection, pass an empty vector for those arguments.
% ===========================================================================================================================

%%  CREATE DIRECTORIES AS NEEDED
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate])
        mkdir(['C:/Users/Wilson Lab/Documents/MATLAB/Data/', strDate]);
    end
    if ~isdir(['U:/Data Backup/', strDate])
        mkdir(['U:/Data Backup/', strDate]);
    end

%% CREATE DATA STRUCTURE AS NEEDED
    D = dir(['Data/', strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']);
    if isempty(D)           
        % If no saved data exists then this is the first trial
        n = 1 ;
    else
        % Load current data file
        load(['Data/', strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']','data');
        n = length(data)+1;
    end

    %% SAVE CURRENT GIT HASH

    data(n).gitHash = getCodeStamp(mfilename('fullpath'));

 %% RECORD TRIAL PARAMETERS
 
    data(n).odor = odor;
    sampRate = 20000;   % Note hardcoded sampling rate
    data(n).trialduration = trialDuration;  % Trial duration in sec [pre-stim, valves open, post-stim]
    data(n).ejectionDuration = ejectionDuration; % length of picopump activation in msec
    data(n).iontoDuration = iontoDuration;  % Ionto duration in sec [pre-ionto, ionto on, post-ionto]
    data(n).valveID = valveID;

  % Current command parameters
    data(n).Istep = Istep;
    data(n).Ihold = Ihold;
    data(n).stepStartTime = 1; % Note hardcoded parameters here
    data(n).stepLength = 1;
    data(n).DAQOffset = 0.5;  % The amount of current the DAQ is injecting when the command is 0. Will be subtracted from current command to offset this.
    
  % Experiment information
    data(n).date = strDate;            % experiment date
    data(n).expnumber = expNumber;     % experiment number
    data(n).trial = n;                 % trial number
    data(n).sampleTime = clock;
    
  % Sampling rates
    data(n).sampratein = sampRate;             % input sample rate
    data(n).samprateout = sampRate;            % output sample rate becomes input rate as well when both input and output present
        
  % Amplifier gains to be read or used
    data(n).variableGain = NaN;                % Amplifier 1 alpha
    data(n).variableOffset1 = NaN;             % Amplifier 1 variable output offset. Determined empirically.
    data(n).ImGain = 10;
    data(n).VmGain = 100;
    data(n).ImOffset1 = 0;  
    
end