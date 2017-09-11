function [ aOut ] = open_tif_fast( tifpath )
% Output: [Lines, Pixels, Channels, Planes, Volumes]

% Open tiff file
tifObj = Tiff(tifpath,'r');

% Iterate over the tiff file to find out how many images there are
numImg = 1;
while ~tifObj.lastDirectory()

    try
        tifObj.nextDirectory();
    catch
        break;
    end
    numImg = numImg + 1;
end

frameString = tifObj.getTag('ImageDescription');
%[ num_channels, num_planes, num_volumes ] = parse_si51_frame_string( frameString );
%num_channels = si51_frame_string_get_value_for_key(frameString, 'hChannels.channelsActive');
num_channels = 1;
num_planes = si51_frame_string_get_value_for_key(frameString, 'hFastZ.numFramesPerVolume');
num_volumes = si51_frame_string_get_value_for_key(frameString, 'hFastZ.numVolumes');

% Get TIFF information
numLines = tifObj.getTag('ImageLength');
numPixels = tifObj.getTag('ImageWidth');
switch tifObj.getTag('SampleFormat')
    case 1
        imageDataType = 'uint16';
    case 2
        imageDataType = 'int16';
    otherwise
        assert('Unrecognized or unsupported SampleFormat tag found');
end

aOut_tmp = zeros(numLines,numPixels,numImg,imageDataType);
for idx = 1:numImg
    tifObj.setDirectory(idx);
    aOut_tmp(:,:,idx) = tifObj.read();
end

aOut = reshape(aOut_tmp, [numLines,numPixels, num_channels,num_planes,num_volumes]);

tifObj.close();
end

