%{
 
Author: Timothy Fisher

Source: Jakob Nikola, Andrew Janowczyk, Sergey Klimov, Mathworks

Description: This script reads all texture images and computes a feature vector for each one of them.

Input: QuPath Tiles of Annotated Area (Maximum Size is 1000 x 1000 tiles) 

Output: Texture Features (all6 = 80 features)

Usage: Write in more details.
    load('features.mat')


%}
%% Step 0: Clean workspace and establish parmeters. 
format compact; clear all; close all; %clc; % clean up session
rng('default'); % reset random number generator for reproducibility

addpath([pwd,'/subroutines'],'-end'); % my own functions, see license
addpath([pwd,'/lbp'],'-end'); % code for LBP, see license in subfolder
addpath([pwd,'/perceptual'],'-end'); % code for perceptual features, see license in subfolder


% define some constants (paths, filenames and the like)
allImages = imageDatastore('/media/tfisher1995/TIM_FILES/Research/code/old/case_10','IncludeSubfolders', true, 'LabelSource', 'foldernames');
[training_set, validation_set, testing_set] = splitEachLabel(allImages,.7,.15,.15);
cnst.inputDir = char(training_set.Folders);
% ONE FOLDER PER TISSUE CATEGORY with multiple small images per folder, 
% e.g. 625 images with 150 * 150 px each. Path must end with /
cnst.effectiveImageSize = 150*150; % default 150*150
cnst.noOverheat =  true; % pause program after each iteration to prevent overheat, default true
cnst.limitedMode = false; % use only the first N images per class, default false
    cnst.limit = 625;      % if limitedMode==true, how many images?, default 625
cnst.featureType = {'all6'}; %'best2','best3','best4','best5','all6'}; % one or more of {'histogram_lower','histogram_higher','gabor','perceptual','f-lbp','glcmRotInv','best2','best3'};  
cnst.gaborArray = gabor(2:2:12,0:30:150); % create gabor filter bank, requires Matlab R2015b

for currFeat = cnst.featureType % iterate through feature types
   currFeat = char(currFeat);         % convert name of feature set to char
   cnst.numFeatures = getNumFeat(currFeat); % request number of features

    % Read source images of all classes, creates one class per folder
    TisCats = dir(cnst.inputDir);               % read input folder contents
    TisCats = TisCats([TisCats.isdir] & ~strncmpi('.', {TisCats.name}, 1));
    TisCatsName = cellstr(char(TisCats.name))'; % create catory name array | Add the labels from the folder name
    TisCatImgCount = zeros(size(TisCats,1),1);  % preallocate summary array | 

    for i = 1:size(TisCats,1) % iterate through each Tissue category (TisCat)
        CurrFiles = dir([char(cnst.inputDir),'/',char(TisCatsName(i)),'/']); %training_set.Files(i) % read file names
        % remove folders and dot files  
        CurrFiles = CurrFiles(~[CurrFiles.isdir] & ~strncmpi('.', {CurrFiles.name}, 1));
        % optional: crop currFiles vector to fewer elements per class
        if cnst.limitedMode && size(CurrFiles,1)>cnst.limit, CurrFiles = CurrFiles(1:cnst.limit); end
        % show status
        disp([num2str(size(CurrFiles,1)), ' items in class ',TisCats(i).name]);
        TisCatImgCount(i) = size(CurrFiles,1); % add file count to summary array
    end
    
    
disp(['-> in total: ', num2str(sum(TisCatImgCount)), ' files.']); % show status

%% Step 1: Load all images and compute features
source_array = double(zeros(cnst.numFeatures,sum(TisCatImgCount))); % preallocate
target_array = uint8(zeros(size(TisCats,1),sum(TisCatImgCount)));   % preallocate

    for i = 1:size(TisCats,1) % iterate through Tissue categories (TisCats)
        tImage = tic;  % start timer
        CurrFiles = dir([cnst.inputDir,'/',TisCats(i).name,'/']); % read file names
        % remove folders and dot files
        CurrFiles = CurrFiles(~[CurrFiles.isdir] & ~strncmpi('.', {CurrFiles.name}, 1));
        % optional: crop currFiles vector to fewer elements per class
        if cnst.limitedMode && size(CurrFiles,1)>cnst.limit, CurrFiles = CurrFiles(1:cnst.limit); end
        % set up an index of first element of current class
        if i>1, firstEl = sum(TisCatImgCount(1:i-1))+1; else firstEl = 1; end

        tB = tic; tT = tic;
        example_tile = imread('/media/tfisher1995/TIM_FILES/Research/code/old/linux/matlab/full_slide_classifier/Kather_texture_2016_image_tiles_5000/01_TUMOR/1A11_CRC-Prim-HE-07_022.tif_Row_601_Col_151.tif');
        % load each image, compute feature vector and add this vector to array
            for j = 1:size(CurrFiles,1)
               currImg = imread([cnst.inputDir,'/',TisCats(i).name,'/',CurrFiles(j).name]); % read image file
               
               [w, h, ~] = size(currImg);
               [rows, columns, ~] = size(example_tile);
               if w >= rows & h >= columns
                   currImg = imresize(currImg, [150 150]);
                   % compute the feature vector for the current image
                   currFeatureVector = computeFeatureVector(currImg, currFeat, cnst.gaborArray);
                   % add current feature vector to the source array
                   source_array(:,firstEl-1+j) = currFeatureVector(:); 
                   % show status of computation for every 25th element
                   if ~mod(j,25), disp(['current class: completed ', num2str(j), ' of ', ...
                       num2str(size(CurrFiles,1)), ' t= ',num2str(toc(tB))]); tB=tic; end
               else
                   %CurrFiles(j) = [];
                   continue
               end
            end
        timeBlock(i) = toc(tT)/size(CurrFiles,1);
        disp(['time per image in this class: ', num2str(timeBlock(i)),' seconds']);

        % add target variable (tissue category ID) to target array
        target_array(i,firstEl:(firstEl+TisCatImgCount(i)-1)) = 1;
        disp(['Successfully added data from ', TisCats(i).name,' to array.']);

    %     % optional: avoid MacBook overheating by pausing the program
    %     if cnst.noOverheat && (i<size(TisCats,1)), waitFor(toc(tImage),60); end
    end

disp('times per image per block:'); timeBlock 


%% Step 2: Save results and print status

% prepare data description
infostring = ['This dataset consists of H&E stained tumor tissue blocks',...
   ', feature descriptor: ', currFeat, ', # ', num2str(cnst.numFeatures),...
   ', mean time per image: ', num2str(mean(timeBlock))];
imageBlockSize = cnst.effectiveImageSize;

% reformat data for machine learning toolbox
target_reformatted = target_array;

    for l=1:size(target_array,1), 
        target_reformatted(l,:) = target_array(l,:) * l; end

target_reformatted = sum(target_reformatted);
source_and_target = [source_array; target_reformatted]';

% save dataset for further use
rng('shuffle');
save(['./datasets/',currFeat,'_numFeatures',num2str(cnst.numFeatures),...
    '_last_output_rand_', num2str(round(rand()*100000)),'.mat'],...
    'source_array','target_array','imageBlockSize','source_and_target',...
    'infostring','TisCatsName');

end

save('features.mat') 

% play notification sound 
sound(sin(1:0.3:800)); disp('done all.');
