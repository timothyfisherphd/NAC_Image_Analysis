
%{
Author: Timothy Fisher


Usage: Create tiles / blocs of images.

Image = imread(xxxxx); %whatever image you are processing 
fun = @(X)  blocks_50_Texture_Saving_Cancer  (X); %store the function (the above one) 

FeaturesSet = blockproc( Image   ,[50 50],fun,'PadMethod','symmetric',...
'TrimBorder',false,'PadPartialBlocks',true,'UseParallel',true ); 

% For the 50x box ,'UseParallel',true  %then you run the bloc proc function while
 calling our function and inputting the image.

Documentation: https://www.mathworks.com/help/images/ref/blockproc.html#d120e7999

%}


% For the 50x box ,'UseParallel',true  %then you run the bloc proc function while
 %calling our function and inputting the image.

function [JustOutput] = SavePCRTile(block_struct)

Location = block_struct.location';  % This allows the function to access the individual tile locations at x,y cordinates
    % This step below was to omit saving anything in case the area was all white (or all background in my case). This type of logic is something you can use to omit areas that are not annotated from being saved
    if median(reshape(block_struct.data(:,:,4),[],1)) == 1
         Name = ['A76_',num2str(Location(1)),'_',num2str(Location(2)),'.tif'];
         FullLocation = ['/Volumes/FREECOM HDD/NAC_Image_Project/all_MATLAB/Partial/testing/',Name];
         imwrite(block_struct.data(:,:,1:3),FullLocation);
    else
%         % Below is simply image normalization. I do not know if you need this
%         imgNormalized2 = colornormalization(block_struct.data);   
% 
%         % Naming the file based on the location and manual inputs 
%         Name = ['',num2str(CancerVal),'_',num2str(i),'_',num2str(j),'_',num2str(Location(1)),'_',num2str(Location(2)),'_.tif']; 
%         imwrite(imgNormalized2,Name);% Saving the file (tiles)
%         JustOutput = 1;% Dummy variable
    end
    JustOutput =0;
end