function data = pressureEject(expNumber,trialDuration, ejectionDuration, Ihold)

% expnumber = experiment (fly or cell) number
% trialDuration = [time before ejection, time after beginning of ejection] in seconds
% ejectionDuration = duration of picopump ejection in milliseconds

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial


%% SETUP TRIAL PARAMETERS

    [data, n] = acquisitionSetup(expNumber, trialDuration, [], ejectionDuration, [], [], [], Ihold);   
    sampRate = data(n).sampratein;    
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data 

    % Set up stimulus data
    ejectStimOut = zeros(sampRate * sum(trialDuration),1);
    ejectStimOut(int32(sampRate*trialDuration(1)):int32(sampRate*(trialDuration(1)+(ejectionDuration./1000)))) = 1;
    pumpCommand = ejectStimOut;
    
    Icommand = ones(sampRate*sum(trialDuration),1) * Ihold/2;
    
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
    
    % Setup output channel
    s.addDigitalChannel('Dev2', 'port0/line2', 'OutputOnly');       % Picopump command
    s.addAnalogOutputChannel('Dev2', 0 , 'Voltage');                % Amplifier external command
    
    % Load output data for each channel
    s.queueOutputData([pumpCommand, Icommand]);
    
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
    if strcmp(data(n).scaledOutMode, 'I')
        ylabel('Im (pA)');
    elseif strcmp(data(n).scaledOutMode, 'V')
        ylabel('Vm (mV)');
    end
    plot([trialDuration(1), trialDuration(1)], ylim, 'Color' , 'm')  
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
    plot([trialDuration(1), trialDuration(1)], ylim, 'Color' , 'm')  
    title(['Trial Number ' num2str(n) ]);
    box off;
  