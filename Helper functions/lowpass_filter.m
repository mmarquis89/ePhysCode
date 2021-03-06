function Hd = lowpass_filter
% ==============================================================================================
% LOWPASSFILTER Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 8.5 and the Signal Processing Toolbox 7.0.
% Generated on: 23-Feb-2016 13:34:15

% Butterworth Lowpass filter designed using FDESIGN.LOWPASS.
% ==============================================================================================

% All frequency values are in Hz.
Fs = 10000;  % Sampling Frequency

N  = 50;  % Order
Fc = 5;   % Cutoff Frequency

% Construct an FDESIGN object and call its BUTTER method.
h  = fdesign.lowpass('N,F3dB', N, Fc, Fs);
Hd = design(h, 'butter');

% [EOF]
