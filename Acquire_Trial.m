function [data] = Acquire_Trial(acqSettings)

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

% The acqSettings object also has these properties which already have default "semi-hardcoded" values:
    % sampRate (default = 20000): input and output sampling rate for the trial. 
    % stepStartTime (default = 1): time in seconds from the start of the trial to begin the current test step. 
    % stepLength (default = 1): length of current test step in seconds. 
    % DAQOffset (default = 0.7): the amount of current the DAQ is injecting when the command is 0. 
    % altStimChan (default = 'port0/line12'): the name of the output channel on the DAQ for the alternate stimulus. 
    % frameRate (default = 30): The rate (in FPS) at which the behavior camera should acquire images during the trial
        
% Acquired Ephys data is saved as a single file for each trial.
% ====================================================================================================================

%% SETUP TRIAL PARAMETERS AND STIMULUS DATA

    % Pull variables from settings
    trialDuration = acqSettings.trialDuration;
    altStimDuration = acqSettings.altStimDuration;
    altStimType = acqSettings.altStimType;
    altStimParam = acqSettings.altStimParam;
    valveID = acqSettings.valveID;
    Ihold = acqSettings.Ihold;
    Istep = acqSettings.Istep;
    
    % Run initial setup function
    [data, trialNum] = acquisitionSetup(acqSettings);
    sampRate = data.sampratein;
    data.acquisition_filename = mfilename('fullpath');       % Saves name of mfile that generated data    
    
    % Check if trial will use stimulus
    if length(trialDuration) == 1
        stimOn = 0;
    else
        stimOn = 1;
    end
    
    % Make sure temporary camera directory doesn't already have images
    tempDir = 'C:/tmp/*';
    dirContents = dir(tempDir(1:end-1));
    if length(dirContents) > 2
        disp('Warning: one or more images already exist in temporary video frame save directory')
    end
    delete('C:/tmp/*.tif');  
        
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
                altStimOut(end) = 0; % Make sure stim is off at the end
            case 'opto'                
                % Check to make sure LED duty cycle parameter is valid
                if isempty(altStimParam)
                   disp('Warning: no LED duty cycle parameter provided...using a 100% duty cycle')
                   dutyCycle = 100;
                elseif altStimParam < 1 || altStimParam > 100
                   disp('Warning: invalid LED duty cycle parameter provided...using a 100% duty cycle')
                   dutyCycle = 100;
                else
                    dutyCycle = altStimParam;
                end
                % Optogenetic stimulus setup          
                preOpto = zeros(sampRate * altStimDuration(1), 1);
                optoStim_pre = zeros(sampRate * altStimDuration(2), 1);
                optoStim = optoStim_pre;
                for iSamp = 1:100:length(optoStim_pre)
                    optoStim(iSamp:iSamp + dutyCycle - 1) = 1;
                end
                postOpto = zeros(sampRate * altStimDuration(3), 1);
                altStimOut = [preOpto; optoStim; postOpto];
                altStimOut(end) = 0; % Make sure stim is off at the end
            case 'eject'
                % Pressure ejection setup
                preEject = zeros(sampRate * altStimDuration(1), 1);
                ejectStim = ones(sampRate * altStimDuration(2), 1);
                postEject = zeros(sampRate * altStimDuration(3), 1);
                altStimOut = [preEject; ejectStim; postEject];
                altStimOut(end) = 0; % Make sure stim is off at the end
            otherwise 
                disp('Warning: invalid altStimType. Running trial with no alternate stimulus');
        end
    else
        altStimOut = zeros(sampRate * sum(trialDuration),1);
    end
    
    % Set up amplifier external current command
    commandScalar = 4; % The number to divide desired command in pA by to get the correct voltage output
    if ~isempty(Istep)
        preStepOut = ones(sampRate*data.stepStartTime,1) * Ihold/commandScalar;
        stepOut = (ones(sampRate*data.stepLength, 1) * (Ihold + Istep)/commandScalar);
        postStepOut = ones(sampRate * (sum(trialDuration) - (data.stepStartTime + data.stepLength)), 1) * Ihold/commandScalar;
        Icommand = [preStepOut; stepOut; postStepOut] - data.DAQOffset/commandScalar;
    else
        Icommand = (ones(sampRate*sum(trialDuration),1) * Ihold/commandScalar) - data.DAQOffset/commandScalar;
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
    s.DurationInSeconds = sum(data.trialduration);
    s.Rate = data.sampratein;
    s.addAnalogInputChannel('Dev2', 0:5,'Voltage');              % Amplifier data and telegraphs 
    for iChan=1:6
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    s.addDigitalChannel('Dev2', 'port0/line29', 'InputOnly');    % Camera strobe input
    
    % Set up output channels
    digiOutputChannels = {'port0/line0', ...        % Olfactometer shuttle valve
                      'port0/line8:11', ...         % Olfactometer 2-way iso valves
                      acqSettings.altStimChan, ...  % Alternate stim command
                      'port0/line28'};              % Camera trigger command 
                  
    s.addDigitalChannel('Dev2', digiOutputChannels, 'OutputOnly');
    s.addAnalogOutputChannel('Dev2', 0, 'Voltage'); % Amplifier external command

    % Load output data for each channel
    outputData = zeros(sum(trialDuration*sampRate), 8);
    if stimOn
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
    end
    outputData(:,6) = altStimOut; 
    outputData(:,7) = camTrigOut;
    outputData(:,8) = Icommand;

    % Save all command data and queue for output
    data.outputData = outputData;
    s.queueOutputData(outputData);

    % Start acquisition
    s.Rate = data.samprateout;
    rawAcqData = s.startForeground();

