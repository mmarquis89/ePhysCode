function [output] = shuffleTrials(odors, nReps)
% ==============================================================================================
% Creates a list of odors in a pseudorandom order such that the same odor will never be 
% presented on two consecutive trials. If there are fewer than four odors this will often get
% stuck in the loop for a long period of time, so in that case the odors are returned in a truly
% random order instead.
%
% odors: a Nx1 cell array with the names of the odors you want to present
% nReps: the number of times you want each odor to be listed in the output
% ==============================================================================================

% Repeat each odor the specified number of times and shuffle list
odorList = repelem(odors, nReps);
odorList = odorList(randperm(length(odorList)));

if numel(odors) > 3
    done = 0;
    while ~done
        % See if there are still any repeats, exit if not
        csq = csqTest(odorList);
        if sum(csq) == 0
            done = 1;
        else
            % Find the index of the first repeat, and look through the array for a location it could
            % be swapped with that will eliminate the repeat at that location without creating a new
            % one in the swapped element's location
            ind = find(csq, 1);
            for iTrial = 2:length(odorList)-1
                if ~strcmp(odorList{ind}, odorList{iTrial-1}) && ~strcmp(odorList{ind}, odorList{iTrial+1}) ...
                        && ~strcmp(odorList{iTrial}, odorList{ind-1}) && ~strcmp(odorList{iTrial}, odorList{ind+1})
                    % Swap elements and exit loop
                    newList = odorList;
                    newList{iTrial} = odorList{ind};
                    newList{ind} = odorList{iTrial};
                    odorList = newList;
                    break
                end
            end
        end
    end
end
    output = odorList;
end

% This function returns a logical vector indicating the locations of
% consecutive repeated entries in the input array
function csq = csqTest(odorList)
    csq = zeros(length(odorList), 1);
    for iOdor = 2:length(odorList)-1
        if strcmp(odorList{iOdor-1}, odorList{iOdor})
            csq(iOdor) = 1;
        end
    end
    if strcmp(odorList{end}, odorList{end-1})
       csq(end-1) = 1; 
    end
end