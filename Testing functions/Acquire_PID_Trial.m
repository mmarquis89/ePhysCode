function data = acquire_PID_trial(expNumber,trialDuration, valveID)
% ==============================================================================================
% expnumber = experiment (fly or cell) number
% trialDuration = [pre-stim, clean valve open, post-stim] in seconds
        % If trialDuration is a single integer, a trace of that duration will be acquired
% odor = record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
% valveID = a number from 1-4 indicating which valve to use if a stimulus is delivered (use '[]' if no stim)
% Istep = the size of the current step to use at the beginning of the trial in pA. [] will skip the step.
% Ihold = the holding current in pA to consistently inject into the cell

% Raw data sampled at 20 kHz and saved as separate waveforms for each trial
% ==============================================================================================
 
%% SETUP TRIAL PARAMETERS

    [data, n] = acquisition_setup(expNumber,trialDuration, [], [], [], valveID, [], 0);
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
        
        % iso valve open vectors
        isoValveOpen = ones(sampRate * (trialDuration(2)+1), 1);     
        shuttleValveOpen = ones(sampRate * trialDuration(2),1);
        
        % Put together full output vectors                  
        isoValveOut = [preStimIso; isoValveOpen; postStim];        
        shuttleValveOut = [preStimIso; shuttleValveOpen; postStimShuttle];
        
        % Make sure valves are closed
        isoValveOut(end) = 0;
        shuttleValveOut(end) = 0;
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
    s.addAnalogInputChannel('Dev2', 6,'Voltage');
    s.Channels(1,1).InputType = 'SingleEnded';
    
    if stimOn
        % Setup output channels
        s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');       % Shuttle valve        
        s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');    % 2-way iso valves
               
        % Load output data for each channel
        outputData = zeros(sum(trialDuration*sampRate), 9);
        outputData(:,1) = shuttleValveOut;
        outputData(:, valveID + 1) = isoValveOut;
        s.queueOutputData(outputData);    
    end
    
    s.Rate = data(n).samprateout;
    x = s.startForeground();

%% RUN POST-PROCESSING AND SAVE DATA
    
    strDate = data(n).date;
    expNumber = data(n).expnumber;

    % Calculate and record "Output Gain" setting on amplifier
    data(n).variableGain = [];

    % Calculate and record amplifier filter setting
    data(n).filterFreq = [];
    
    % Calculate and record amplifier mode
    data(n).scaledOutMode = [];
        
    % Save recorded data
    PID_Out = x(:,1); 

    data(n).Rin = 0; % Trying this instead of NaN to see if it solves problem with Matlab crashing during Rin plotting
    data(n).Rpipette = [];

    
    %% save data(n)
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['U:/Data Backup/', strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save(['C:/Users/Wilson Lab/Documents/MATLAB/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'PID_Out'); %, 'odor');
    save(['U:/Data Backup/', strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'PID_Out');

 
    %% PLOTS
    
    time = [1/data(n).sampratein:1/data(n).sampratein:sum(data(n).trialduration)];
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 150 1650 800],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time(.05*sampRate:end), PID_Out(.05*sampRate:end)); %scaledOut) ;
    if stimOn
        plot([trialDuration(1), trialDuration(1)],ylim, 'Color', 'k') % Clean valves open
        plot([sum(trialDuration(1:2)),sum(trialDuration(1:2))],ylim, 'Color', 'k')  % Shuttle valve closed
    end
%     ylim([-3.3, -2.3]);
    title(['Trial Number ' num2str(n) ]);
    ylabel('V');
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
    
    