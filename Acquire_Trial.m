function data = Acquire_Trial(acqSettings)

% ===================================================================================================================
% acqSettings: an acqSettings object with the following properties: 
    % expNum = experiment (fly or cell) number
    % trialDuration = [pre-stim, clean valve open, post-stim] in seconds
            % If trialDuration is a single integer, a trace of that duration will be acquired
    % altStimDuration = [pre-stim, stim on, post-stim] in seconds (sum must match trialDuration)
            % Pass '[]' if not using alternate stim on this trial. 
    % altStimType = String describing the type of alternative stim being used. Pass '[]' for no alt stim. Valid types are:
            % 'opto'
            % 'ionto'
            % 'eject'
    % odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
    % valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (pass '[]' if no stim)
    % Istep = the size of the current step to use at the beginning of the trial in pA. Pass '[]' to skip the step.
    % Ihold = the holding current in pA to constantly inject into the cell

% The acqSettings object also has these properties which already have default values:
    % sampRate (default = 20000): input and output sampling rate for the trial. 
    % stepStartTime (default = 1): time in seconds from the start of the trial to begin the current step. 
    % stepLength (default = 1): length of current step in seconds. 
    % DAQOffset (default = 4.25): the amount of current the DAQ is injecting when the command is 0. 
    % altStimChan (default = 'port0/line12'): the name of the output channel on the DAQ for the alternate stimulus. 
    % frameRate (default = 30): The rate (in FPS) at which the behavior camera should acquire images during the trial
        
% Acquired Ephys data is saved as a single file for each trial.
% ====================================================================================================================

%% SETUP TRIAL PARAMETERS AND STIMULUS DATA
    
    % Pull variables from settings
    trialDuration = acqSettings.trialDuration;
    altStimDuration = acqSettings. altStimDuration;
    altStimType = acqSettings.altStimType;
    valveID = acqSettings.valveID;
    Ihold = acqSettings.Ihold;
    Istep = acqSettings.Istep;
    
    % Run initial setup function
    [data, n] = acquisitionSetup(acqSettings);
    sampRate = data(n).sampratein;
    data(n).acquisition_filename = mfilename('fullpath');       % Saves name of mfile that generated data

    % Check if trial will use stimulus
    if length(trialDuration) == 1
        stimOn = 0;
    else
        stimOn = 1;
    end
    
    % Set up odor stimulus data
    if stimOn        
        % Make pre- and post-stim output vectors
        preStimIso = zeros(sampRate * trialDuration(1), 1);
        postStim = zeros(sampRate * (trialDuration(3)-1), 1);
        postStimShuttle = zeros(sampRate * trialDuration(3), 1);
        
        % Make open-valve vectors
        isoValveOpen = ones(sampRate * (trialDuration(2)+1), 1);     
        shuttleValveOpen = ones(sampRate * trialDuration(2), 1);
        
        % Put together full output vectors                                                 
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed 
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;
    else
        shuttleValveOut = zeros(sampRate*sum(trialDuration), 1);
        isoValveOut = zeros(sampRate*sum(trialDuration), 1);
    end
    
    % Alternative stimulus setup
    if ~isempty(altStimDuration)
        switch lower(altStimType)
            case 'ionto'
                % Iontophoresis stimulus setup
                preIonto = zeros(sampRate * altStimDuration(1), 1);
                iontoStim = ones(sampRate * altStimDuration(2), 1);
                postIonto = zeros(sampRate * altStimDuration(3), 1);
                altStimOut = [preIonto; iontoStim; postIonto];
                altStimOut(end) = 0;
            case 'opto'
                % Optogenetic stimulus setup
                minPulseLen = ceil(.0002 / (1/sampRate));  % TTL pulse must be at least 100 uSec to trigger shutter, use 200 to be safe
                preOpto = zeros(sampRate * altStimDuration(1), 1);
                optoStim = zeros(sampRate * altStimDuration(2), 1);
                optoStim(1:minPulseLen) = 1; % Set trigger pulse at beginning of light stimulus
                postOpto = zeros(sampRate * altStimDuration(3), 1);
                postOpto(1:minPulseLen) = 1; % Set offset trigger pulse after stimulus period
                altStimOut = [preOpto; optoStim; postOpto];
                altStimOut(end) = 0;
            case 'eject'
                % Pressure ejection setup
                preEject = zeros(sampRate * altStimDuration(1), 1);
                ejectStim = ones(sampRate * altStimDuration(2), 1);
                postEject = zeros(sampRate * altStimDuration(3), 1);
                altStimOut = [preEject; ejectStim; postEject];
                altStimOut(end) = 0;
            otherwise 
                disp('Warning: invalid altStimType. Running trial with no alternate stimulus');
        end
    else
        altStimOut = zeros(sampRate * sum(trialDuration),1);
    end
    
    % Set up amplifier external current command
    if ~isempty(Istep)
        preStepOut = ones(sampRate*data(n).stepStartTime,1) * Ihold/2;
        stepOut = (ones(sampRate*data(n).stepLength, 1) * (Ihold + Istep)/2);
        postStepOut = ones(sampRate * (sum(trialDuration) - (data(n).stepStartTime + data(n).stepLength)), 1) * Ihold/2;
        Icommand = [preStepOut; stepOut; postStepOut] - data(n).DAQOffset/2;
    else
        Icommand = (ones(sampRate*sum(trialDuration),1) * Ihold/2) - data(n).DAQOffset/2;
    end
    
    % Set up camera trigger output
    camTrigOut = zeros(sampRate * sum(trialDuration),1);
    triggerInterval = round(sampRate / acqSettings.frameRate);
    camTrigOut(1:triggerInterval:end) = 1;
    

