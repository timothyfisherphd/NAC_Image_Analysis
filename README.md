# NAC_Image_Analysis
- Author: Timothy Fisher
- PI: Dr. Jun Kong and Dr. Ritu Aneja
- Mentor: Dr. Hogxiao Li and Dr. Sergey Klimov
- Pathologist Collaborators: Dr. Jayashree Krishnamurthy and Dr. Rekha TS

## Introduction
This repository contains MATLAB source code for the project: "Predicting Neoadjuvant Chemotherapy Response in Triple Negative Breast Cancer (TNBC) using Machine Learning". Using this code, you can train a classifier with sample images of histological textures and apply this classifier to other histological images. A trained classifier is already included and can be applied to H&E images of triple negative breast cancer (40x magnification).  This method is capable of classifying more than mutiple tissue categories. In our paper, we investigated the classification of sixteen tissue categories. The second classifier you can train a histological heatmap based on the predict values of each tile to train a classifer with spatial calculations. A trained classifer will be able to classify whole slide images to predict neoadjuvant chemotherapy response in TNBC. 


The general workflow is as follows:

<img src="https://github.com/timothyfisherphd/NAC_Image_Analysis/blob/master/supporting_files/Small_NAC_Pipeline.png" align="center">

### Part 1: Tile-Level Classifer (A-F)
1. Use *'main_01_texture_features.m'* to create a feature vector for a given set of training images. Then, manually change *'subroutines/load_testure_feature_dataset.m'* and specify the filename of the feature vector for further use.
2. Use *'main_02_trainClassifier.m'* to train a classifier. Then, manually change 'classifierFolder' and 'classifierName' in *'main_deploy_classifier_fractal.m'* to specify which classifier should be used.
3. Use *'main_03_deploy_classifier.m'* to apply this classifier to unknown images. These images are typically located in *'./test_cases'*.
### Part 2: Patient-Level Classifier (G-K) - Code still in development
4. Use *'main_04_spatial_features.m'* to apply this classifier to a classification map with predict values.  Then, manually change *'subroutines/load_spatial_feature_dataset.m'* and specify the filename of the feature vector for further use.
5. Use *'main_05_trainClassifier.m'* to train a classifier for neoadjuvant chemotherapy response.
6. *'main_06_deploy_classifier.m'* to apply this classifier to unknown images. 


## License / Acknowledgements

The MIT license (available in the file "LICENSE") applies to all source codes within this repository. We want to thank Francesco Bianconi for providing (and permitting redistribution) of all source codes in the subfolder “perceptual”. Furthermore, we want to thank Matti Pietikäinen for providing (and permitting redistribution) of all source codes in the subfolder “lpb” (originally available from: http://www.cse.oulu.fi/CMV/Downloads/LBPMatlab).

## Contact
For questions, please contact: Timothy B. Fisher (tfisher10@student.gsu.edu)
