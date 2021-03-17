
%% Step 0:  Clean up session.
% restoredefaultpath
% rehash toolboxcache
% format compact; clear all; close all; clc; % clean up session
% rng('default'); % reset random number generator for reproducibility
warning('off','all') % To turn off all warnings.

addpath([pwd,'/subroutines/'],'-end');
addpath([pwd,'/lbp/'],'-end');
addpath([pwd,'/perceptual/'],'-end');

% Step 1: Define some constants (paths, filenames and the like)
cnst.effectiveImageSize = 150*150; % default 150*150
cnst.noOverheat =  true; % pause program after each iteration to prevent overheat, default true
cnst.limitedMode = false; % use only the first N images per class, default false
cnst.limit = 625;      % if limitedMode==true, how many images?, default 625
cnst.featureType = {'all6'}; %'best2','best3','best4','best5','all6'}; % one or more of {'histogram_lower','histogram_higher','gabor','perceptual','f-lbp','glcmRotInv','best2','best3'};
cnst.gaborArray = gabor(2:2:12,0:30:150); % create gabor filter bank

%Total Contour Calculation
%total_contours_folder = '/media/tfisher1995/TIM_FILES/Research/code/FSC/Classifier_1/all_annotation'; %uigetdir; %'all_annotation/annotation_results/step4';
total_contours_folder = 'all_annotation';
total_contours = dir(fullfile(total_contours_folder, '*.*'));
total_contours = total_contours(~[total_contours.isdir] & ~strncmpi('.', {total_contours.name}, 1));


% % Call pyenv outside loop.
% py_path = '/home/tfisher1995/opEnv/bin/python';
% pe = pyenv('Version', py_path);

% Create variables
level = 0; % Level for openslide highest resolution
level2 = 6; % Level for downsamples openslide
grid_step_size = 500; % Bigger tile size for less processing time.

% % Check for variables
% if ~exist ('level','var')
%     level = str2double(inputdlg('Features: Please enter level for openslide (eg. 0): '));
% end
% 
% if ~exist ('grid_step_size', 'var')
%     grid_step_size = str2double(inputdlg('Define window size for contour (eg. 1000): ')); % Set window size as 1000
% end

example_tile = imread('Kather_texture_2016_image_tiles_5000/01_TUMOR/1A11_CRC-Prim-HE-07_022.tif_Row_601_Col_151.tif');

tB = tic; tT = tic; tImage = tic; % Set timers
close all

for currFeat = cnst.featureType % iterate through feature types
    currFeat = char(currFeat);         % convert name of feature set to char
    cnst.numFeatures = getNumFeat(currFeat); % request number of features
    
    for i = 1:length(total_contours)
        coordinates = readtable(string(total_contours(i,1).folder)+'/'+string(total_contours(i,1).name), 'Delimiter', ',', 'ReadVariableNames',false, 'ReadRowNames', false);
        rowname = rows2vars(coordinates(:,1));
        rowname(:,1)= [];
        rownames{i} = table2cell(rowname); % All rownames
        unique_rownames{i} = unique(rownames{1,i});
        total_unique = unique(horzcat(unique_rownames{:}));
        total_rowname(i) = width(cell2table(rownames{1,i}));
        total_rowname_sum = sum(total_rowname);
    end
    
