function olfactometerFlush()
% ===================================================================================================
% Flushes out olfactometer by opening all valves until user presses a button on a GUI to end looping
% ===================================================================================================

    %% SETUP TRIAL PARAMETERS

    sampRate = 10000;

    %% GUI to break looping
    DlgH = figure;
    H = uicontrol('Style', 'PushButton', 'String', 'Break', 'Callback', 'delete(gcbf)');
    
   
%% SESSION-BASED ACQUISITION CODE 
tic
 while (ishandle(H))
        % Create session
        s = daq.createSession('ni');

        % Setup output channels
        s.addDigitalChannel('Dev2', 'port0/line0', 'OutputOnly');       % Shuttle valve        
        s.addDigitalChannel('Dev2', 'port0/line8:11', 'OutputOnly');    % 2-way iso valves
        s.addAnalogInputChannel('Dev2', 0,'Voltage');
        lh = addlistener(s,'DataAvailable',@(src,event) disp(['Flushing for ', num2str(toc), ' seconds']));
        
        % Setup acquisition
        s.Rate = sampRate;
        outputData = ones(5*sampRate, 5);
        outputData(end, :) = 0;
        s.queueOutputData(outputData);
        s.NotifyWhenDataAvailableExceeds = 0.75 * sampRate;
        
        % Load output data and start trial
        startBackground(s);

    end 
    
    % One last operation to close valves
    s.stop()
    s.queueOutputData(zeros(sampRate, 5));
    startBackground(s);
    delete(lh);
end
    
    

    

    