%{
Author: Timothy Fisher

Source: Andrew Janowczyk, Sergey Klimov, Mathworks

Description: To generate 500x500 tiles and a stiched together slide image.

Input: uigetdir to locate directory were images located.

Output: Preprocessed Tiles and Stiched

Usage: Write in more details.
    Follow on screen insturctions and select the correct dirrectory. It is important to keep the filenames consitent.
    If there is any spaces in filename then go to terminal/command line and run this code in the file directory:
        rename 's/ /_/g' *  # May need to install rename through sudo apt-install



%}

%% Step 0:  Clean up session.
% restoredefaultpath
% rehash toolboxcache
format compact; clear all; close all; clc; % clean up session
rng('default'); % reset random number generator for reproducibility

% Total Contour Calculation
total_contours_folder = '/media/tfisher1995/TIM_FILES/Research/code/full_slide_classifier_code_linux/all_annotation/annotation_results/step4';%uigetdir;
total_contours = dir(fullfile(total_contours_folder, '*.*'));
total_contours = total_contours(~[total_contours.isdir] & ~strncmpi('.', {total_contours.name}, 1));



% Retrive image image annotation coordiantes.
for i = 1 : length(total_contours)
    coordinates = readtable(string(total_contours(i,1).folder)+'/'+string(total_contours(i,1).name), 'Delimiter', ','); %(string(name+'_step4.csv'), 'Delimiter', ',');
    rownames = coordinates(:,1); % All rownames
    unique_rownames{i} = unique(rownames);
    total_rowname(i) = height(rownames);
    
    full_name = string(total_contours(i,1).name);
    name = full_name.extractBefore('_step4.csv');
    path = '/media/tfisher1995/TIM_FILES/Research/wsi/Dekalb_Shristi';
    image_info = imfinfo(string(path)+'/'+name+'.ndpi');
    %image_info = flip(image_info_2);
    image = string(path)+'/'+name+'.ndpi';
    image_width = image_info(1).Width;
    image_height = image_info(1).Height;
    
    coordinates(:,1) = []; % Remove the first row
    x_coor = table2array(coordinates(:,1:2:end)); % extracts the x corrdinates
    y_coor = table2array(coordinates(:,2:2:end)); % extracts the y corrdinates
    
    % x & y coordinates at level 3
    x_coor_downsampled = x_coor/(image_info(1).Width/image_info(3).Width);
    y_coor_downsampled = y_coor/(image_info(1).Width/image_info(3).Width);
    tB = tic; tT = tic;
    
    % Find a bounding box. (min_x,min_y), (min_x,max_y), (max_x,max_y), (max_x,min_y)
    min_x_down = min(min(x_coor_downsampled));%(j,:));
    max_x_down = max(max(x_coor_downsampled));%(j,:));
    min_y_down = min(min(y_coor_downsampled));%(j,:));
    max_y_down = max(max(y_coor_downsampled));%(j,:));
    
    
    wsi_down = imread(string(path)+'/'+name+'.ndpi', 3);
    imshow(wsi_down)
    hold on
    
    for scat = 1:total_rowname(i)
        scatter(x_coor_downsampled(scat,:), y_coor_downsampled(scat,:))
    end
    
    mkdir('wsi_contours_level_3')
    savefig('wsi_contours_level_3/'+name+'.fig')
    hold off
end
    
    
    
