function data = Acquire_Trial_Odor_Opto(expNumber,trialDuration, optoDuration, odor, valveID, Istep, Ihold)

% ===================================================================================================================
% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, no odor will be presented (but shutter can still operate)
% optoDuration = [pre-stim, shutter open, post-stim] in seconds (sum must match trialDuration)
        % Use [] if not using light stim on this trial.    
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.
% Ihold = the holding current in pA to consistently inject into the cell

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial
% ====================================================================================================================
%% SETUP TRIAL PARAMETERS

[data,n] = acquisitionSetup(expNumber, trialDuration, optoDuration, [], odor, valveID, Istep, Ihold);
sampRate = data(n).sampratein;
data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data

    % Check if trial will use stimulus
    if length(trialDuration) == 1
        stimOn = 0;
    else
        stimOn = 1;
    end

    % Set up stimulus data
    if stimOn        
        
        % Make pre- and post-stim output vectors
        preStimIso = zeros(sampRate * trialDuration(1), 1);
        postStim = zeros(sampRate * (trialDuration(3)-1), 1);
        postStimShuttle = zeros(sampRate * trialDuration(3), 1);
        
        % Make valve open vectors
        isoValveOpen = ones(sampRate * (trialDuration(2)+1), 1);     
        shuttleValveOpen = ones(sampRate * trialDuration(2), 1);
        
        % Put together full output vectors                                             
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;        
    end
    
    % Opto stim setup
    if ~isempty(optoDuration)
        minPulseLen = ceil(.0002 / (1/sampRate));  % TTL pulse must be at least 100 uSec to trigger shutter, use 200 to be safe
        preOpto = zeros(sampRate * optoDuration(1), 1);
        optoStim = zeros(sampRate * optoDuration(2), 1);            
            optoStim(1:minPulseLen) = 1; % Set trigger pulse at beginning of light stimulus
        postOpto = zeros(sampRate * optoDuration(3), 1);
            postOpto(1:minPulseLen) = 1; % Set offset trigger pulse after stimulus period
        optoStimOut = [preOpto; optoStim; postOpto];
        optoStimOut(end) = 0;
    else
        optoStimOut = zeros(sampRate * sum(trialDuration),1);
    end
        
    % Set up amplifier external command
    if ~isempty(Istep)
        preStepOut = ones(sampRate * data(n).stepStartTime, 1) * Ihold/2;
        stepOut = ones(sampRate * data(n).stepLength, 1) * (Ihold + Istep)/2;
        postStepOut = ones(sampRate * (sum(trialDuration) - (data(n).stepStartTime + data(n).stepLength)), 1) * Ihold/2;
        Icommand = [preStepOut; stepOut; postStepOut];
        if ~isempty(iontoDuration)
            iontoStepStart = (iontoDuration(1) + data(n).stepStartTime) * sampRate;
            iontoStepEnd = (iontoDuration(1) + data(n).stepStartTime + data(n).stepLength) * sampRate;
            Icommand(iontoStepStart:iontoStepEnd) = (Ihold + Istep)/2;
        end
    else
        Icommand = ones(sampRate*sum(trialDuration),1) * Ihold/2;
    end
    
%% Session based acquisition code for inputs  
    
%    CHANNEL SET-UP:
%       0  Scaled Out 
%       1  Im  
%       2  10Vm  
%       3  Amplifier Gain (Alpha)
%       4  Amplifier Filter Freq
%       5  Amplifier Mode
    
    % Setup session and input channels
    s = daq.createSession('ni');
    s.DurationInSeconds = sum(data(n).trialduration);
    s.Rate = data(n).sampratein;
    s.addAnalogInputChannel('Dev2',0:6,'Voltage');
    for i=1:7
        s.Channels(1,i).InputType = 'SingleEnded';
    end
    
    if stimOn
        % Setup output channels
        s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');       % Shuttle valve       
        s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');    % 2-way iso valves
        s.addAnalogOutputChannel('Dev2', 0 , 'Voltage');                % Amplifier external command        
        s.addDigitalChannel('Dev2', 'port0/line12', 'OutputOnly');       % Shutter driver command
        
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 7);
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
        outputData(:,6) = Icommand;
        outputData(:,7) = optoStimOut;
    else
        % Load output data for current step
        s.addAnalogOutputChannel('Dev2', 0, 'Voltage');
        outputData(:,1) = Icommand;
        % Queue shutter driver command
        s.addDigitalChannel('Dev2', 'port0/line12', 'OutputOnly');  
        outputData(:,2) = optoStimOut;
    end
    s.queueOutputData(outputData);
    
     % Save all command data
    data(n).outputData = outputData;
    
    s.Rate = data(n).samprateout;
    x = s.startForeground();
    
%% RUN POST-PROCESSING AND SAVE DATA 
    data(n).shutterTelegraph = x(:,7);
    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, x, n);
%% PLOTS
    
    time = 1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration);
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1650 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), scaledOut(.05*sampRate:end));
    if strcmp(data(n).scaledOutMode, 'V')
        ylabel('Vm (mV)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        ylabel('Im (pA)');
    end
    if stimOn
        plot([trialDuration(1), trialDuration(1)],ylim, 'Color', 'k') % Odor stim onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Odor stim offset
        if ~isempty(iontoDuration)
            iontoStart = iontoDuration(1);
            iontoEnd = sum(iontoDuration(1:2));
            plot([iontoStart, iontoStart], ylim, 'Color' , 'r')  % Iontophoresis start
            plot([iontoEnd, iontoEnd], ylim, 'Color', 'r')  % Iontophoresis end
        end
    end
    title(['Trial Number ' num2str(n) ]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
     
    figure (2); clf; hold on
    set(gcf,'Position',[10 50 1650 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    if strcmp(data(n).scaledOutMode, 'V')
        plot(time(.05*sampRate:end), current(.05*sampRate:end)); 
        ylabel('Im (pA)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        plot(time(.05*sampRate:end), tenVm(.05*sampRate:end));
        ylabel('Vm (mV)');
    end
    if stimOn
        plot([trialDuration(1), trialDuration(1)],ylim, 'Color', 'k') % Odor stim onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Odor stim offset
        if ~isempty(iontoDuration)
            iontoStart = iontoDuration(1);
            iontoEnd = sum(iontoDuration(1:2));
            plot([iontoStart, iontoStart], ylim, 'Color' , 'm')  % Iontophoresis start
            plot([iontoEnd, iontoEnd], ylim, 'Color', 'm')  % Iontophoresis end
        end
    end
    title(['Trial Number ' num2str(n) ]);
    box off;
    
    % Plot input resistance across experiment
    figure(3); clf; hold on
    plotRins(data);
    
