%{
Code Still in Development
%}

%% Step 0: Clean up session and add paths
warning('off','all') % To turn off all warnings.

addpath([pwd,'/subroutines/'],'-end');
addpath([pwd,'/lbp/'],'-end');
addpath([pwd,'/perceptual/'],'-end');

% Step 1: Define some constants (paths, filenames and the like)
cnst.effectiveImageSize = 1000*1000; % default 150*150
cnst.noOverheat =  true; % pause program after each iteration to prevent overheat, default true
cnst.limitedMode = false; % use only the first N images per class, default false
cnst.limit = 625; % if limitedMode==true, how many images?, default 625
cnst.featureType = {'all6'}; %'best2','best3','best4','best5','all6'}; % one or more of {'histogram_lower','histogram_higher','gabor','perceptual','f-lbp','glcmRotInv','best2','best3'};
cnst.gaborArray = gabor(2:2:12,0:30:150); % create gabor filter bank

%Total Contour Calculation
total_contours_folder = ([pwd,'/all_annotation']);
total_contours = dir(fullfile(total_contours_folder, '*.*'));
total_contours = total_contours(~[total_contours.isdir] & ~strncmpi('.', {total_contours.name}, 1));

% % Call pyenv outside loop.
% if isunix
%     py_path = '/home/tfisher1995/opEnv/bin/python';
% elseif ispc
%     py_path =  'C:\opEnv\Scripts\python.exe';
% else
%     disp('Platform not supported, please us a Linux or PC computer')
% end
% pe = pyenv('Version', py_path);

% Create variables
level = 0; % Level for openslide highest resolution
level2 = 6; % Level for downsamples openslide
grid_step_size = 500; % Bigger tile size for less processing time.

% Point to reference tile for color normalization.
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
    
    feature = 1;
    it = 1;
    %% Step 1: Create File List
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
            
            % Must put full path
            if isunix
                path = '/media/tfisher1995/GSU_RESEARCH/Research/wsi/Dekalb_Shristi_HE';
                %elseif ispc
            else
                disp('Please use a linux machine and connect GSU_Research hard drive.')
            end
            
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
            
            % Delaunay Triangulation
            x = x_coor; 
            y = y_coor; 
            dt = delaunayTriangulation(x,y);
            
            triplot(dt);
            %
            % Display the Vertex and Triangle labels on the plot
            hold on
            vxlabels = arrayfun(@(n) {sprintf('P%d', n)}, (1:10)');
            Hpl = text(x, y, vxlabels, 'FontWeight', 'bold', 'HorizontalAlignment',...
                'center', 'BackgroundColor', 'none');
            ic = incenter(dt);
            numtri = size(dt,1);
            trilabels = arrayfun(@(x) {sprintf('T%d', x)}, (1:numtri)');
            Htl = text(ic(:,1), ic(:,2), trilabels, 'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center', 'Color', 'blue');
            hold off
            
            
        end
        feature=  feature + total_rowname(it);
        it = it+1;
    end
end
