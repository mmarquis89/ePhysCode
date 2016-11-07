function data = Acquire_Trial_Odor_Ionto(expNumber,trialDuration, iontoDuration, odor, valveID)

% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, pinch valve acclimation, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% iontoDuration = [pre-ionto, ionto on, post-ionto] in seconds. Use [] if not iontophoresing on this trial.
% vHold = command voltage in mV (only used in I-clamp mode)
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial

%%  CREATE DIRECTORIES AS NEEDED
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate])
        mkdir(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate]);
    end
    if ~isdir(['U:/Data Backup/', strDate])
        mkdir(['U:/Data Backup/', strDate]);
    end

%% CREATE DATA STRUCTURE AS NEEDED
    D = dir([strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']);
    if isempty(D)           % if no saved data exists then this is the first trial
        n=1 ;
    else                    %load current data file
        load([strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']','data');
        n = length(data)+1;
    end
   
%% SETUP TRIAL PARAMETERS
    
    % Check if trial will use stimulus
    if length(trialDuration) == 1
        stimOn = 0;
    else
        stimOn = 1;
    end
    
    % Record trial parameters
    data(n).odor = odor;
    sampRate = 20000;
    data(n).trialduration = trialDuration;                      % Trial duration (pre-stim, pinch open, 2-way open, post-stim)
    data(n).iontoDuration = iontoDuration;
    data(n).ejectionDuration = [];
    data(n).valveID = valveID;
    
    % Set up stimulus data
    if stimOn        
        stimVolts = 5;
        
        % Make pre- and post-stim output vectors
        preStimPinch = zeros(sampRate * trialDuration(1), 1);
        preStimIso = zeros(sampRate * sum(trialDuration(1:2)), 1);
        postStim = zeros(sampRate * (trialDuration(4)-1), 1);
        postStimShuttle = zeros(sampRate * trialDuration(4), 1);
        
        % Make pinch and iso valve open vectors
        pinchValveOpen = ones(sampRate * (sum(trialDuration(2:3))+1), 1);
        isoValveOpen = ones(sampRate * (trialDuration(3)+1), 1) * stimVolts;     
        shuttleValveOpen = ones(sampRate * trialDuration(3),1) * stimVolts;
        
        % Put together full output vectors
        pinchValveOut = [preStimPinch; pinchValveOpen; postStim];                                                    
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed
        pinchValveOut(end) = 0;  
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;
        
        % Iontophoresis stim setup
        if ~isempty(iontoDuration)
            preIonto = zeros(sampRate * iontoDuration(1), 1);
            iontoStim = ones(sampRate * iontoDuration(2), 1) * stimVolts;
            postIonto = zeros(sampRate * iontoDuration(3), 1);
            iontoStimOut = [preIonto; iontoStim; postIonto];
            iontoStimOut(end) = 0;
        else
            iontoStimOut = zeros(sampRate * sum(trialDuration),1);
        end
    end

    % experiment information
    data(n).date = strDate;                                     % experiment date
    data(n).expnumber = expNumber;                              % experiment number
    data(n).trial = n;                                          % trial number
    data(n).sampleTime = clock;
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data
    
    % sampling rates
    data(n).sampratein = sampRate;                                 % input sample rate
    data(n).samprateout = sampRate;                                % output sample rate becomes input rate as well when both input and output present
        
    % amplifier gains to be read or used
    data(n).variableGain = NaN;                                 % Amplifier 1 alpha
    data(n).variableOffset1 = NaN;                              % Amplifier 1 variable output offset. Determined emperically.
    data(n).ImGain = 10;
    data(n).VmGain = 100;
    data(n).ImOffset1 = 0;                                      % Amplifier 1 fixed output offset. Determined emperically.  

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
    s.addAnalogInputChannel('Dev1',[0:5],'Voltage');
    for i=1:6
        s.Channels(1,i).InputType = 'SingleEnded';
    end
    
    if stimOn
        % Setup output channels
        s.addAnalogOutputChannel('Dev2', 0:3 , 'Voltage');              % 2-way valves
        s.addDigitalChannel('Dev2', 'port0/line28:31', 'OutputOnly');   % Pinch valves
        s.addAnalogOutputChannel('Dev1', 0, 'Voltage');                 % 3-way valve
        s.addAnalogOutputChannel('Dev1', 1 , 'Voltage');                % PicoPump command       
        
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 10);
        outputData(:, valveID) = isoValveOut;
        outputData(:, valveID + 4) = pinchValveOut; 
        outputData(:, 9) = shuttleValveOut;
        outputData(:, 10) = iontoStimOut;
        s.queueOutputData(outputData);
    end
    
    s.Rate = data(n).samprateout;
    x = s.startForeground();
    
    % Calculate and record "Output Gain" setting on amplifier
       gainReading = mean(x(:,4));
    if gainReading > 0 && gainReading < 2.34
        data(n).variableGain = 0.5;
    elseif gainReading >= 2.34 && gainReading < 2.85
        data(n).variableGain = 1;
    elseif gainReading >= 2.85 && gainReading < 3.34
        data(n).variableGain = 2;
    elseif gainReading >= 3.34 && gainReading < 3.85
        data(n).variableGain = 5;
    elseif gainReading >= 3.85 && gainReading < 4.37
        data(n).variableGain = 10;
    elseif gainReading >= 4.37 && gainReading < 4.85
        data(n).variableGain = 20;
    elseif gainReading >= 4.85 && gainReading < 5.34
        data(n).variableGain = 50;
    elseif gainReading >= 5.34 && gainReading < 5.85
        data(n).variableGain = 100;
    elseif gainReading >= 5.85 && gainReading < 6.37
        data(n).variableGain = 200;
    elseif gainReading >= 6.37 && gainReading < 6.85
        data(n).variableGain = 500;
    end
    
    % Calculate and record amplifier filter setting
    filterTelegraph = mean(x(:,5));
    if filterTelegraph > 0 && filterTelegraph < 3
        data(n).filterFreq = 1;
    elseif filterTelegraph >= 3 && filterTelegraph < 5
        data(n).filterFreq = 2;
    elseif filterTelegraph >=5 && filterTelegraph < 7
        data(n).filterFreq = 5;
    elseif filterTelegraph >=7 && filterTelegraph < 9
        data(n).filterFreq = 10;
    elseif filterTelegraph >=9 && filterTelegraph < 11
        data(n).filterFreq = 100;
    end
    
    % Calculate and record amplifier mode
    scaledOutMode = mean(x(:,6));
    if scaledOutMode > 0 && scaledOutMode < 3.5
        data(n).scaledOutMode = 'V';
    elseif scaledOutMode >= 3.5 && scaledOutMode < 7
        data(n).scaledOutMode = 'I';
    end 
    
    % Save recorded data
    scaledOut = (x(:,1)/data(n).variableGain)*1000; % mV or pA
    current = (x(:,2)/data(n).ImGain)*1000; % pA 
    tenVm = (x(:,3)/data(n).VmGain)*1000; % mV    
    
    %% PLOTS
    
    time = [1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration)];
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1650 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), scaledOut(.05*sampRate:end));
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
    ylabel('Vm (mV)');
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
     
    figure (2); clf; hold on
    set(gcf,'Position',[10 50 1650 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    if strcmp(data(n).scaledOutMode, 'V')
        plot(time(.05*sampRate:end), current(.05*sampRate:end)); 
    elseif strcmp(data(n).scaledOutMode, 'I')
        plot(time(.05*sampRate:end), tenVm(.05*sampRate:end)); 
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
    ylabel('Im (pA)');
    box off;
    
    %% save data(n)
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['U:/Data Backup/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm'); %, 'odor');
    save(['U:/Data Backup/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm');

