%% This file processes the .csv files output by the Flir camera software

% Neal P. Dillon
% 11/4/2015

clc; clear; close all;

%% Basic info

FrameSize = [480, 640]; % rows, col

% Show video ??
show_video = 1;

% Trim video ??
trim_video = 0;
trim_range_frame = [300, 850]; % first, last frame - use only if video from Flir software is not already trimmed

% Crop video ??
crop_video = 1;
xy_size = 100; % in each direction
ctr_xy = [215, 378]; % row, col

%% Load csv files exported from Flir software

% Folder name
csv_folder = 'Rec_000087_Heat4_Medial';
thermal_data_folder = 'D:\NPD\PCI Thermal Data';
file_path = fullfile(thermal_data_folder, csv_folder);

% Read file info
csv_files_info = dir(file_path);

% Remove any unrelated files
remove_file_list = [];
for ii = 1:length(csv_files_info)
    if length(csv_files_info(ii).name) < 3
        remove_file_list = [remove_file_list, ii]; %#ok<AGROW>
    else
        if ~strcmp(csv_files_info(ii).name(end-2:end), 'csv')
            remove_file_list = [remove_file_list, ii]; %#ok<AGROW>
        end
    end
end
csv_files_info(remove_file_list) = [];
nFrames = length(csv_files_info);

%% Copy data from .csv files to Matlab workspace and save as .mat file

Thermal_Frames = zeros(FrameSize(1), FrameSize(2), nFrames, 'single');
Thermal_Frames_Time = zeros(1,nFrames);
hW = waitbar(0,'Reading .csv Files');
Frames_Found = zeros(1,nFrames);
for ii = 1:nFrames
    % Determine frame number for this file (not in order)
    f_name = csv_files_info(ii).name;
    f_num = str2num(f_name(length(csv_folder)+2:end-4)); %#ok<ST2NM>
    if trim_video == 1
        if f_num >= trim_range_frame(1) && f_num <= trim_range_frame(2)
            [Fii, Tii] = ImportThermalFrameFromCSV(fullfile(file_path, csv_files_info(ii).name));
            Thermal_Frames(:,:,f_num) = single(Fii);
            Thermal_Frames_Time(1,f_num) = Tii;
        end
    else
        [Fii, Tii] = ImportThermalFrameFromCSV(fullfile(file_path, csv_files_info(ii).name));
        Thermal_Frames(:,:,f_num) = single(Fii);
        Thermal_Frames_Time(1,f_num) = Tii;
    end
    Frames_Found(f_num) = 1;
    waitbar(ii/nFrames);
end
delete(hW);

if find(Frames_Found==0)
    warning('Not all frames found\n');
end

% Trim data if necessary
if trim_video == 1
    Thermal_Frames = Thermal_Frames(:,:,trim_range_frame(1):trim_range_frame(2));
    Thermal_Frames_Time = Thermal_Frames_Time(1,trim_range_frame(1):trim_range_frame(2));
    nFrames = size(Thermal_Frames,3);
end

% Crop data if necessary
if crop_video == 1
    Thermal_Frames = Thermal_Frames(ctr_xy(1)-xy_size:ctr_xy(1)+xy_size, ctr_xy(2)-xy_size:ctr_xy(2)+xy_size,:);
end

% Convert time data to seconds from start
Thermal_Frames_Time = Thermal_Frames_Time - Thermal_Frames_Time(1,1);

%% View video of thermal data

if show_video == 1

    spd_factor = 4;
    Temp_Range = [0 120];
    figure; hold on; axis([0 2*xy_size+1 0 2*xy_size+1]); axis equal; axis tight;
    xlabel('X [px]'); ylabel('Y [px]');
    title(['Heat Map (Approx. ', num2str(spd_factor), 'x Speed)']);
    imagesc(Thermal_Frames(:,:,1), Temp_Range);
    colormap hot;
    colorbar('EastOutside');
    for ii = 2:nFrames
        cla;
        imagesc(Thermal_Frames(:,:,ii), Temp_Range);
        drawnow;
        pause((Thermal_Frames_Time(ii)-Thermal_Frames_Time(ii-1))/spd_factor);
    end
    
end

%% Save as new .mat file
save(fullfile('Matlab Files', strcat(csv_folder, '.mat')), 'Thermal_Frames', 'Thermal_Frames_Time', '-v7.3');