%% RUN POST-PROCESSING AND SAVE DATA

    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, rawAcqData, trialNum);
    
    % Move camera files from temp directory to local and network folders
    savePath = ['C:/Users/Wilson Lab/Dropbox (HMS)/Data/_Movies/', data.date, '/E', num2str(acqSettings.expNum), '_T', num2str(trialNum), '/'];
    
    % Create specific save directory if it doesn't already exist
    if ~isdir(savePath)
        mkdir(savePath);
    end
    
%     % Check to make sure the camera saved the expected number of pictures
    framesRequested = sum(data.outputData(:,7));
    framesSaved = length(dir([tempDir, '.tif*']));
    if framesRequested ~= framesSaved && framesSaved > 0
       disp('Warning! Number of video frames saved does not match number of frames requested!')
       errorMsg = ['Requested: ', num2str(framesRequested), '  Saved: ', num2str(framesSaved)];
       errorFile = fopen([savePath, 'frameCountError.txt'], 'wt');
       fprintf(errorFile, errorMsg);
       fclose('all');
    end
    
    % Move images
    try
        movefile(tempDir, savePath, 'f');
    catch
        disp('Warning: camera not recording!')
    end

%% PLOT FIGURES
    
    % Make time vector for x-axis
    time = 1/data.sampratein:1/data.sampratein:sum(data.trialduration);
    
    % Create figure and plot scaled out
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), smooth(scaledOut(.05*sampRate:end),1));
    if strcmp(data.scaledOutMode, 'V')
        ylabel('Vm (mV)');
    elseif strcmp(data.scaledOutMode, 'I')
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
    title(['Trial Number ' num2str(trialNum) ]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
    
    % Plot whichever signal (Im or 10Vm) is not the same as scaled out
    figure (2); clf; hold on
    set(gcf,'Position',[10 50 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    if strcmp(data.scaledOutMode, 'V')
        plot(time(.05*sampRate:end), smooth(current(.05*sampRate:end),1)); 
        ylabel('Im (pA)');
    elseif strcmp(data.scaledOutMode, 'I')
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
    title(['Trial Number ' num2str(trialNum) ]);
    box off;
 
% baseline = mean(current(sampRate:trialDuration(1)*sampRate));
% phase1 = mean(current(trialDuration(1)*sampRate:sum(trialDuration(1:2))*sampRate));
% phase2 = mean(current(sum(trialDuration(1:2))*sampRate:(sum(trialDuration(1:2))+1)*sampRate));
% titleStr = ['Phase 1 = ', num2str(round(abs(phase1-baseline),1)), ' pA, Phase 2 = ', num2str(round(abs(phase2-baseline),2)), ' pA'];
% title(titleStr);  
%  disp(titleStr);
    % Plot input resistance across experiment
    figure(3); clf; hold on
    set(gcf, 'Position', [1250 40 620 400], 'Color', [1 1 1]);
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\',data.date, [data.date, '_E', num2str(data.expNum), '_Rinputs.mat']), 'Rins');
    plot(1:length(Rins), Rins, 'LineStyle', 'none', 'Marker', 'o');
    xlim([0, length(Rins)+1]);
    xlabel('Trial');
    ylabel('Rin (GOhm)'); % Not using tex markup to troubleshoot crashing issue: ylabel('R_{input}  (G\Omega)');

    