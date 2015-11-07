%% This file processes the .csv files output by the Flir camera software

% Neal P. Dillon
% 11/4/2015

clc; clear; close all;

%% Basic info

FrameSize = [480, 640]; % rows, col
VideoFreq = 25; % Hz

% Trim video ??
trim = 1;
trim_range_frame = [550,1005];
xy_size = 100; % in each direction
ctr_xy = [130,406]; % row, col

%% Load csv files exported from Flir software

% Folder name
csv_folder = 'Rec_000083_Heat7_Medial';
thermal_data_folder = 'D:\NPD\PCI Thermal Data';
file_path = fullfile(thermal_data_folder, csv_folder);

% Read file info
csv_files_info = dir(file_path);

% Remove any unrelated files
remove_file_list = [];
parfor ii = 1:length(csv_files_info)
    if length(csv_files_info(ii).name) < 3
        remove_file_list = [remove_file_list, ii];
    else
        if ~strcmp(csv_files_info(ii).name(end-2:end), 'csv')
            remove_file_list = [remove_file_list, ii];
        end
    end
end
csv_files_info(remove_file_list) = [];
nFrames = length(csv_files_info);

%% Copy data from .csv files to Matlab workspace and save as .mat file

Thermal_Frames = zeros(FrameSize(1), FrameSize(2), nFrames, 'single');
hW = waitbar(0,'Reading .csv Files');
Frames_Found = zeros(1,nFrames);
for ii = 1:nFrames
    % Determine frame number for this file (not in order)
    f_name = csv_files_info(ii).name;
    f_num = str2num(f_name(length(csv_folder)+2:end-4)); %#ok<ST2NM>
    if trim == 1
        if f_num >= trim_range_frame(1) && f_num <= trim_range_frame(2)
            Thermal_Frames(:,:,f_num) = single(csvread(fullfile(file_path, csv_files_info(ii).name)));
        end
    else
        Thermal_Frames(:,:,f_num) = single(csvread(fullfile(file_path, csv_files_info(ii).name)));
    end
    Frames_Found(f_num) = 1;
    waitbar(ii/nFrames);
end
delete(hW);

if find(Frames_Found==0)
    warning('Not all frames found\n');
end

% Trim data if necessary
if trim == 1
    Thermal_Frames = Thermal_Frames(:,:,trim_range_frame(1):trim_range_frame(2));
    Thermal_Frames = Thermal_Frames(ctr_xy(1)-xy_size:ctr_xy(1)+xy_size, ctr_xy(2)-xy_size:ctr_xy(2)+xy_size,:);
    nFrames = size(Thermal_Frames,3);
end

% Convert time data to seconds from start
Thermal_Frames_Time = (1/VideoFreq)*0:nFrames-1;

% Save as new .mat file
save(fullfile('Matlab Files', strcat(csv_folder, '.mat')), 'Thermal_Frames', 'Thermal_Frames_Time', '-v7.3');