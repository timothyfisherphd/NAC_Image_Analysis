%{

Author: Timothy Fisher
Resource: https://www.mathworks.com/help/deeplearning/examples/train-deep-learning-network-to-classify-new-images.html
Info: Basic CNN on a pretrained model such as AlexNet, VGG16, VGG19,
GoogleNet
Date Last Modified: 15 December 2019

%}

%% Pre-proccess Data and Load Network. 
% Reading Images into MATLAB.
imds = imageDatastore('G:\Training\tiles\',...
    'IncludeSubfolders',true,...
    'FileExtensions','.tif',...
    % Source control practice. I will add this
    'LabelSource','foldernames');
[imdsTrain,imdsValidation] = splitEachLabel(imds,0.7);

% Load Pretrained Network
net = googlenet;

% Visualize the network architechture
analyzeNetwork(net);

% Store the input size of the image. 
inputSize = net.Layers(1).InputSize;

%% Replace Final Layers %%
% SeriesNetworks must extract the graph layer.
if isa(net,'SeriesNetwork') 
  lgraph = layerGraph(net.Layers); 
else
  lgraph = layerGraph(net);
end 

% Find Layer Names
openExample('nnet/TransferLearningUsingGoogLeNetExample')
[learnableLayer,classLayer] = findLayersToReplace(lgraph);
[learnableLayer,classLayer] 


% Connect each layer to its respective weights.
numClasses = numel(categories(imdsTrain.Labels));

if isa(learnableLayer,'nnet.cnn.layer.FullyConnectedLayer')
    newLearnableLayer = fullyConnectedLayer(numClasses, ...
        'Name','new_fc', ...
        'WeightLearnRateFactor',10, ...
        'BiasLearnRateFactor',10);
    
elseif isa(learnableLayer,'nnet.cnn.layer.Convolution2DLayer')
    newLearnableLayer = convolution2dLayer(1,numClasses, ...
        'Name','new_conv', ...
        'WeightLearnRateFactor',10, ...
        'BiasLearnRateFactor',10);
end

lgraph = replaceLayer(lgraph,learnableLayer.Name,newLearnableLayer);


% Storing the class
newClassLayer = classificationLayer('Name','new_classoutput');
lgraph = replaceLayer(lgraph,classLayer.Name,newClassLayer);

% Check
figure('Units','normalized','Position',[0.3 0.3 0.4 0.4]);
plot(lgraph)
ylim([0,10])


%% Freeze Inital Layers %%
% Must move freezeWeights.m and  createLgraphUsingConnections to current
% working directory. 

% Extract the layers and connections of the layer graph and select which
% layers to freeze.
layers = lgraph.Layers;
connections = lgraph.Connections;

layers(1:10) = freezeWeights(layers(1:10));
lgraph = createLgraphUsingConnections(layers,connections);

%% Train Network %% 

pixelRange = [-30 30];
scaleRange = [0.9 1.1];
imageAugmenter = imageDataAugmenter( ...
    'RandXReflection',true, ...
    'RandXTranslation',pixelRange, ...
    'RandYTranslation',pixelRange, ...
    'RandXScale',scaleRange, ...
    'RandYScale',scaleRange);
augimdsTrain = augmentedImageDatastore(inputSize(1:2),imdsTrain, ...
    'DataAugmentation',imageAugmenter);

% To automatically resize the image without  further data augmentation. 
augimdsValidation = augmentedImageDatastore(inputSize(1:2),imdsValidation);

% Specify the training options. 
miniBatchSize = 10;
valFrequency = floor(numel(augimdsTrain.Files)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',6, ...
    'InitialLearnRate',3e-4, ...
    'Shuffle','every-epoch', ...
    'ValidationData',augimdsValidation, ...
    'ValidationFrequency',valFrequency, ...
    'Verbose',false, ...
    'Plots','training-progress');

% To train the network.
net = trainNetwork(augimdsTrain,lgraph,options);





