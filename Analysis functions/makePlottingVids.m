function msg = makePlottingVids(expData, parentDir, flowDir, savePath)
%============================================================================================================================
% CREATE COMBINED PLOTTING VIDEOS
% Creates an .avi movie for each trial of an experiment that combines the behavior video, the membrane voltage, and the optic
% flow data. Returns a message string indicating whether the operation was a success (and if not, which trial it failed on). 
% The videos are saved at the location indicated by 'savePath'.
%       expData = entire data object for the experiment in question
%       parentDir = the file path to the parent folder containing all the .tif files for each trial. Within this directory,
%                   the frames for each trial should be saved in a folder named with the experiment and trial numbers
%                   separated by an understore (e.g. 'E1_T3')
%       flowDir = the path to the .mat file containing the optic flow data for the experiment
%       savePath = the path to the directory where video will be saved
%============================================================================================================================

frameRate = expData.expInfo(1).acqSettings.frameRate;
strDate = expData.expInfo(1).date;
disp('Creating combined plotting videos...')
% try
    for iTrial = 1:length(expData.expInfo);
        
        strDate = expData.expInfo(1).date;
        trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
        
        disp(trialStr)  
        % Check to make sure some raw video and no existing combined plotting video for this trial
        if ~isempty(dir(fullfile(parentDir, strDate, trialStr, '*tif*'))) && isempty(dir(fullfile(savePath, [trialStr, '_*']))) 
            
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
            load(flowDir);
            
            % Create save directory and open video writer
            if ~isdir(savePath)
                mkdir(savePath);
            end
            myVid = VideoWriter(fullfile(savePath, [trialStr, '_With_Plots.avi']));
            myVid.FrameRate = frameRate;
            open(myVid)
            
            % Make temporary block structure to get plotting data from
            blTemp = makeBl(getTrials(expData, iTrial), iTrial);
            
            % Get annotation line info
            if ~isempty(blTemp.odors{1})
                annotLines = {[blTemp.stimOnTime, blTemp.stimOnTime+blTemp.stimLength]};
            else
                annotLines = {};
            end
            if ~isempty(blTemp.altStimDuration)
                annotLines(end+1:end+2) = {blTemp.altStimStartTime, blTemp.altStimStartTime+blTemp.altStimLength};
                annotColors = [0 0 0; 1 0 1; 1 0 1];
            else
                annotColors = [0 0 0];
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
                plotTraces(ax, blTemp, fTemp, currVm', [0 0 1], annotLines, annotColors);
                plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],[ylim()], 'LineWidth', 1, 'color', 'r');
                xlabel('Time (sec)');
                ylabel('Vm (mV)');
                
                % Optic flow plot
                axes('Units', 'Pixels', 'Position', [425 20 1330 300]);
                hold on
                frameTimes = (1:1:length(flowData{iTrial}))./ frameRate;
                ylim([0, 1.5]);
                plot(frameTimes(2:end), flowData{iTrial}(2:end));
                plot([iFrame*(1/frameRate), iFrame*(1/frameRate)],ylim(),'LineWidth', 1, 'color', 'r');
                set(gca,'xticklabel',[])
                ylabel('Optic flow (au)')
                
                % Write frame to video
                writeFrame = getframe(h);
                writeVideo(myVid, writeFrame);
            end%for
            close(myVid)
        end%if
    end%for
    msg = 'Combined plotting videos created successfully!';
% catch
%     msg = ['Error - video making failed on trial #', num2str(iTrial)];
% end%try

end%function