%% SESSION-BASED ACQUISITION CODE
    
%    CHANNEL SET-UP:
%       0  Scaled Out 
%       1  Im  
%       2  10Vm  
%       3  Amplifier Gain (Alpha)
%       4  Amplifier Filter Freq
%       5  Amplifier Mode
%       6  Camera strobe input
    
    % Setup session and input channels
    s = daq.createSession('ni');
    s.DurationInSeconds = sum(data(n).trialduration);
    s.Rate = data(n).sampratein;
    s.addAnalogInputChannel('Dev2', 0:5,'Voltage');                      % Amplifier data and telegraphs 
    for iChan=1:6
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    s.addDigitalChannel('Dev2', 'port0/line29', 'InputOnly');            % Camera strobe input
    
    % Setup output channels
    s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');            % Olfactometer shuttle valve        
    s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');         % Olfactometer 2-way iso valves
    s.addAnalogOutputChannel('Dev2', 0, 'Voltage');                      % Amplifier external command
    s.addDigitalChannel('Dev2', acqSettings.altStimChan, 'OutputOnly');  % Alternate stim command
    s.addDigitalChannel('Dev2', 'port0/line28', 'OutputOnly');           % Camera trigger command
    
    % Load output data for each channel
    outputData = zeros(sum(trialDuration*sampRate), 8);
    outputData(:,1) = shuttleValveOut;
    outputData(:, valveID + 1) = isoValveOut;
    outputData(:,6) = Icommand;
    outputData(:,7) = altStimOut; 
    outputData(:,8) = camTrigOut;

    % Save all command data and queue for output
    data(n).outputData = outputData;
    s.queueOutputData(outputData);
    
    % Start acquisition
    s.Rate = data(n).samprateout;
    rawAcqData = s.startForeground();

%% RUN POST-PROCESSING AND SAVE DATA
    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, rawAcqData, n);
    
  % Move camera files from temp directory to local and network folders
  tempDir = 'C:\tmp\fc2_save\*';
  savePath = ['C:\Users\Wilson Lab\Documents\MATLAB\Data\_Movies\', data(n).date, '\E', num2str(acqSettings.expNum), '_T', num2str(n), '\'];
  networkPath = ['U:\Data Backup\_Movies\', data(n).date, '\E', num2str(acqSettings.expNum), '_T', num2str(n), '\'];
  if ~isdir(savePath)
     mkdir(savePath); 
  end
  if ~isdir(networkPath)
     mkdir(networkpath) 
  end
  try
     copyfile(tempDir, savePath, 'f');
     movefile(tempDir, networkPath, 'f');
  catch
      disp('Warning: camera not recording!')
  end
  
  
%% PLOT FIGURES
    
    % Make time vector for x-axis
    time = 1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration);
    
    % Create figure and plot scaled out
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), scaledOut(.05*sampRate:end));
    if strcmp(data(n).scaledOutMode, 'V')
        ylabel('Vm (mV)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        ylabel('Im (pA)');
    end
    
    % Plot annotation lines if stimulus was presented
    if stimOn
        plot([trialDuration(1), trialDuration(1)],ylim, 'Color', 'k') % Odor stim onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Odor stim offset
        if ~isempty(altStimDuration)
            altStimStart = altStimDuration(1);
            altStimEnd = sum(altStimDuration(1:2));
            plot([altStimStart, altStimStart], ylim, 'Color' , 'r')  % Alternate stim start
            plot([altStimEnd, altStimEnd], ylim, 'Color', 'r')  % Alternate stim end
        end
    end
    title(['Trial Number ' num2str(n) ]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
    
    % Plot whichever signal (Im or 10Vm) is not the same as scaled out
    figure (2); clf; hold on
    set(gcf,'Position',[10 50 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    if strcmp(data(n).scaledOutMode, 'V')
        plot(time(.05*sampRate:end), current(.05*sampRate:end)); 
        ylabel('Im (pA)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        plot(time(.05*sampRate:end), tenVm(.05*sampRate:end));
        ylabel('Vm (mV)');
    end
    
    % Plot annotation lines if stimulus was presented
    if stimOn
        plot([trialDuration(1), trialDuration(1)],ylim, 'Color', 'k') % Odor stim onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Odor stim offset
        if ~isempty(altStimDuration)
            altStimStart = altStimDuration(1);
            altStimEnd = sum(altStimDuration(1:2));
            plot([altStimStart, altStimStart], ylim, 'Color' , 'r')  % Alternate stim start
            plot([altStimEnd, altStimEnd], ylim, 'Color', 'r')  % Alternate stim end
        end
    end
    title(['Trial Number ' num2str(n) ]);
    box off;
    
    % Plot input resistance across experiment
    figure(3); clf; hold on
    plotRins(data);
    
    