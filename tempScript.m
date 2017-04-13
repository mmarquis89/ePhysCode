

%% Load next exp

expData = loadExperiment('2017-Apr-12', 1);

%% CREATE MOVIES FROM .TIF FILES

strDate = expData.expInfo(1).date;
nTrials = length(expData.expInfo);
 
disp('Creating videos...');
for iTrial = 1:nTrials
    % Get name of current trial
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];   
    disp(trialStr)
    savePath = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate, trialStr);
    currFiles = dir(fullfile(savePath, '*.tif'));
    
    if ~isempty(currFiles) && isempty(dir(fullfile(savePath, '*.avi'))) % Make sure there's at least one image file and no .avi file already in this trial's directory
        currFrames = {currFiles.name}';
        
        % Create video writer object
        outputVid = VideoWriter([fullfile(savePath, [trialStr, '.avi'])]);
        outputVid.FrameRate = expData.expInfo(1).acqSettings.frameRate;
        open(outputVid)
        
        % Write each .tif file to video
        for iFrame = 1:length(currFrames)
            currImg = imread(fullfile(savePath, currFrames{iFrame}));
            writeVideo(outputVid, currImg);
        end
        close(outputVid)
    end   
end

% CALCULATE OR LOAD MEAN OPTICAL FLOW

nTrials = length(expData.expInfo);
strDate = expData.expInfo(1).date;
parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
allFlow = cell(nTrials, 1);
disp('Calculating optic flow...')

