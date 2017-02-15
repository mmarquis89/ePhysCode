

function data = denoising_Acquisition(expNumber,trialDuration)

% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.
% Ihold = the holding current in pA to consistently inject into the cell

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial
  
%% SETUP TRIAL PARAMETERS
    
    aS = acqSettings;
    aS.expNum = expNumber;
    aS.trialDuration = trialDuration;

    % Run initial setup function
    [data, n] = acquisitionSetup(aS);
    disp(num2str(n))
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
    
    s.Rate = data(n).samprateout;
    x = s.startForeground();

%% RUN POST-PROCESSING AND SAVE DATA
    [data, current, scaledOut, tenVm] = acquisitionPostProcessing(data, x, n);
 
%% PLOT FIGURES
    
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
    title(['Trial Number ' num2str(n) ]);
    box off;
    
    % Plot input resistance across experiment
    %% PLOT FREQUENCY CONTENT

    % Calulate frequency power spectrum for each data type
    if strcmp(data(n).scaledOutMode, 'V')
        [pfftV, fValsV] = getFreqContent(scaledOut,sampRate);
        [pfftC, fValsC] = getFreqContent(current(:,1),sampRate);
    elseif strcmp(data(n).scaledOutMode, 'I')
        [pfftV, fValsV] = getFreqContent(tenVm,sampRate);
        [pfftC, fValsC] = getFreqContent(scaledOut,sampRate);
    end
    
    % Plot them each on a log scale
    figure(3);clf;subplot(211)
    plot(fValsV, 10*log10(pfftV));
    title('Voltage'); xlabel('Frequency (Hz)') ;ylabel('PSD(dB)'); xlim([-300 300]);
    ylim([-100 50]);
    subplot(212)
    plot(fValsV, 10*log10(pfftC));
    title('Current'); xlabel('Frequency (Hz)'); ylabel('PSD(dB)'); xlim([-300 300]);

    
    