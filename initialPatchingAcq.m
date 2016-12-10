function data = initialPatchingAcq(expNumber,trialDuration)

% ===============================================================================================================
% expnumber = experiment (fly or cell) number
% trialDuration = trial length in seconds
% Raw data sampled at 100 kHz and saved as separate waveforms for each trial
% ===============================================================================================================
%% SETUP TRIAL PARAMETERS
    
    % Run initial setup function
    [data, n] = acquisitionSetup(expNumber,trialDuration, [], [], [], [], [], []);
    data(n).sampratein = 100000;
    data(n).samprateout = 100000;
    sampRate = data(n).sampratein;
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data
    
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
    % Plot annotation lines if stimulus was presented
    if stimOn
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'k')    % Odor valve onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'r')  % Odor valve offset
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
    % Plot annotation lines if stimulus was presented
    if stimOn
        plot([(trialDuration(1)),(trialDuration(1))],ylim, 'Color', 'g')  % Odor valve onset
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'r')  % Odor valve offset
    end
    title(['Trial Number ' num2str(n) ]);
    box off;
    