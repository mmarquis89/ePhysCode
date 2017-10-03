function msg = make_vids(expData, parentDir)
%============================================================================================================================
% CREATE MOVIES FROM .TIF FILES
% Creates an .avi movie for each trial of an experiment from the .tif files captured by the fly behavior camera, and returns 
% a message string indicating whether the operation was a success (and if not, which trial it failed on). The videos are
% saved in the same location as the .tif files that they were created from.
%       expData = entire data object for the experiment in question
%       parentDir = the file path to the parent folder containing all the .tif files for each trial. Within this directory,
%                   the frames for each trial should be saved in a folder named with the experiment and trial numbers
%                   separated by an understore (e.g. 'E1_T3')
%============================================================================================================================

strDate = expData.expInfo(1).date;
nTrials = length(expData.expInfo);

disp('Creating videos...');
try
    for iTrial = 1:nTrials
        % Get name of current trial
        trialStr = ['E', num2str(expData.expInfo(1).expNum), '_T', num2str(iTrial)];
        disp(trialStr)
        savePath = fullfile(parentDir, strDate, trialStr);
        currFiles = dir(fullfile(savePath, '*.tif'));
        
        % Make sure there's at least one image file and no .avi file already in this trial's directory
        if ~isempty(currFiles) && isempty(dir(fullfile(savePath, '*.avi'))) 
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
        end%if
    end%for
    msg = 'Videos created successfully!';
catch
    msg = ['Error - video making failed on trial #', num2str(iTrial)];
end%try

end%function