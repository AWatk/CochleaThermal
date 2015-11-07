%% This file imports and analyzes the thermal imaging data

% Note: data from Flir camera must be first processed to organize the data

% Neal P. Dillon
% 10/31/2015

clc; clear; close all;
fig_size = get(0,'Screensize');

%% Options

show_video = 0;
show_mean_temp = 0;
plot_temp_vs_time = 1;

%% Load matlab file containing temperature and time data

pixels_per_mm = 20;
d_drill = 1.6; % [mm]

% Load .mat file, read list of variables
%file = 'Rec_000083_Heat7_Medial'; % 0.5 mm/s, continuous
file = 'Rec_000084_Heat4_Medial'; % 1 mm/s, continuous
%file = 'Rec_000085_Heat5_Medial'; % 2 mm/s, peck (1 mm steps)
%file = 'Rec_000087_Heat4_Medial'; % 1 mm/s, continuous
%file = 'Rec_000088_Heat5_Medial'; % 0.5 mm/s, continuous
%file = 'Rec_000089_Heat7_Medial'; % 2 mm/s, peck (1 mm steps)
load(strcat('Matlab Files\', file, '.mat'));
[nRows, nCols, nFrames] = size(Thermal_Frames);
if length(Thermal_Frames_Time) ~= nFrames
    error('Unequal sizes of frame and time data.');
end

% Determine video frame rate
frame_dt = mean(Thermal_Frames_Time(2:end) - Thermal_Frames_Time(1:end-1));

%% View video of thermal data

if show_video == 1

    spd_factor = 4;
    Temp_Range = [0 100];
    figure; hold on; axis([0 640 0 480]); axis equal; axis tight;
    xlabel('X [px]'); ylabel('Y [px]');
    title(['Heat Map (Approx. ', num2str(spd_factor), 'x Speed)']);
    imagesc(Thermal_Frames(:,:,1), Temp_Range);
    colormap hot;
    colorbar('EastOutside');
    for ii = 1:10:nFrames
        cla;
        imagesc(Thermal_Frames(:,:,ii), Temp_Range);
        drawnow;
        pause(frame_dt/spd_factor);
    end
    
end

%% Determine center of drill bit (via max temperature) and distance from each pixel to center

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

%% Compute average and maximum temperature for various points from drill surface

d_test_range = 0.0:0.25:1.0;
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

%% Calculate cumulative equivalent minutes at 43 deg Celsius

T_ref = 43; % see Saparetto et al. paper
CEM43 = zeros(1,length(d_test_range)); % equivalent minutes at 43 C

for ii = 1:length(d_test_range)
    for jj = 2:nFrames
        dt = Thermal_Frames_Time(1,jj) - Thermal_Frames_Time(1,jj-1);
        T_jj = Temp_vs_Time_Mean(ii,jj);
        if T_jj > T_ref
            R = 0.5;
        else
            R = 0.25;
        end
        CEM43(1,ii) = CEM43(1,ii) + R^(T_ref-T_jj);
    end
end

% Put this info in variable that can be easily copied to Excel file
ExcelCopyVariable = reshape([max(Temp_vs_Time_Max,[],2)'; CEM43],1,[]);



%% Temperature vs. Time plots for various distances from drill surface

if plot_temp_vs_time == 1
    c = distinguishable_colors(length(d_test_range));
    fig_pos_size = [0.1*fig_size(3), 0.1*fig_size(4), 0.8*fig_size(3), 0.8*fig_size(4)];
    f1 =  figure('visible', 'on', 'renderer', 'OpenGL', 'windowstyle', 'normal');
    set(f1, 'Position', fig_pos_size); % set figure position/size
    
    % Plot mean temperature
    %subplot(2,1,1);
    hold on; grid on;
    xlabel('Time [sec]', 'FontSize', 18); ylabel('Temperature [^oC]', 'FontSize', 18);
    title('Mean Temperature over Time - 1 mm/s Constant Speed Drilling', 'FontSize', 20);
    legend_text = cell(length(d_test_range),1);
    for ii = 1:length(d_test_range)
        plot(Thermal_Frames_Time', Temp_vs_Time_Mean(ii,:), 'color', c(ii,:));
        legend_text{ii} = ['d=', num2str(d_test_range(ii)), ' mm'];
    end
    axis([-inf inf 0 140]);
    legend(legend_text); hold off
    
    % Plot maximum temperature
    figure; 
    %subplot(2,1,2); hold on; grid on;
    xlabel('Time [sec]'); ylabel('Temperature [^oC]');
    title('Max Temperature over Time at Various Distances from Drill Surface');
    for ii = 1:length(d_test_range)
        plot(Thermal_Frames_Time', Temp_vs_Time_Max(ii,:), 'color', c(ii,:));
    end
    axis([-inf inf 0 160]);
    legend(legend_text);
end