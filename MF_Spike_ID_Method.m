
y = bl.scaledOut; %<-- this is my voltage data
time = 1/20000:1/20000:sum(bl.trialDuration); % 20000 is my sampling rate
time = time';
y = downsample(y,10); % To get rid of fast changes caused by noise
time = downsample(time, 10);
dy = diff(y)./diff(time);
figure; plot(time(2:end), dy)
dy2 = diff(dy)./diff(time(2:end));
figure; plot(time(3:end), dy2)
