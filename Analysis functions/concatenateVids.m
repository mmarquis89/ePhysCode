function msg = concatenateVids(expData, parentDir)
%============================================================================================================================
% CONCATENATE ALL COMBINED PLOTTING VIDEOS FOR THE EXPERIMENT
% Concatenates the combined plotting videos for each trial of an experiment, and returns a message string indicating whether
% the operation was a success (and if not, which trial it failed on). The new video will be saved in the same folder as the
% source videos.
%       expData = entire data object for the experiment in question
%       parentDir = the file path to the parent folder containing the combined plotting videos for each trial. Within this 
%                   directory, the frames for each trial should be saved in a folder named with the date, containing another
%                   folder named according to the experiment number (e.g. 'E1_Movies+Plots').
%============================================================================================================================

strDate = expData.expInfo(1).date;
frameRate = expData.expInfo(1).acqSettings.frameRate;
nTrials = length(expData.expInfo);

% Create videowriter
vidDir = fullfile(parentDir, 'Combined videos', strDate, ['E', num2str(expData.expInfo(1).expNum)]);
if ~isdir(vidDir);
   mkdir(vidDir) 
end
myVidWriter = VideoWriter(fullfile(vidDir, ['E', num2str(expData.expInfo(1).expNum),'_AllTrials.avi']));
myVidWriter.FrameRate = frameRate;
open(myVidWriter)

disp('Concatenating videos...')
try
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
        end%if
    end%for
    
    close(myVidWriter)
    clear('myMovie')
    
    msg = 'Combined plotting videos concatenated successfully!';
catch
    msg = ['Error - video making failed on trial #', num2str(iTrial)];
end%try

end%function