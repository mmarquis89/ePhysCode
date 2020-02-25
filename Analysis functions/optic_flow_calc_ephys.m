function flowData = optic_flow_calc_ephys(expData, parentDir, savePath)
%============================================================================================================================
% CALCULATE MEAN OPTICAL FLOW
% Calculates the mean optic flow across each frame of each video from the fly behavior camera. Returns an nx1 cell array with
% a vector of these values for each trial in the experiment, and also saves it as a variable 'flowData' in a .mat file.
%
% INPUTS:
%   expData   = entire data object for the experiment in question
%   
%   parentDir = the file path to the parent folder containing all the .tif files for each trial. Within this directory,
%               the frames for each trial should be saved in a folder named with the experiment and trial numbers
%               separated by an understore (e.g. 'E1_T3')
%   
%   savepath  = the file path to the location where the .mat file containing the optical flow data will be saved
%
% OUTPUTS: 
%   flowData  = An nTrials x 1 cell array containing the optic flow data for each video frame 
%
%============================================================================================================================

nTrials = length(expData.expInfo);
strDate = expData.expInfo(1).date;
flowData = cell(nTrials, 1);

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
            flowData{iTrial} = flowMag;
        end%if
    end%for
    
    % Save data to disk for future use
    save(savePath, 'flowData');
    
end%function