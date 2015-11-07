%% This file processes the .mat files output by the Flir camera software

% Neal P. Dillon
% 10/30/2015

clc; clear; close all;

%% Load matlab file exported from Flir software

% Load .mat file, read list of variables
file = 'Rec--000088-306_12_10_22_142';
load(strcat('D:\', file, '.mat'));
FramesList = whos;
FramesList = FramesList(2:end-1);
nFrames = length(FramesList)/2;
if rem(length(FramesList),2) ~= 0
    error('Unequal number of data/time and frame variables.');
end

Thermal_Frames = zeros([size(Frame0), nFrames]);
Thermal_DateTime = zeros(nFrames, length(Frame0_DateTime));
Data_ii_List = zeros(nFrames,2);
for ii = 1:length(FramesList)
    if FramesList(ii).size == size(Frame0)
        FrameStr = FramesList(ii).name;
        FrameNum = str2num(FrameStr(6:end)) + 1; %#ok<*ST2NM>
        Thermal_Frames(:,:,FrameNum) = eval(FramesList(ii).name);
        Data_ii_List(FrameNum,1) = 1;
    elseif FramesList(ii).size == size(Frame0_DateTime)
        FrameStr = strsplit(FramesList(ii).name, '_');
        FrameStr = FrameStr{1};
        FrameNum = str2num(FrameStr(6:end))+1;
        Thermal_DateTime(FrameNum,:) = eval(FramesList(ii).name);
        Data_ii_List(FrameNum,2) = 1;
    else
        warning('Variable %d not same size as frame or date info', ii);
    end
end

% Convert time data to seconds from start
Thermal_Frames_Time = Thermal_DateTime(:,4)*60*60 + Thermal_DateTime(:,5)*60 ...
        + Thermal_DateTime(:,6) + Thermal_DateTime(:,7)/1000;
Thermal_Frames_Time = Thermal_Frames_Time - Thermal_Frames_Time(1);

% Save as new .mat file
save(fullfile('Matlab Files', strcat(file, '_Proc.mat')), 'Thermal_Frames', 'Thermal_Frames_Time');