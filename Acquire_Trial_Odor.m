function data = Acquire_Trial_Odor(expNumber,trialDuration, odor, valveID, Istep, Ihold)

% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, pinch valve acclimation, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.
% Ihold = the holding current in pA to consistently inject into the cell

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial
  
%% SETUP TRIAL PARAMETERS
    
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
        %preStimPinch = zeros(sampRate * trialDuration(1), 1);
        preStimIso = zeros(sampRate * sum(trialDuration(1:2)), 1);
        postStim = zeros(sampRate * (trialDuration(4)-1), 1);
        postStimShuttle = zeros(sampRate * trialDuration(4), 1);
        
        % Make pinch and iso valve open vectors
        %pinchValveOpen = ones(sampRate * (sum(trialDuration(2:3))+1), 1);
        isoValveOpen = ones(sampRate * (trialDuration(3)+1), 1);     
        shuttleValveOpen = ones(sampRate * trialDuration(3),1);
        
        % Put together full output vectors
        %pinchValveOut = [preStimPinch; pinchValveOpen; postStim];                                                    
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed
        %pinchValveOut(end) = 0;  
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;
    end
    
    % Set up amplifier external command
    if ~isempty(Istep)
        preStepOut = ones(sampRate*data(n).stepStartTime,1) * Ihold/2;
        stepOut = (ones(sampRate*data(n).stepLength, 1) * (Ihold + Istep)/2);
        postStepOut = ones(sampRate * (sum(trialDuration) - (data(n).stepStartTime + data(n).stepLength)), 1) * Ihold/2;
        Icommand = [preStepOut; stepOut; postStepOut] - data(n).DAQOffset/2;
%         Icommand = (command'+4)/2;
%         Icommand(end) = 4/2;
        % Extra current steps during stim to test input resistance
%         if stimOn
%             steps = [zeros(uint32(sampRate*(sum(trialDuration(1:2))-1.9)), 1); ones(uint32(sampRate*0.5),1); zeros(uint32(sampRate*1.4),1); zeros(uint32(sampRate*1),1); ones(uint32(sampRate*0.5),1); zeros(uint32(sampRate*(trialDuration(4)-0.5)),1)];
%             Icommand = Icommand + (steps * Istep)/2;
%         end
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
        %s.addDigitalChannel('Dev2', 'port0/line12:15', 'OutputOnly');   % Pinch valves
        s.addAnalogOutputChannel('Dev2', 0, 'Voltage');                % Amplifier external command
               
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 6);
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
        %outputData(:, valveID + 5) = pinchValveOut;
        outputData(:,6) = Icommand;
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
 
%% PLOT FIGURES
    
    time = 1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration);
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1850 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), scaledOut(.05*sampRate:end));
    if strcmp(data(n).scaledOutMode, 'V')
        ylabel('Vm (mV)');
    elseif strcmp(data(n).scaledOutMode, 'I')
        ylabel('Im (pA)');
    end
    if stimOn
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')    % Pinch valve open
        plot([(trialDuration(1)+trialDuration(2)),(trialDuration(1)+trialDuration(2))],ylim, 'Color', 'r') % Clean valves open
        plot([sum(trialDuration(1:3)),sum(trialDuration(1:3))],ylim, 'Color', 'r')  % Shuttle valve closed
    end
    title(['Trial Number ' num2str(n) ]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
        
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
    if stimOn
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')  % Pinch valve open
        plot([(trialDuration(1)+trialDuration(2)),(trialDuration(1)+trialDuration(2))],ylim, 'Color', 'r') % Clean valve open
        plot([sum(trialDuration(1:3)),sum(trialDuration(1:3))],ylim, 'Color', 'r')  % Shuttle valve closed
    end
    title(['Trial Number ' num2str(n) ]);
    box off;
    
    % Plot input resistance across experiment
    figure(3); clf; hold on
%     set(gcf, 'Position', [1050 40 620 400], 'Color', [1 1 1]);
%     set(gca, 'LooseInset', get(gca, 'TightInset'));
%     Rins = [data.Rin];
%     plot(1:length(Rins), Rins, 'LineStyle', 'none', 'Marker', 'o');
%     xlim([0, length(Rins)+1]);
%     xlabel('Trial');
%     ylabel('Rin (GOhm)');
    plotRins(data);
    
    