%     for b = 1:length(total_unique)
%         s1 = total_unique;
%         s2 = total_unique(b);
%         tf = strncmpi(s1,s2,3);
%         
%         indices = find(tf==1);
%         total_unique(indices) = s2;
%     end
%     
%     total_unique = unique(total_unique);
    feature = 1;
    it = 1;
    %% Generate Features
    while feature <= total_rowname_sum
        for j = 1:total_rowname(it)
            
            % Retrive image info
            full_name = string(total_contours(it,1).name);
            name_file = full_name.extractBefore('.csv');
            if length(strfind(name_file,'_')) > 1
                name_index = strfind(full_name, '_');
                name = extractBefore(full_name, name_index(2));
            elseif length(strfind(name_file,'_')) == 1
                name_index = strfind(full_name, '_');
                name = extractBefore(full_name, name_index(1));
            end
            
            path = '/media/tfisher1995/TIM_FILES/Research/wsi/Dekalb_Shristi_HE';
            image_info = imfinfo(string(path)+'/'+name_file+'.ndpi');
            image = string(path)+'/'+name_file+'.ndpi';
            image_width = image_info(1).Width; % x-axis/rows of pixel coordinate map at level 0
            image_height = image_info(1).Height; %y-axis/column of pixel coordinate map at level 0
            coordinates = readtable(string(total_contours(it,1).folder)+'/'+string(total_contours(it,1).name), 'Delimiter', ',');
            coordinates(:,1) = []; % Remove the first column
            
            % Extract coordiantes
            x_coor = table2array(coordinates(:,1:2:end)); % extracts the x corrdinates
            y_coor = table2array(coordinates(:,2:2:end)); % extracts the y corrdinates
            
            % Extract contour coordinates
            grid_rx = floor(x_coor(j,:));
            grid_ry = floor(y_coor(j,:));
            
            % Find the bounding box.
            grid_min_x = min(grid_rx);
            grid_max_x = max(grid_rx);
            grid_min_y = min(grid_ry);
            grid_max_y = max(grid_ry);
            grid_width_x = grid_max_x - grid_min_x;
            grid_height_y = grid_max_y - grid_min_y;
            
            % set up an index of first element of current class
            if it>1, firstEl = sum(total_rowname(1:it-1))+1; else firstEl = 1; end
            
            % Check for contour size
            if grid_width_x > 7000 || grid_height_y > 7000
                %% Large Contour
                step = 'Processing %d Large Contour of %d via Sliding Window Method for %s';
                step_str = sprintf(step, j, total_rowname(it), name);
                disp(step_str)
                
