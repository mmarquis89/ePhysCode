function data = Acquire_Trial_Odor_Ionto(expNumber, trialDuration, iontoDuration, odor, valveID, Istep, Ihold)

% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, pinch valve acclimation, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% iontoDuration = [pre-ionto, ionto on, post-ionto] in seconds. Use [] if not iontophoresing on this trial.
% vHold = command voltage in mV (only used in I-clamp mode)
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial

%% SETUP TRIAL PARAMETERS

[data,n] = acquisitionSetup(expNumber, trialDuration, iontoDuration, [], odor, valveID, Istep, Ihold);
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
        %preStimPinch = zeros(sampRate * trialDuration(1), 1);
        preStimIso = zeros(sampRate * sum(trialDuration(1:2)), 1);
        postStim = zeros(sampRate * (trialDuration(4)-1), 1);
        postStimShuttle = zeros(sampRate * trialDuration(4), 1);
        
        % Make pinch and iso valve open vectors
        %pinchValveOpen = ones(sampRate * (sum(trialDuration(2:3))+1), 1);
        isoValveOpen = ones(sampRate * (trialDuration(3)+1), 1);     
        shuttleValveOpen = ones(sampRate * trialDuration(3), 1);
        
        % Put together full output vectors
        %pinchValveOut = [preStimPinch; pinchValveOpen; postStim];                                                    
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed
        %pinchValveOut(end) = 0;  
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;
        
        % Iontophoresis stim setup
        if ~isempty(iontoDuration)
            preIonto = zeros(sampRate * iontoDuration(1), 1);
            iontoStim = ones(sampRate * iontoDuration(2), 1);
            postIonto = zeros(sampRate * iontoDuration(3), 1);
            iontoStimOut = [preIonto; iontoStim; postIonto];
            iontoStimOut(end) = 0;
        else
            iontoStimOut = zeros(sampRate * sum(trialDuration),1);
        end
        
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
    s.addAnalogInputChannel('Dev2',0:5,'Voltage');
    for i=1:6
        s.Channels(1,i).InputType = 'SingleEnded';
    end
    
    if stimOn
        % Setup output channels
        s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');       % Shuttle valve       
        s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');    % 2-way iso valves
        %s.addDigitalChannel('Dev2', 'port0/line12:15', 'OutputOnly');   % Pinch valves
        s.addAnalogOutputChannel('Dev2', 0 , 'Voltage');                % Amplifier external command        
        s.addDigitalChannel('Dev2', 'port0/line1', 'OutputOnly');       % Ionto generator
        
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 7);
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
        %outputData(:, valveID + 5) = pinchValveOut;
        outputData(:,6) = Icommand;
        outputData(:,7) = iontoStimOut;
        s.queueOutputData(outputData); 
    else
        % Load output data for current step
        s.addAnalogOutputChannel('Dev2', 0, 'Voltage');
        s.queueOutputData(Icommand);
    end
    
    s.Rate = data(n).samprateout;
    x = s.startForeground();
    
%% RUN POST-PROCESSING AND SAVE DATA 
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
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')    % Pinch valve open
        plot([(trialDuration(1)+trialDuration(2)),(trialDuration(1)+trialDuration(2))],ylim, 'Color', 'k') % Clean valve open
        plot([sum(trialDuration(1:3)),sum(trialDuration(1:3))],ylim, 'Color', 'k')  % Shuttle valve closed
        if ~isempty(iontoDuration)
            iontoStart = iontoDuration(1);
            iontoEnd = sum(iontoDuration(1:2));
            plot([iontoStart, iontoStart], ylim, 'Color' , 'm')  % Iontophoresis start
            plot([iontoEnd, iontoEnd], ylim, 'Color', 'm')  % Iontophoresis end
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
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')  % Pinch valve open
        plot([(trialDuration(1)+trialDuration(2)),(trialDuration(1)+trialDuration(2))],ylim, 'Color', 'k') % Clean valve open
        plot([sum(trialDuration(1:3)),sum(trialDuration(1:3))],ylim, 'Color', 'k')  % Both valves closed
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
    
