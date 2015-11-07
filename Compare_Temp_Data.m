%% This file compares the temperature vs time data for several trials at a given distances away from the drill surface

% Neal P. Dillon
% 11/5/2015

clc; clear; close all;
fig_size = get(0,'Screensize');

%% Options

show_mean_temp = 0;
plot_temp_vs_time = 1;

%% Basic data and files to test

pixels_per_mm = 20;
d_drill = 1.6; % [mm]

d_test_range = 0.4;

file1 = 'Rec_000083_Heat7_Medial'; % 0.5 mm/s, continuous
file2 = 'Rec_000084_Heat4_Medial'; % 1 mm/s, continuous
file3 = 'Rec_000085_Heat5_Medial'; % 2 mm/s, peck (1 mm steps)
file4 = 'Rec_000088_Heat5_Medial'; % 0.5 mm/s, continuous
file5 = 'Rec_000087_Heat4_Medial';
file6 = 'Rec_000089_Heat7_Medial'; % 2 mm/s, peck (1 mm steps)

file_list = {file1, file2, file3, file4, file5, file6};
t_start = ceil([3.5, 0.095, 8.4, 2.2, 1.7, 2.9]);
start_ind = ceil([3.5*25, 1.1*25, 8.4*25, 2.7*25, 1.7*25, 2.9*25]);

Temp_vs_Time = struct('Mean', [], 'Max', [], 'Time', []);

%% Load and analyze each file

for file_num = 1:length(file_list)
    
    file_name = file_list{file_num};

    % Load .mat file, read list of variables
    load(strcat('Matlab Files\', file_name, '.mat'));
    [nRows, nCols, nFrames] = size(Thermal_Frames);
    if length(Thermal_Frames_Time) ~= nFrames
        error('Unequal sizes of frame and time data.');
    end

    % Determine center of drill bit (via max temperature) and distance from each pixel to center

    % Calc drill center pixel (hottest average pixel of filtered heat map)
    Mean_Pixel_Temp = sum(Thermal_Frames(:,:,:), 3)/nFrames;
    sigma = 3;
    cutoff = ceil(3*sigma);
    h = fspecial('gaussian', 2*cutoff+1,sigma);
    Mean_Pixel_Temp = conv2(Mean_Pixel_Temp, h, 'same');

    [~, ind_max] = max(Mean_Pixel_Temp(:));
    [ctr_ii, ctr_jj] = ind2sub(size(Mean_Pixel_Temp), ind_max);

    % Plot
    if show_mean_temp == 1
        figure; hold on; axis([0 640 0 480]); axis equal; axis tight;
        xlabel('X [px]'); ylabel('Y [px]');
        title('Mean Temperatures for Each Location');
        imagesc(Mean_Pixel_Temp, [min(Mean_Pixel_Temp(:)), max(Mean_Pixel_Temp(:))]);
        colormap hot;
        colorbar('EastOutside');
        scatter(ctr_jj, ctr_ii,20, 'g', 'filled');
    end

    % Calculate distance between center and each pixel
    dmap_increment = 0.05; % [mm]
    ctr_image = zeros(nRows, nCols); ctr_image(ctr_ii, ctr_jj) = 1;
    ctr_dmap = double(bwdist(ctr_image))/pixels_per_mm;
    ctr_dmap = dmap_increment*(round((1/dmap_increment)*ctr_dmap)) - d_drill/2;

    % Compute average and maximum temperature for various points from drill surface

    Temp_vs_Time_Mean = zeros(length(d_test_range), nFrames); % matrix of average temp at given distance for each frame
    Temp_vs_Time_Max = zeros(length(d_test_range), nFrames); % matrix of average temp at given distance for each frame

    for ii = 1:length(d_test_range)
        % Determine indices of pixels for a given distance
        dist = d_test_range(ii);
        dist_ind = find(abs(ctr_dmap-dist)<0.001);
        [dist_i, dist_j] = ind2sub(size(ctr_dmap), dist_ind);
        for jj = 1:nFrames
            Frame_jj = Thermal_Frames(:,:,jj);
            temps = Frame_jj(dist_ind);
            Temp_vs_Time_Mean(ii,jj) = mean(temps);
            Temp_vs_Time_Max(ii,jj) = max(temps);
        end
    end
    
%     Temp_vs_Time_Mean = Temp_vs_Time_Mean(1,start_ind(file_num):end);
%     Temp_vs_Time_Max = Temp_vs_Time_Max(1,start_ind(file_num):end);
    Thermal_Frames_Time = Thermal_Frames_Time - t_start(file_num);
    
    Temp_vs_Time(file_num).Mean = Temp_vs_Time_Mean;
    Temp_vs_Time(file_num).Max = Temp_vs_Time_Max;
    Temp_vs_Time(file_num).Time = Thermal_Frames_Time;
    
end

%% Temperature vs. Time plots for various distances from drill surface

if plot_temp_vs_time == 1
    c = [0.7 0 0; 0 0.7 0; 0 0 0.7; 0.7 0 0; 0 0.7 0; 0 0 0.7];
    l = {'-', '-', '-', '--', '--', '--'};
    fig_pos_size = [0.1*fig_size(3), 0.1*fig_size(4), 0.8*fig_size(3), 0.8*fig_size(4)];
    f1 =  figure('visible', 'on', 'renderer', 'OpenGL', 'windowstyle', 'normal');
    set(f1, 'Position', fig_pos_size); % set figure position/size
    hold on; grid on;
    xlabel('Time (sec)', 'FontSize', 18); ylabel('Temperature (^oC)', 'FontSize', 18);
    %title('Mean Bone Temperature at Distance Away from Drill Surface', 'FontSize', 18);
    for ii = 1:length(file_list)
        plot(Temp_vs_Time(ii).Time', Temp_vs_Time(ii).Mean, 'color', c(ii,:), 'linestyle', l{ii},'LineWidth', 2);
    end
    axis([0 20 0 100]);
    legend_text = {'0.5 mm/s const.', '1.0 mm/s const.', '2.0 mm/s peck'};
    legend(legend_text, 'FontSize', 16); hold off
end