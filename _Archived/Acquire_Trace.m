function data = Acquire_Trace(expNumber,trialDuration, odor)

% expnumber = experiment (fly or cell) number
% trialDuration = time to record in seconds
% odor = record of odor ID - Use 'NA', 'EmptyVial', 'ParaffinOil', or the odor name
% Raw data sampled at 10kHz and saved as separate waveforms for each trial

%%  make a directory if one does not exist
    strDate = datestr(now, 'yyyy-mmm-dd');
    if ~isdir(strDate)
        mkdir(strDate);
    end  

    %% access data structure and count trials check whether a saved data file exists with today's date
    D = dir([strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']);
    if isempty(D)           % if no saved data exists then this is the first trial
        n=1 ;
    else                    %load current data file
        load([strDate,'/WCwaveform_',strDate,'_E',num2str(expNumber),'.mat']','data');
        n = length(data)+1;
    end
   
%% set trial parameters 
    
    % Setup Constants
    data(n).odor = odor;
    data(n).trialduration = trialDuration;                      % Trial duration (sec)
    sampRate = 10000;
    
    % experiment information
    data(n).date = strDate;                                        % experiment date
    data(n).expnumber = expNumber;                              % experiment number
    data(n).trial = n;                                          % trial number
    data(n).sampleTime = clock;
    data(n).acquisition_filename = mfilename('fullpath');       % saves name of mfile that generated data
    
    % sampling rates
    data(n).sampratein = sampRate;                                 % input sample rate
    
    % amplifier gains to be read or used
    data(n).variableGain = NaN;                                % Amplifier 1 alpha
    data(n).variableOffset1 = NaN;                              % Amplifier 1 variable output offset. Determined emperically.
    data(n).ImGain = 10;
    data(n).VmGain = 100;
    data(n).ImOffset1 = 0;                                      % Amplifier 1 fixed output offset. Determined emperically.  

    %% Session based acquisition code for inputs  
    
    %   CHANNEL SET-UP 
%    0  Scaled Out 
%    1  Im  
%    2  10Vm  
%    3  Amplifier Gain
%    4  Amplifier Filter Freq
%    5  Amplifier Mode

    s = daq.createSession('ni');
 
    s.addAnalogInputChannel('Dev1',[0:5],'Voltage');
    for i=1:6
        s.Channels(1,i).InputType = 'SingleEnded';
    end
    s.DurationInSeconds = sum(data(n).trialduration);
    s.Rate = data(n).sampratein;  
    
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
    ampMode = mean(x(:,6));
    if ampMode > 0 && ampMode < 3.5
        data(n).scaledOutMode = 'V';
    elseif ampMode >= 3.5 && ampMode < 7
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
    plot(time, tenVm);
    title(['Trial Number ' num2str(n) ]);
    ylabel('Vm (mV)');
    set(gca,'LooseInset',get(gca,'TightInset'))
    box off
     
    figure (2); clf; hold on
    set(gcf,'Position',[10 50 1650 400],'Color',[1 1 1]);
    set(gca,'LooseInset',get(gca,'TightInset'))
    plot(time, current); 
    title(['Trial Number ' num2str(n) ]);
    ylabel('Im (pA)');
 box off;
   
    %% save data(n)
    save([strDate,'/WCwaveform_' data(n).date,'_E',num2str(expNumber)],'data');
    save([strDate,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expNumber),'_',num2str(n)],'current','scaledOut','tenVm');
    

