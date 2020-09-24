
% Deep Learning:

% define the image name
% imName = '/media/tfisher1995/TIM_FILES/Research/wsi/Dekalb_Shristi0/NP9_L1_BATCH_3_2019_11_27_14.20.36.ndpi';
% imInfo = imfinfo(imread(imName,2)); % get the metadata

imName = '../../wsi/Dekalb_Shristi/CASE_10_L1_2019_11_14_17.23.37.ndpi';
imInfo = imfinfo(imName); % get the metadata
%imInfo = imfinfo('../../wsi/Dekalb_Shristi/CASE_10_L1_2019_11_14_17.23.37.ndpi')
% NDPI images are essentially multipage TIFFs and we can use imfinfo() to look at the metadata of each page.
for i = 1:numel(imInfo)
    X = ['Layer ', num2str(i), ': Width ',num2str(imInfo(i).Width), ...
     ' and Height ', num2str(imInfo(i).Height)];
    disp(X)
end


% Read in base image
%imshow(imread(imName,1)) % TO big, unable to read first page. % Call it level 0 
imshow(imread(imName,3))

% Display each chaneel metadata. 
disp(['this image has ',num2str(imInfo(3).Width),'*',num2str(imInfo(3).Height),' pixels'])


% Trasnsfer learning with AlexNet
net = alexnet; % load an alexnet which is pretrained on ImageNet

% Load QuPath TIle Images
allImages = imageDatastore('/media/tfisher1995/TIM_FILES/Research/code/old/matlab_tile','IncludeSubfolders',true,'LabelSource','foldernames');
[training_set, validation_set, testing_set] = splitEachLabel(allImages,.7,.15,.15);



% Network Modification
layersTransfer = net.Layers(1:end-3);

%Display Output categories
categories(training_set.Labels)
numClasses = numel(categories(training_set.Labels));

% Merge Layers
layers = [
    layersTransfer
    fullyConnectedLayer(numClasses,'Name', 'fc','WeightLearnRateFactor',1,'BiasLearnRateFactor',1)
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'classOutput')];

% Setup laygraph and plot it
lgraph = layerGraph(layers);
plot(lgraph)

%% Modify Training Parameters
imageInputSize = [227 227 3];
augmented_training_set = augmentedImageSource(imageInputSize,training_set);

resized_validation_set = augmentedImageDatastore(imageInputSize,validation_set);
resized_testing_set = augmentedImageDatastore(imageInputSize,testing_set);

% Set training options
opts = trainingOptions('sgdm', ...
    'MiniBatchSize', 64,... % mini batch size, limited by GPU RAM, default 100 on Titan, 500 on P6000
    'InitialLearnRate', 1e-5,... % fixed learning rate
    'L2Regularization', 1e-4,... % optimization L2 constraint
    'MaxEpochs',15,... % max. epochs for training, default 3
    'ExecutionEnvironment', 'gpu',...% environment for training and classification, use a compatible GPU
    'ValidationData', resized_validation_set,...
    'Plots', 'training-progress')

% Training
net = trainNetwork(augmented_training_set, lgraph, opts);

% Testing and Prediction
[predLabels,predScores] = classify(net, resized_testing_set, 'ExecutionEnvironment','gpu');

% COnfusion Matrix and CLassification Accuracy
plotconfusion(testing_set.Labels, predLabels)
PerItemAccuracy = mean(predLabels == testing_set.Labels);
title(['overall per image accuracy ',num2str(round(100*PerItemAccuracy)),'%'])

save("deep_learning.mat")