if isempty(dir(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat'])))
    for iTrial = 1:nTrials
        % Get trial name
        trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
        disp(trialStr)
        
        if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
            
            % Load movie for the current trial
            myMovie = [];
            myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
            while hasFrame(myVid)
                currFrame = readFrame(myVid);
                myMovie(:,:,end+1) = rgb2gray(currFrame);
            end
            myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
            
            % Calculate mean optical flow magnitude across frames for each trial
            opticFlow = opticalFlowFarneback;
            currFlow = []; flowMag = zeros(size(myMovie, 3),1);
            for iFrame = 1:size(myMovie, 3)
                currFlow = estimateFlow(opticFlow, myMovie(:,:,iFrame));
                flowMag(iFrame) = mean(mean(currFlow.Magnitude));
            end
            allFlow{iTrial} = flowMag;
        end
    end
    
    % Save data to disk for future use
    save(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
%     try
%         save(fullfile('U:\Data Backup', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
%     catch
%         disp('Warning: server backup folder does not exist. Skipping server backup save.')
%     end
else
    load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
end

% CREATE COMBINED PLOTTING VIDEOS

frameRate = expData.expInfo(1).acqSettings.frameRate;
disp('Creating combined plotting videos...')

for iTrial = 1:length(expData.expInfo);
        
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    strDate = expData.expInfo(1).date;
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = [];
        myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(:,:,end+1) = rgb2gray(currFrame);
        end
        myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
        
        % Load trial data
        currVm = expData.trialData(iTrial).scaledOut;
        trialDuration = sum(expData.expInfo(iTrial).trialduration);
        
        % Load optic flow data
        load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
        
        % Create save directory and open video writer
        if ~isdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']))
            mkdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']));
        end
        myVid = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], [trialStr, '_With_Plots.avi']));
        myVid.FrameRate = frameRate;
        open(myVid)
        
        % Make temporary block structure to get plotting data from
        blTemp = makeBl(getTrials(expData, iTrial), iTrial);
        if ~isempty(blTemp.odors{1})
            annotLines = {[blTemp.stimOnTime, blTemp.stimOnTime+blTemp.stimLength]};
        else
            annotLines = {};
        end
        
        % Create and save each frame
        for iFrame = 1:size(myMovie, 3)
            
            currFrame = myMovie(:,:,iFrame);
            
            % Create figure
            h = figure(10); clf
            set(h, 'Position', [50 100 1800 700]);
            
            % Movie frame plot
            axes('Units', 'Pixels', 'Position', [50 225 300 300]);
            imshow(currFrame);
            axis image
            axis off
            if ~isempty(annotLines)
                title({strrep(blTemp.odors{1}, '_', '\_'), '',['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            else
                title({['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            end
            
            % Vm plot
            ax = axes('Units', 'Pixels', 'Position', [425 380 1330 300]);
            hold on
            fTemp = figInfo;
            yRange = max(currVm) - min(currVm);
            fTemp.yLims = [min(currVm)-0.1*yRange, max(currVm)+0.2*yRange];
            plotTraces(ax, blTemp, fTemp, currVm', [0 0 1], annotLines, [0 0 0]);         
%             t = (1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein)*length(currVm);
%             plot(t, currVm)
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],[ylim()], 'LineWidth', 1, 'color', 'r');
            xlabel('Time (sec)');
            ylabel('Vm (mV)');
            
            % Optic flow plot
            axes('Units', 'Pixels', 'Position', [425 20 1330 300]);
            hold on
            frameTimes = (1:1:length(allFlow{iTrial}))./ frameRate;
            ylim([0, 1.5]);
            plot(frameTimes(2:end), allFlow{iTrial}(2:end));
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],ylim(),'LineWidth', 1, 'color', 'r');
            % set(gca,'ytick',[])
            set(gca,'xticklabel',[])
            ylabel('Optic flow (au)')
            
            % Write frame to video
            writeFrame = getframe(h);
            writeVideo(myVid, writeFrame);
        end
        close(myVid)
    end
end

% CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT

parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
strDate = expData.expInfo(1).date;
frameRate = expData.expInfo(1).acqSettings.frameRate;
nTrials = length(expData.expInfo);
disp('Concatenating videos...')

% Create videowriter 
myVidWriter = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], ['E', num2str(expData.expInfo(1).expNum),'_AllTrials.avi']));
myVidWriter.FrameRate = frameRate;
open(myVidWriter)

for iTrial = 1:nTrials
    
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = {};
        myVid = VideoReader(fullfile(parentDir, strDate,['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'] ,[trialStr '_With_Plots.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(end+1) = {uint8(currFrame)};
        end
        
        % Add frames to movie
        for iFrame = 1:length(myMovie)
            writeVideo(myVidWriter, myMovie{iFrame});
        end
    end
end
close(myVidWriter)
clear('myMovie')

%% Load next exp

expData = loadExperiment('2017-Apr-12', 2);

%% CREATE MOVIES FROM .TIF FILES

strDate = expData.expInfo(1).date;
nTrials = length(expData.expInfo);
 
disp('Creating videos...');
for iTrial = 1:nTrials
    % Get name of current trial
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];   
    disp(trialStr)
    savePath = fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies', strDate, trialStr);
    currFiles = dir(fullfile(savePath, '*.tif'));
    
    if ~isempty(currFiles) && isempty(dir(fullfile(savePath, '*.avi'))) % Make sure there's at least one image file and no .avi file already in this trial's directory
        currFrames = {currFiles.name}';
        
        % Create video writer object
        outputVid = VideoWriter([fullfile(savePath, [trialStr, '.avi'])]);
        outputVid.FrameRate = expData.expInfo(1).acqSettings.frameRate;
        open(outputVid)
        
        % Write each .tif file to video
        for iFrame = 1:length(currFrames)
            currImg = imread(fullfile(savePath, currFrames{iFrame}));
            writeVideo(outputVid, currImg);
        end
        close(outputVid)
    end   
end

% CALCULATE OR LOAD MEAN OPTICAL FLOW

nTrials = length(expData.expInfo);
strDate = expData.expInfo(1).date;
parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
allFlow = cell(nTrials, 1);
disp('Calculating optic flow...')

if isempty(dir(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat'])))
    for iTrial = 1:nTrials
        % Get trial name
        trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
        disp(trialStr)
        
        if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
            
            % Load movie for the current trial
            myMovie = [];
            myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
            while hasFrame(myVid)
                currFrame = readFrame(myVid);
                myMovie(:,:,end+1) = rgb2gray(currFrame);
            end
            myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
            
            % Calculate mean optical flow magnitude across frames for each trial
            opticFlow = opticalFlowFarneback;
            currFlow = []; flowMag = zeros(size(myMovie, 3),1);
            for iFrame = 1:size(myMovie, 3)
                currFlow = estimateFlow(opticFlow, myMovie(:,:,iFrame));
                flowMag(iFrame) = mean(mean(currFlow.Magnitude));
            end
            allFlow{iTrial} = flowMag;
        end
    end
    
    % Save data to disk for future use
    save(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
%     try
%         save(fullfile('U:\Data Backup', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']), 'allFlow');
%     catch
%         disp('Warning: server backup folder does not exist. Skipping server backup save.')
%     end
else
    load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
end

% CREATE COMBINED PLOTTING VIDEOS

frameRate = expData.expInfo(1).acqSettings.frameRate;
disp('Creating combined plotting videos...')

for iTrial = 1:length(expData.expInfo);
        
    parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
    strDate = expData.expInfo(1).date;
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = [];
        myVid = VideoReader(fullfile(parentDir, strDate, trialStr, [trialStr, '.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(:,:,end+1) = rgb2gray(currFrame);
        end
        myMovie = uint8(myMovie(:,:,2:end)); % Adds a black first frame for some reason, so drop that
        
        % Load trial data
        currVm = expData.trialData(iTrial).scaledOut;
        trialDuration = sum(expData.expInfo(iTrial).trialduration);
        
        % Load optic flow data
        load(fullfile('C:\Users\Wilson Lab\Dropbox (HMS)\Data', strDate,['E', num2str(expData.expInfo(1).expNum),'OpticFlowData.mat']));
        
        % Create save directory and open video writer
        if ~isdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']))
            mkdir(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots']));
        end
        myVid = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], [trialStr, '_With_Plots.avi']));
        myVid.FrameRate = frameRate;
        open(myVid)
        
        % Make temporary block structure to get plotting data from
        blTemp = makeBl(getTrials(expData, iTrial), iTrial);
        if ~isempty(blTemp.odors{1})
            annotLines = {[blTemp.stimOnTime, blTemp.stimOnTime+blTemp.stimLength]};
        else
            annotLines = {};
        end
        
        % Create and save each frame
        for iFrame = 1:size(myMovie, 3)
            
            currFrame = myMovie(:,:,iFrame);
            
            % Create figure
            h = figure(10); clf
            set(h, 'Position', [50 100 1800 700]);
            
            % Movie frame plot
            axes('Units', 'Pixels', 'Position', [50 225 300 300]);
            imshow(currFrame);
            axis image
            axis off
            if ~isempty(annotLines)
                title({strrep(blTemp.odors{1}, '_', '\_'), '',['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            else
                title({['Trial Number = ', num2str(iTrial)], '',['Frame = ', num2str(iFrame), '          Time = ', sprintf('%06.3f',(iFrame/frameRate))], ''});
            end
            
            % Vm plot
            ax = axes('Units', 'Pixels', 'Position', [425 380 1330 300]);
            hold on
            fTemp = figInfo;
            yRange = max(currVm) - min(currVm);
            fTemp.yLims = [min(currVm)-0.1*yRange, max(currVm)+0.2*yRange];
            plotTraces(ax, blTemp, fTemp, currVm', [0 0 1], annotLines, [0 0 0]);         
%             t = (1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein):(1/expData.expInfo(1).sampratein)*length(currVm);
%             plot(t, currVm)
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],[ylim()], 'LineWidth', 1, 'color', 'r');
            xlabel('Time (sec)');
            ylabel('Vm (mV)');
            
            % Optic flow plot
            axes('Units', 'Pixels', 'Position', [425 20 1330 300]);
            hold on
            frameTimes = (1:1:length(allFlow{iTrial}))./ frameRate;
            ylim([0, 1.5]);
            plot(frameTimes(2:end), allFlow{iTrial}(2:end));
            plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],ylim(),'LineWidth', 1, 'color', 'r');
            % set(gca,'ytick',[])
            set(gca,'xticklabel',[])
            ylabel('Optic flow (au)')
            
            % Write frame to video
            writeFrame = getframe(h);
            writeVideo(myVid, writeFrame);
        end
        close(myVid)
    end
end

% CONCATENATE ALL MOVIES+PLOTS FOR THE EXPERIMENT

parentDir = 'C:\Users\Wilson Lab\Dropbox (HMS)\Data\_Movies';
strDate = expData.expInfo(1).date;
frameRate = expData.expInfo(1).acqSettings.frameRate;
nTrials = length(expData.expInfo);
disp('Concatenating videos...')

% Create videowriter 
myVidWriter = VideoWriter(fullfile(parentDir, strDate, ['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'], ['E', num2str(expData.expInfo(1).expNum),'_AllTrials.avi']));
myVidWriter.FrameRate = frameRate;
open(myVidWriter)

for iTrial = 1:nTrials
    
    trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
    disp(trialStr)
    
    if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) % Check to make sure is some video for this trial
        
        % Load movie for the current trial
        myMovie = {};
        myVid = VideoReader(fullfile(parentDir, strDate,['E', num2str(expData.expInfo(1).expNum), '_Movies+Plots'] ,[trialStr '_With_Plots.avi']));
        while hasFrame(myVid)
            currFrame = readFrame(myVid);
            myMovie(end+1) = {uint8(currFrame)};
        end
        
        % Add frames to movie
        for iFrame = 1:length(myMovie)
            writeVideo(myVidWriter, myMovie{iFrame});
        end
    end
end
close(myVidWriter)
clear('myMovie')
