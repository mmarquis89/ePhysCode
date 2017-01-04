function data = Acquire_Trial_Odor(expNumber,trialDuration, odor, valveID, Istep, Ihold)

% ===================================================================================================================
% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.
% Ihold = the holding current in pA to consistently inject into the cell

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial
% ====================================================================================================================

%% SETUP TRIAL PARAMETERS AND STIMULUS DATA
    
    % Run initial setup function
    [data, n] = acquisitionSetup(expNumber,trialDuration, [], [], odor, valveID, Istep, Ihold);
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
    
    % Set up amplifier external current command
    if ~isempty(Istep)
        preStepOut = ones(sampRate*data(n).stepStartTime,1) * Ihold/2;
        stepOut = (ones(sampRate*data(n).stepLength, 1) * (Ihold + Istep)/2);
        postStepOut = ones(sampRate * (sum(trialDuration) - (data(n).stepStartTime + data(n).stepLength)), 1) * Ihold/2;
        Icommand = [preStepOut; stepOut; postStepOut] - data(n).DAQOffset/2;
    else
        Icommand = (ones(sampRate*sum(trialDuration),1) * Ihold/2) - data(n).DAQOffset/2;
    end

%% SESSION-BASED ACQUISITION CODE
    
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
    s.addAnalogInputChannel('Dev2', 0:5,'Voltage');
    for iChan=1:6
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    
    if stimOn
        % Setup output channels
        s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');       % Shuttle valve        
        s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');    % 2-way iso valves
        s.addAnalogOutputChannel('Dev2', 0, 'Voltage');                % Amplifier external command
               
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 6);
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
        outputData(:,6) = Icommand;
        s.queueOutputData(outputData); 
    else
        % Load output data for current step
        s.addAnalogOutputChannel('Dev2', 0, 'Voltage');  
        outputData = Icommand;
    end
    s.queueOutputData(outputData); 
        
    % Save all command data
    data(n).outputData = outputData;
    
    s.Rate = data(n).samprateout;
    rawAcqData = s.startForeground();

%% RUN POST-PROCESSING AND SAVE DATA
    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, rawAcqData, n);
 
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
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'k')    % Odor valve onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Odor valve offset
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
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')  % Odor valve onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'r')  % Odor valve offset
    end
    title(['Trial Number ' num2str(n) ]);
    box off;
    
    % Plot input resistance across experiment
    figure(3); clf; hold on
    plotRins(data);
    
    