%                 if ~exist ('level2','var')
%                     level2 = str2double(inputdlg('Features: Please enter level for openslide of large contour (eg. 6): '));
%                 end
           
                % Shift and scale down coordinates
                % Find mask/contour bounding box
                mask_min_x = grid_min_x /2^6;
                mask_max_x = grid_max_x / 2^6;
                mask_min_y = grid_min_y / 2^6;
                mask_max_y = grid_max_y / 2^6;
                mask_width_x = grid_width_x / 2^6;
                mask_height_y = grid_height_y / 2^6;
                
                % Read contour with openslide
                tile_info = use_info(image); % openslide.level[#].downsample = 64, stored in a py dictionary.
                tile = use_example(image, grid_min_x, grid_min_y, level2, mask_width_x, mask_height_y);
                
                
                % Create a mask
                size_tile = size(tile);
                mask = zeros(size_tile(1), size_tile(2));
                mask_tile_x = grid_rx;
                mask_x= mask_tile_x - grid_min_x;
                mask_x(isnan(mask_x)) = '';
                mask_x = mask_x / 2^6; % 2^6 == image_info(1).Width/image_info(4).Width
                mask_tile_y = grid_ry;
                mask_y= mask_tile_y - grid_min_y;
                mask_y(isnan(mask_y)) = '';
                mask_y = mask_y / 2^6;
                
                close all
                imshow(mask)
                
                if numel(mask_x) > numel(mask_y)
                    len_diff = numel(mask_x) - numel(mask_y);
                    mask_x = mask_x(:,1:end-len_diff);
                elseif numel(mask_y) > numel(mask_x)
                    len_diff = numel(mask_y) - numel(mask_x);
                    mask_y = mask_y(:,1:end-len_diff);
                end
                
                
                roi = drawpolygon(gca,'Position', [mask_x; mask_y]');
                mask_final = createMask(roi);
                
                %                 % Check current image
                %                 figure, imagesc(tile);
                %                 figure, imagesc(imread(image,4));
                %                 figure, imshow(mask_final);
                %                 close all
                
                % Get the dimensions of the image.
                [rows columns numberOfColorBands] = size(tile);
                [rows2 columns2 numberOfColorBands2] = size(mask_final);
                
                % Sliding Window Judgement
                blockSizeR = grid_step_size / 2^6; % Rows in block
                blockSizeC = blockSizeR; % Columns in block
                
                % Figure out the size of each block in rows.
                % Most will be blockSizeR but there may be a remainder amount of less than that.
                wholeBlockRows = floor(rows / blockSizeR);
                blockVectorR = [blockSizeR * ones(1, wholeBlockRows), rem(rows, blockSizeR)];
                
                % Figure out the size of each block in columns.
                wholeBlockCols = floor(columns / blockSizeC);
                blockVectorC = [blockSizeC * ones(1, wholeBlockCols), rem(columns, blockSizeC)];
                
                mask = zeros(sum(ceil(blockVectorR)), sum(ceil(blockVectorC)));
                imshow(mask)
                roi = drawpolygon(gca,'Position', [mask_x; mask_y]');
                mask_final = createMask(roi);
                figure,imshow(mask_final)
                
                % Create the cell array, ca. This is for contour
                % Each cell (except for the remainder cells at the end of the image)
                % in the array contains a blockSizeR by blockSizeC by 3 color array.
                % This line is where the image is actually divided up into blocks
                if numberOfColorBands > 1
                    % It's a color image.
                    ca = mat2cell(tile, blockVectorR, blockVectorC, numberOfColorBands);
                else
                    % If only has one colorband from the
                    % color normalization and deconvolution
                    ca = mat2cell(tile, blockVectorR, blockVectorC);
                end
                
                % Now display all the blocks at the low resolution.
                numPlotsR = size(ca, 1);
                numPlotsC = size(ca, 2);
                
                % Size of block rows
                blockVectorR2 = ceil(blockVectorR);
                blockVectorC2 = ceil(blockVectorC);
                
                
                % This is cell array for the binary mask.
                if numberOfColorBands2 > 1
                    % It's a color image.
                    ca2 = mat2cell(mask_final, blockVectorR2, blockVectorC2, numberOfColorBands2);
                else
                    % If only has one colorband from the
                    % color normalization and deconvolution
                    ca2 = mat2cell(mask_final, blockVectorR2, blockVectorC2);
                end
                
                % Now display all the mask at the down-scaled size.
                numPlotsR2 = size(ca2, 1);
                numPlotsC2 = size(ca2, 2);
                
                clear table_add
                
                for r = 1 : numPlotsR % for loop of y-axis
                    for c = 1 : numPlotsC  % for loop of x-axis
                        rgbBlock = ca{r,c};
                        maskBlock = ca2{r,c};
                        
                        totalMaskBlocks = size(ca2);
                        totalMaskBlocks = totalMaskBlocks(1) * totalMaskBlocks(2);
                        
                        % Count pixels of mask
                        numberOfPixels = numel(maskBlock);
                        numberOfTruePixels = sum(maskBlock(:));
                        trueRatio = numberOfTruePixels/numberOfPixels;
                        
                        % Condition statements to check if region is where the mask foreground is.
                        if trueRatio > .5
                            
                            if ~exist ('table_add','var')
                                table_add = 0;
                            else
                                table_add = table_add+1;
                            end
                            
                            % upscale the rgbBlock from 2^6 to orginal size
                            top_left_X = (mask_min_x + (blockSizeR*c)) * 2^6;
                            top_left_Y = (mask_min_y + (blockSizeC*r)) * 2^6;
                            tile = use_example(image, top_left_X, top_left_Y, level, grid_step_size, grid_step_size);
                            rowname_table = cell2table(rownames{1,it});
                            large_contour_class = rowname_table{1,j};
                            
                            if width(rowname_table)+1 <= j+table_add % To make sure variable index does not exceed table dimensions
                                rowname_table2 = addvars(rowname_table, large_contour_class);
                            else
                                rowname_table2 = addvars(rowname_table,large_contour_class,'After',(j+table_add));
                            end
                            
                            rownames{it,1} = table2cell(rowname_table2);
                            class = string(rowname_table{1,j});
                            
                            %                             % Check target rowname and folder name.
                            %                             if sum(strcmp(string(rowname_table{1,j}),total_unique)) == 1
                            %                                 if isfolder('tiles/'+class)
                            %                                     if ~exist ('target_rowname','var')
                            %                                         target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class;
                            %                                         target_rowname = target;
                            %                                     else
                            %                                         target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class;
                            %                                         target_rowname = horzcat(target_rowname,target);
                            %                                     end
                            %
                            %                                     destinationFolder = ('tiles/'+class);
                            %                                     outputBaseName = target+'.tif';
                            %                                     fullDestinationFileName = fullfile(destinationFolder, outputBaseName);
                            %
                            %                                     if exist(fullDestinationFileName,'file')
                            %                                         delete(fullDestinationFileName)
                            %                                         imwrite(tile,fullDestinationFileName)
                            %                                     end
                            %                                 end
                            %                             elseif sum(strcmpi(string(rowname_table{1,j}),total_unique)) == 1
                            %                                 class_upper = upper(extractBefore(class,2)) + extractAfter(class,1);
                            %                                 if isfolder('tiles/'+class_upper)
                            %                                     if ~exist ('target_rowname','var')
                            %                                         target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class_upper;
                            %                                         target_rowname = target;
                            %                                     else
                            %                                         target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class_upper;
                            %                                         target_rowname = horzcat(target_rowname,target);
                            %                                     end
                            %
                            %                                     destinationFolder = ('tiles/'+class_upper);
                            %                                     outputBaseName = target+'.tif';
                            %                                     fullDestinationFileName = fullfile(destinationFolder, outputBaseName);
                            %                                     imwrite(tile,fullDestinationFileName)
                            %                                 end
                            %                             else
                            %                                 mkdir('tiles/'+class)
                            %                                 if ~exist ('target_rowname','var')
                            %                                     target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class;
                            %                                     target_rowname = target;
                            %                                 else
                            %                                     target = name+'_'+top_left_X+'_'+top_left_Y+'_'+grid_step_size+'_largeRow_'+r+'_Col_'+c+'+'+class;
                            %                                     target_rowname = horzcat(target_rowname,target);
                            %                                 end
                            %
                            %                                 destinationFolder = ('tiles/'+class);
                            %                                 outputBaseName = target+'.tif';
                            %                                 fullDestinationFileName = fullfile(destinationFolder, outputBaseName);
                            %                                 imwrite(tile,fullDestinationFileName)
                            %                             end
                            %
                            
                            rowname_table = cell2table(rownames{1,it});
                            large_contour_class = rowname_table{1,j};
                            
                            if width(rowname_table)+1 <= j+table_add % To make sure variable index does not exceed table dimensions
                                rowname_table2 = addvars(rowname_table, large_contour_class);
                            else
                                rowname_table2 = addvars(rowname_table,large_contour_class,'After',(j+table_add));
                            end
                            
                            rownames{it,1} = table2cell(rowname_table2);
                            
                            % Calculate texture features.
                            currImg = tile;
                            [w, h, ~] = size(currImg);
                            [rows, columns, ~] = size(example_tile); % siz[subscripgt]e
                            
                            if ~exist ('source_array','var')
                                currImg = imresize(currImg, [150 150]);
                                % compute the feature vector for the current image
                                currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
                                % add current feature vector to the source array
                                source_array(:,firstEl-1+j) = currFeatureVector(:);
                            else
                                if w >= rows & h >= columns
                                    currImg = imresize(currImg, [150 150]);
                                    % compute the feature vector for the current image
                                    currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
                                    % add current feature vector to the source array
                                    source_array = horzcat(source_array, currFeatureVector(:));
                                    
                                else
                                    continue
                                end
                            end
                        else
                            continue
                        end
                    end
                end
                
            else
                
%                 if grid_width_x > 10 || grid_height_y > 10
%                     %% Small Contour
%                     step = 'Processing %d Small Contour of %d for %s';
%                     step_str = sprintf(step, j, total_rowname(it), name);
%                     disp(step_str)
%                     
%                     rowname_cell = rownames{1,it};
%                     for b = 1:length(rowname_cell)
%                         s1 = rowname_cell;
%                         s2 = rowname_cell(b);
%                         tf = strncmpi(s1,s2,2);
%                         indices = find(tf==1);
%                         rowname_cell(indices) = s2;
%                     end
%                     
%                     rowname_table = cell2table(rowname_cell);
%                     tile = use_example(image, grid_min_x, grid_min_y, level, grid_width_x, grid_height_y);
%                     %                     class = string(rowname_table{1,j});
%                     %
%                     %                     % To write tile to image file.
%                     %                     if isfolder('tiles/'+class)
%                     %                         if ~exist ('target_rowname','var')
%                     %                             target = name+'_'+grid_min_x+'_'+grid_min_y+'_'+grid_width_x+'_'+grid_height_y+'+'+class;
%                     %                             target_rowname = target;
%                     %                         else
%                     %                             target = name+'_'+grid_min_x+'_'+grid_min_y+'_'+grid_width_x+'_'+grid_height_y+'+'+class;
%                     %                             target_rowname = horzcat(target_rowname,target);
%                     %                         end
%                     %
%                     %
%                     %                         destinationFolder = ('tiles/'+class);
%                     %                         outputBaseName = target+'.tif';
%                     %                         fullDestinationFileName = fullfile(destinationFolder, outputBaseName);
%                     %                         imwrite(tile,fullDestinationFileName)
%                     %
%                     %                     else
%                     %                         class_upper = upper(extractBefore(class,2)) + extractAfter(class,1);
%                     %                         mkdir('tiles/'+class_upper)
%                     %                         if ~exist ('target_rowname','var')
%                     %                             target = name+'_'+grid_min_x+'_'+grid_min_y+'_'+grid_width_x+'_'+grid_height_y+'+'+class_upper;
%                     %                             target_rowname = target;
%                     %                         else
%                     %                             target = name+'_'+grid_min_x+'_'+grid_min_y+'_'+grid_width_x+'_'+grid_height_y+'+'+class_upper;
%                     %                             target_rowname = horzcat(target_rowname,target);
%                     %                         end
%                     %
%                     %                         destinationFolder = ('tiles/'+class_upper);
%                     %                         outputBaseName = target+'.tif';
%                     %                         fullDestinationFileName = fullfile(destinationFolder, outputBaseName);
%                     %                         imwrite(tile,fullDestinationFileName)
%                     %                     end
%                     
%                     small_x = double(grid_rx);
%                     small_x(isnan(small_x)) = ''; % To remove NaN's
%                     small_x_scale = small_x - grid_min_x; % To scale coordinates to fit contour tile.
%                     small_y = double(grid_ry);
%                     small_y(isnan(small_y)) = ''; % To remove NaN's
%                     small_y_scale = small_y - grid_min_y; % To scale coordinates to fit contour tile
%                     imshow(tile)
%                     hold on
%                     
%                     if length(small_x_scale) == length(small_y_scale)
%                         plot(small_x_scale, small_y_scale) % line
%                         scatter(small_x_scale, small_y_scale) % points
%                         hold off
%                         close all
%                     elseif length(small_x_scale) > length(small_y_scale)
%                         vector_len_diff = length(small_x_scale) - length(small_y_scale);
%                         sxs2 = sort(small_x_scale);
%                         small_x_scale = sxs2(1+vector_len_diff:end);
%                         hold off
%                         close all
%                     elseif length(small_x_scale) < length(small_y_scale)
%                         disp('pause program, at line 448')
%                         pause
%                     end
%                     
%                     
%                     % Calculate texture features.
%                     currImg = tile;
%                     [w, h, ~] = size(currImg);
%                     [rows, columns, ~] = size(example_tile);
%                     %if w >= rows & h >= columns
%                     currImg = imresize(currImg, [150 150]);
%                     % compute the feature vector for the current image
%                     currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
%                     % add current feature vector to the source array
%                     if ~exist ('source_array','var')
%                         source_array(:,firstEl-1+j) = currFeatureVector(:);
%                     else
%                         source_array = horzcat(source_array, currFeatureVector(:));
%                     end
%                     %end
%                     
%                 else
%                     continue
%                 end
            end
        end
        feature=  feature + total_rowname(it);
        it = it+1;
    end
end
%% Step 3: Save results and print status
%load('step3_try1.mat')

simple_rowname = [];%zeros(1:135701);
full_rowname = []; %zeros(1:135701);

% Add columns names to target array
for simple = 1:length(target_rowname)
    simple_name = extractAfter(target_rowname(simple),'+');
    full_name_be4 = extractBefore(target_rowname(simple),'+');
    
    switch simple_name
        case {"Benign breast lession","Benign breast tumor"}
            %simple_rowname(:,end) = []; % Remove last column
            simple_name = 'Benign breast tumor';
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        case {"Haemorrhage", "haemorrhage"}
            simple_name = "Haemorrhage";
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        case {"In-situ", "Insitu lesion"}
            simple_name = "In-situ";
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        case {"Normal breast", "Normal breast tissue"}
            simple_name = "Normal breast tissue";
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        case {"adipose tissue", "Adipose tissue"}
            simple_name = "Adipose tissue";
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        case {"Apocrine metaplasia", "Apocrine change"}
            simple_name = "Apocrine change";
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
        otherwise
            simple_rowname = horzcat(simple_rowname, simple_name);
            full_rowname = horzcat(full_rowname,full_name_be4+'+'+simple_name);
    end
end

simple_unique = unique(simple_rowname);
simple_count_list = [];
for apple = 1:length(simple_unique)
    simple_count = sum(count(simple_rowname,simple_unique(apple)));
    simple_count_list = horzcat(simple_count_list, simple_count);
end



for it = 1:length(simple_unique)
    class_name = simple_unique(it);
    class_files = matches(simple_rowname, class_name);
    placeholder = [];
    for it_class = 1:length(simple_rowname)
        
        if class_files(it_class) == 1
            placeholder = horzcat(placeholder,full_rowname(it_class));
        end
    end
    classes_names{it} = placeholder;
end

unnp=[];
uncases=[];
unp={};
ucases = {};
cases = [];
np = [];
for o = 1:length(classes_names)
    for oo = 1:length(classes_names{1,o})
        
        if strncmpi(classes_names{1,o}(1,oo),'CASE',4) == 1
            case_name = extractBefore(classes_names{1,o}(1,oo),8);
            cases = horzcat(cases,case_name);
        elseif strncmpi(classes_names{1,o}(1,oo),'NP',2) == 1
            np_name = extractBefore(classes_names{1,o}(1,oo),5);
            np=horzcat(np,np_name);
        end
        %         ucases{o}=unique(cases);
        %         unp{o}=unique(np);
    end
    unnp{o}=np;
    uncases{o}=cases;
    ucases{o}=unique(cases);
    unp{o}=unique(np);
    cases=[];
    np=[];
end

infostring = ['This dataset consists of H&E stained tumor tissue blocks',...
    ', feature descriptoclcr: ', currFeat, ', # ', num2str(cnst.numFeatures)];
imageBlockSize = cnst.effectiveImageSize;
% reformat data for machine learning toolbox
target_length = length(source_array); %(source_array_small);
target_height = length(simple_unique);
target_array = uint8(zeros(target_height, target_length)); %pre-allocate

if numel(target_rowname) > (numel(source_array)/80)
    len_dif = numel(target_rowname) - (numel(source_array)/80);
    target_rowname = target_rowname(:,1:end-len_dif);
end

for targets = 1:length(source_array)
    target_column = find(contains(simple_unique,simple_rowname(targets)));
    target_array(target_column,targets) = 1;
end

target_reformatted = target_array;
TisCatsName = simple_unique;

for l=1:size(target_array,1)
    target_reformatted(l,:) = target_array(l,:) * l; end

target_reformatted = sum(target_reformatted);
source_and_target = [source_array; target_reformatted]';

% save dataset for further use
rng('shuffle');
save(['./datasets/PRIMARY/',currFeat,'_numFeatures',num2str(cnst.numFeatures),...
    '_last_output_rand_', num2str(round(rand()*100000)),'.mat'],...
    'source_array','target_array','imageBlockSize','source_and_target',...
    'infostring','TisCatsName');
