% Author:  Jakob Nikolas Kather


function [trainedClassifier, validationAccuracy, ConfMat, ROCraw] = ...
    trainMyClassifier(DataIn,classNames,NcrossVal,classifMethod)

switch lower(classifMethod)
    % --------------- NEURAL
    case 'neural'
        % NOTE: the dataset could also be classified by a neural network. When
        % using the MATLAB GUI nprtool, a well-performing neural network can be
        % easily trained and classification accuracy is very high (comparable
        % to SVM). However, this has not yet been implemented here.
        
        [trainedClassifier, validationAccuracy,ConfMat, ROCraw] = ...
            trainMyNetwork(DataIn,NcrossVal);
        
    otherwise
        % --------------- OTHER THAN NEURAL
        numFeat = size(DataIn,2) - 1; numResp = 1; % no. of features and response
        
        % Convert input to table
        DataIn = table(DataIn); DataIn.Properties.VariableNames = {'column'};
        
        % prepare column names
        nameMat = 'column_1#';
        for i=2:(numFeat+numResp)
            nameMat = [nameMat,['#column_',num2str(i)]];
        end
        
        colnames = strsplit(nameMat,'#');
        
        % Split matrices in the input table into vectors
        DataIn = [DataIn(:,setdiff(DataIn.Properties.VariableNames, ...
            {'column'})), array2table(table2array(DataIn(:,{'column'})), ...
            'VariableNames', colnames)];
        
        % Extract predictors and response, convert to arrays
        predictorNames = colnames(1:(end-1));    responseName = colnames(end);
        predictr = DataIn(:,predictorNames);   response = DataIn(:,responseName);
        predictr = table2array(varfun(@double, predictr));
        response = table2array(varfun(@double, response));
        
        disp('start training...');
        switch lower(classifMethod)
            
            % --------------- support vector machine (SVM)
            % https://www.mathworks.com/help/stats/fitcecoc.html
            case {'rbfsvm','linsvm'}
                switch lower(classifMethod)
                    case 'rbfsvm' % radial basis function SVM
                        template = templateSVM('KernelFunction', 'rbf', 'PolynomialOrder', ...
                            [], 'KernelScale', 'auto', 'BoxConstraint', 1, 'Standardize', 1);
                    case 'linsvm' % linear SVM
                        template = templateSVM('KernelFunction', 'linear', 'PolynomialOrder', ...
                            [], 'KernelScale', 'auto', 'BoxConstraint', 1, 'Standardize', 1);
                end % end svm subtypes, start svm common part
                options = statset('UseParallel', true);
                trainedClassifier = fitcecoc(predictr, response, ...
                    'Learners', template, 'Coding', 'onevsone',...
                    'PredictorNames', predictorNames, 'ResponseName', ...
                    char(responseName), 'ClassNames', classNames, 'Options', options);
                
                % Cross-validate using 10-fold cross validation
                CVMdl = crossval(trainedClassifier, 'Options', options);
                genError = kfoldLoss(CVMdl);
                
                close all; figure
                oofLabel = kfoldPredict(CVMdl,'Options',options);
                ConfMat = confusionchart(response,oofLabel,'RowSummary','total-normalized');
                ConfMat.InnerPosition = [0.10 0.12 0.85 0.85];
                % --------------- ensemble of decision trees
            case 'ensembletree'
                template = templateTree(...
                    'MaxNumSplits', 20);
                trainedClassifier = fitensemble(...
                    predictr, ...
                    response, ...
                    'RUSBoost', ...
                    30, ...
                    template, ...
                    'Type', 'Classification', ...
                    'LearnRate', 0.1, ...
                    'ClassNames', classNames);
                % --------------- 1-nearest neighbor (1-NN)
            case '1nn' % SInce there are 16 classes testing K as 16.
                trainedClassifier = fitcknn(predictr, response, 'PredictorNames',...
                    predictorNames, 'ResponseName', char(responseName), 'ClassNames', ...
                    classNames, 'Distance', 'Euclidean', 'Exponent', '',...
                    'NumNeighbors', 16, 'DistanceWeight', 'Equal', 'StandardizeData', 1);
        end % end svm or not svm
        
        % ------ all non-neural methods continuing here
        % Perform cross-validation = re-train and test the classifier K times
        disp('start cross validation...');
        partitionedModel = crossval(trainedClassifier, 'KFold', NcrossVal);
        disp('properties of partitioned set for cross validation'); partitionedModel.Partition
        % Compute validation accuracy on partitioned model
        disp('start validation...');
        validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');
        % Compute validation predictions and scores
        disp('computing validation predictions and scores...');
        [validationPredictions, validationScores] = kfoldPredict(partitionedModel);
        ConfMat = confusionmat(response,validationPredictions);
        %ConfMat = plotconfusion(response,validationPredictions);
        ConfMat2 = confusionchart(response,validationPredictions);
        % Prepare data for ROC curves (reformat arrays)
        trues = zeros(numel(unique(response)),size(response,1));
        for i = 1:numel(unique(response)), trues(i,response==i) = 1; end
        ROCraw.true = trues; ROCraw.predicted = validationScores;
        
end % end neural or not neural
end % end function