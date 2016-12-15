function data = initialPatchingAcq(expNumber)
% ===============================================================================================================
% expnumber = experiment (fly or cell) number
% Raw data sampled at 80 kHz and saved in a single file.
% ===============================================================================================================

% SETUP TRIAL PARAMETERS
    
    % Run initial setup function
    [data, n] = acquisitionSetup(expNumber,[], [], [], [], [], [], []);
    data(n).sampratein = 80000;
    data(n).samprateout = 80000;
    sampRate = data(n).sampratein;
    data(n).acquisition_filename = mfilename('fullpath');
    
    % Make sure this is the first trial of the experiment, but give user an out for flexibility
    inputStr = 'initStr';
    if n > 1
       while ~strcmp(inputStr, 'y') && ~strcmp(inputStr, 'n')
        inputStr = input([char(10), 'This will not be the first trial of this experiment. ', char(10), 'Are you sure you want to continue? y/n: '], 's'); 
       end
       if strcmp(inputStr, 'n')
           disp([char(10), 'Initial acquisition abandoned']);
           return
       end
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
    s.Rate = data(n).sampratein;
    s.addAnalogInputChannel('Dev2', 0:5,'Voltage');
    for iChan=1:6
        s.Channels(1,iChan).InputType = 'SingleEnded';
    end
    s.IsContinuous = true;
    contAcqData = [];
    lh = addlistener(s, 'DataAvailable', @contAcqSave);
    startBackground(s);
    
    %% Create GUI to wait for user to end acquisition
    DlgH = figure;
    H = uicontrol('Style', 'PushButton', 'String', 'Save acquired data', 'Position', [10 220 545 150], 'FontSize', 25, 'Callback', @saveData);
    uicontrol('Style', 'PushButton', 'String', 'Delete acquired data', 'Position', [10 50 545 150], 'FontSize', 25, 'Callback', @delData);
    while(ishandle(H))
        drawnow
    end
    
    % End acquisition and trim to nearest second
    s.stop();
    data(n).trialduration = floor(size(contAcqData, 1) / sampRate); % Round duration down to nearest second
    contAcqData = contAcqData(1:data(n).trialduration*sampRate,:); % Trim acquired data to the nearest second
    s.IsContinuous = false;
    delete(lh)
    delete(DlgH)
    
%% RUN POST-PROCESSING AND SAVE DATA
if ~saveToggle
    disp([char(10), 'Initial acquisition data discarded']);
    clear contAcqData;
else
    disp([char(10), 'Saving initial acquisition data...']);
    [data, ~, scaledOut, ~] = acquisitionPostProcessing(data, contAcqData, n);
    disp('Initial acquisition data saved');
    
    % PLOT FIGURES
    time = 1/data(n).sampratein:1/data(n).sampratein:data(n).trialduration;
    
    figure (1);clf; hold on
    set(gcf,'Position',[10 550 1850 400],'Color',[1 1 1]);
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
end   
%% CALLBACK FUNCTIONS
    function saveData(src, event)
        saveToggle = true;
        delete(gcbf)
    end
    function delData(src, event)
        saveToggle = false;
        delete(gcbf)
    end
    function contAcqSave(src, event)
        contAcqData = [contAcqData; event.Data];
    end
end
