function filtData = notchFilter(data, sampRate, freq, bWidth)

% Apply notch filter to data 
% Input: time series data
%        sampling rate
%        notch frequency in Hz
%        notch bandwidth in samples

wo = freq/(sampRate/2);                                             % Set target frequency
bw = wo/bWidth;                                                     % Set band width
[b,a] = iirnotch(wo, bw);                                           % Create filter
filtData = filter(b,a,data);                                        % Apply to input data

end