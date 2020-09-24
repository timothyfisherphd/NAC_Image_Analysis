README.txt

Author: Timothy FIsher
PI: Dr. Jun Kong and Dr. Ritu Aneja
Mentor: Dr. Hongxiao Li and Dr. Sergey Klimov
Collaborators: Dr. Jayashree Krishnamurthy and Dr. Rekha TS

Description: 
Please use the full slide annotator using QuPath tiles or main00_create_tiles.m. For simplicity, I used QuPath tiles from the 'examples/' directory. 
Also, QuPath tiles come with QuPath Generate Features, QuPath Random Forest Classifier. In the pipeline I used other machine learning algorthims to test the best classifer. 

Instructions:
- To load the workspace data for main01 and main02, use features.mat and class.mat (Respectively).
- To see output of main02, please check the 'output/' directory. Each directory contains the classifer (.mat), ROC (.png), Confusion Matrix (.png)
- Comparison of main00 tiles and QuPath tiles can be seen in 'examples/'

Work in Progress:
- Updating main00 to include the coordinates from QuPath Annotations. QuPath Annotations were not used initally to produce results quicker. It is worth checking the annotations mapped to ROI on blocproc tiles. 
- Update the features and performance classifier. 
- Create an pCR vs non-pCR classifier



Additional comments: 
- This is a big data project, therefore has big data issues that I am still resolving the issues include: 
	1. Data Management: Uploading data to Google Drive has been effective however my storage space is limited an is mostly full. 
	2. Computational Time Intensive. 
	3. Still updating the code to improve the results to 90% or greater. Currently at approxiamtely 88% using rbf SVM classifier with QuPath Tiles
	4. Issues stiching together all tiles to one slide image. Code works fine on a single image but unable to implement looping through each tile (referring to scripts tiles2WSI.m and main00 3 in step 3)
	
