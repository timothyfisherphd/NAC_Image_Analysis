%% Step 0:  Clean up session.
% restoredefaultpath
% rehash toolboxcache
%format compact; clear all; close all; clc; % clean up session
rng('default'); % reset random number generator for reproducibility

addpath([pwd,'/subroutines'],'-end'); % my own functions, see license
addpath([pwd,'/lbp'],'-end'); % code for LBP, see license in subfolder
addpath([pwd,'/perceptual'],'-end'); % code for perceptual features, see license in subfolder

% Step 1: Define some constants (paths, filenames and the like)
cnst.effectiveImageSize = 150*150; % default 150*150
cnst.noOverheat =  true; % pause program after each iteration to prevent overheat, default true
cnst.limitedMode = false; % use only the first N images per class, default false
cnst.limit = 625;      % if limitedMode==true, how many images?, default 625
cnst.featureType = {'all6'}; %'best2','best3','best4','best5','all6'}; % one or more of {'histogram_lower','histogram_higher','gabor','perceptual','f-lbp','glcmRotInv','best2','best3'};
cnst.gaborArray = gabor(2:2:12,0:30:150); % create gabor filter bank

% Total Contour Calculation
total_contours_folder = '/media/tfisher1995/TIM_FILES/Research/code/full_slide_classifier_code_linux/all_annotation/annotation_results/step4';
total_contours = dir(fullfile(total_contours_folder, '*.*'));
total_contours = total_contours(~[total_contours.isdir] & ~strncmpi('.', {total_contours.name}, 1));

% % Call pyenv outside loop.
% py_path = '/home/tfisher1995/opEnv/bin/python';
% pe = pyenv('Version', py_path);

% Check for variables
if ~exist ('level','var')
    level = str2double(inputdlg('Features: Please enter level for openslide:'));
end

if ~exist ('grid_step_size', 'var')
    grid_step_size = str2double(inputdlg('Define window size for contour (eg. 1000): ')); % Set window size as 1000
end

example_tile = imread('/media/tfisher1995/TIM_FILES/Research/code/old/linux/matlab/full_slide_classifier/Kather_texture_2016_image_tiles_5000/01_TUMOR/1A11_CRC-Prim-HE-07_022.tif_Row_601_Col_151.tif');4

tB = tic; tT = tic; tImage = tic; % Set timers

for currFeat = cnst.featureType % iterate through feature types
    currFeat = char(currFeat);         % convert name of feature set to char
    cnst.numFeatures = getNumFeat(currFeat); % request number of features
    
