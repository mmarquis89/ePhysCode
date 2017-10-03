function [pfft, fVals] = get_freq_content(data, sampRate)
% ===============================================================
% Creates frequency domain power spectrum of time series data
% Input: data, sampling rate
% Output: power, frequency values
% ===============================================================
L = length(data);

fftSignal = fftshift(fft(data));
pfft = fftSignal.*conj(fftSignal)/L.^2;
fVals = sampRate/2*linspace(-1,1,L);

end