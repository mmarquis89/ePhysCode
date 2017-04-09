classdef acqSettings

% Object to hold various acquisition parameters

    properties
        
        % General parameters
        expNum                     % Experiment (fly or cell) number
        trialDuration              % [pre-stim, clean valve open, post-stim] in seconds. If trialDuration is a single integer, a trace of that duration will be acquired.
        altStimDuration            % [pre-stim, stim on, post-stim] in seconds (sum must match trialDuration). Use '[]' if not using alternate stim on this trial. 
        altStimType                % String describing the type of alternative stim being used. Pass '[]' for no alt stim. Valid types are: 'opto', 'ionto', 'eject'
        altStimParam               % Optional additional parameter for the alternate stimulus.
        odor                       % Record of odor ID - Use 'EmptyVial', 'ParaffinOil', or the odor name, or '[]' if no stim is delivered
        valveID                    % A number from 1-4 indicating which valve to use if an odor stimulus is delivered (use '[]' if no stim)
        Istep                      % The size of the current step to use at the beginning of the trial in pA. [] will skip the step.
        Ihold = 0                  % The holding current in pA to constantly inject into the cell
        
        % Hardcoded parameters
        sampRate = 20000;               % Input and output sampling rate for the trial
        stepStartTime = 1;              % Time in seconds from the start of the trial to begin the current step
        stepLength = 1;                 % Length of current step in seconds
        DAQOffset = 1.5;                % The amount of current the DAQ is injecting when the command is 0. Will be subtracted from current command to offset this
        altStimChan = 'port0/line12';   % The name of the output channel on the DAQ for the alternate stimulus           
        frameRate = 30;                 % The rate at which the behavior camera should acquire images during the trial.
    end
end