%     for ii = 1 : length(unique_rownames)
%         TisCats = unique_rownames{1,ii};
%         TisCatsName = table2array(TisCats)';
%         TisCatImgCount = zeros(size(TisCats,1),1);
%     end
    
    for i = 1:length(total_contours)
        
        coordinates = readtable(string(total_contours(i,1).folder)+'/'+string(total_contours(i,1).name), 'Delimiter', ',');
        rownames = coordinates(:,1); % All rownames
        unique_rownames{i} = unique(rownames);
        total_unique = unique(vertcat(unique_rownames{:}));
        total_rowname(i) = height(rownames);
        total_rowname_sum = sum(total_rowname);
        
        % Preallocate Arrays
        source_array = double(zeros(cnst.numFeatures,total_rowname_sum)); % preallocate | TisCatImgCount is amount of total contours which is equal to total_rownames
        target_array = uint8(zeros(size(total_unique,1),total_rowname_sum));   % preallocate
        
    end
    
    feature = 1;
    it = 1;
    %% Generate Features
    while feature <= total_rowname_sum
        for j = 1:total_rowname(it)
            
            % Retrive image info
            full_name = string(total_contours(it,1).name);
            name = full_name.extractBefore('_step4.csv');
            path = '/media/tfisher1995/TIM_FILES/Research/wsi/Dekalb_Shristi';
            image_info = imfinfo(string(path)+'/'+name+'.ndpi');
            image = string(path)+'/'+name+'.ndpi';
            image_width = image_info(1).Width; % x-axis of pixel coordinate map at level 0
            image_height = image_info(1).Height; %y-axis of pixel coordinate map at level 0
            coordinates = readtable(string(total_contours(j,1).folder)+'/'+string(total_contours(j,1).name), 'Delimiter', ',');
            coordinates(:,1) = []; % Remove the first row
            x_coor = table2array(coordinates(:,1:2:end)); % extracts the x corrdinates
            y_coor = table2array(coordinates(:,2:2:end)); % extracts the y corrdinates
            grid_rx = floor(x_coor(j,:));
            grid_ry = floor(y_coor(j,:));
            grid_min_x = min(grid_rx);
            grid_max_x = max(grid_rx);
            grid_min_y = min(grid_ry);
            grid_max_y = max(grid_ry);
            grid_width_x = grid_max_x - grid_min_x;
            grid_height_y = grid_max_y - grid_min_y;
            
            % set up an index of first element of current class
            if it>1, firstEl = sum(total_rowname(1:it-1))+1; else firstEl = 1; end
            
            
            % Check for image size
            if grid_width_x > 7000 || grid_height_y > 7000
                
                % Large Contour
                disp('Processing Large Contour via Sliding Window Method')
                
                
                window_tile = num2cell(zeros(ceil(grid_height_y/grid_step_size), ceil(grid_width_x/grid_step_size))); % pre-allocation
                window_contour_tile = num2cell(zeros(ceil(grid_height_y/grid_step_size), ceil(grid_width_x/grid_step_size))); % pre-allocation
                window_min_x = grid_min_x;
                window_min_y = grid_min_y;
                grid_y = 1;
                
                for grid_x = 1 : ceil(grid_width_x/grid_step_size)
                    if window_min_x < grid_max_x
                        tile = use_example(image, window_min_x , window_min_y, level, grid_step_size, grid_step_size);
                        
                        % x-values
                        window_tile_x = grid_rx;
                        window_tile_x(isnan(window_tile_x)) = ''; % To remove NaN's
                        window_contour_x = find(window_tile_x<=(window_min_x+grid_step_size));
                        window_x= window_tile_x(window_contour_x) - window_min_x;
                        
                        % Y-values
                        window_tile_y = grid_ry;
                        window_tile_y(isnan(window_tile_y)) = ''; % To remove NaN's
                        window_contour_y = find(window_tile_y<=(window_min_y+grid_step_size));
                        window_y= window_tile_y(window_contour_y) - window_min_y;
                        clf % Close any current figure.
                        imshow(tile)
                        hold on
                        scatter(window_x, window_y)
                        hold off
                        
                        window_tile(grid_x,grid_y)= num2cell(imresize(tile,.1));
                        window_min_x = window_min_x + grid_step_size;
                        
                    else
                        
                        window_min_x = grid_max_x;
                        tile = use_example(image, window_min_x , window_min_y, level, grid_step_size, grid_step_size);
                        %window_tile{3,1}= imresize(tile,.1); %change 1 for X_iterator and 3 for Y_iterator
                        window_tile(grid_x,grid_y)= num2cell(imresize(tile,.1));
                        grid_y = grid_y + 1;
                        window_min_y = window_min_y + grid_step_size;
                        window_min_x = grid_min_x;
                        
                        
                        
                        if window_min_y <= grid_max_y
                            window_min_y = window_min_y + grid_step_size;
                        else
                            window_min_y = window_min_y + (grid_max_y - window_min_y);
                        end
                        
                    end
                    
                    window_min_x=window_min_x+grid_step_size;
                    
                end
                
                
                
                
                % Calculate texture features.
                currImg = tile;
                [w, h, ~] = size(currImg);
                [rows, columns, ~] = size(example_tile);
                if w >= rows & h >= columns
                    currImg = imresize(currImg, [150 150]);
                    % compute the feature vector for the current image
                    currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
                    % add current feature vector to the source array
                    source_array(:,firstEl-1+j) = currFeatureVector(:);
                else
                    continue
                end
                
            else
                % Small Contour
                disp('Processing Small Contour')
                tile = use_example(image, grid_min_x, grid_min_y, level, grid_width_x, grid_height_y);
                
                small_x = double(grid_rx);
                small_x(isnan(small_x)) = ''; % To remove NaN's
                small_x_scale = small_x - grid_min_x; % To scale coordinates to fit contour tile.
                small_y = double(grid_ry);
                small_y(isnan(small_y)) = ''; % To remove NaN's
                small_y_scale = small_y - grid_min_y; % To scale coordinates to fit contour tile
                imshow(tile)
                hold on
                scatter(small_x_scale, small_y_scale)
                hold off
                
                % Calculate texture features.
                currImg = tile;
                [w, h, ~] = size(currImg);
                [rows, columns, ~] = size(example_tile);
                if w >= rows & h >= columns
                    currImg = imresize(currImg, [150 150]);
                    % compute the feature vector for the current image
                    currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
                    % add current feature vector to the source array
                    source_array(:,firstEl-1+j) = currFeatureVector(:);
                else
                    continue
                end
            end
            %
        end
        feature=  feature + total_rowname(it);
        it = it+1;
    end
end