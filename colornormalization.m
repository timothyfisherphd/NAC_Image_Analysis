function img = colornormalization(img_in)

meanStdTarget=[77.5121  270.5718; 8.9287 -23.6535; 2.9664 8.3857];


%%%%%%%%%%%%%%%%%
binry = rgb2gray(img_in);
binry((binry>=215)) = 0;
binry((binry~=0)) = 1;
binry = ~binry;
%%%%%%%%%%%%%%%%%%

% img=colorCorrect(ori,meanStdTarget,-1);       %this is what is normally is
img=colorCorrect(img_in,meanStdTarget,binry);

img=uint8(img*double(intmax('uint8')));

end


function img=colorCorrect(imgO,meanStdTarget,whiteMask)

if isequal(class(imgO),'uint8')
    imgO=double(imgO)/double(intmax('uint8'));
end

lStd=meanStdTarget(1,1);lMT=meanStdTarget(1,2);   %1st line is for L (STD,MEAN)
aStd=meanStdTarget(2,1);aMT=meanStdTarget(2,2);   %2nd line is for A (STD,mean)
bStd=meanStdTarget(3,1);bMT=meanStdTarget(3,2);

% imgR=imgO(:,:,1);
% imgG=imgO(:,:,2);
% imgB=imgO(:,:,3);

if whiteMask ~=-1
    nwMask =~ whiteMask;
else
    nwMask=true(size(imgO,1),size(imgO,2));
end

indexWhitePixel=nwMask==false;

labO=convertRGBToLAB(imgO);

labO_l=labO(:,:,1);
labO_a=labO(:,:,2);
labO_b=labO(:,:,3);

if any(indexWhitePixel(:))
    labO_l=labO_l(nwMask);
    labO_a=labO_a(nwMask);
    labO_b=labO_b(nwMask);
end

lsbO=std(labO_l(:));lMO=mean(labO_l(:));
asbO=std(labO_a(:));aMO=mean(labO_a(:));
bsbO=std(labO_b(:));bMO=mean(labO_b(:));

labO(:,:,1)=((labO(:,:,1)-lMO)/lsbO)*lStd+lMT;
labO(:,:,2)=((labO(:,:,2)-aMO)/asbO)*aStd+aMT;
labO(:,:,3)=((labO(:,:,3)-bMO)/bsbO)*bStd+bMT;

% RGB=applycform(labO,makecform('lab2srgb'));
RGB=convertLABToRGB(labO);

RGB_r=RGB(:,:,1);
RGB_g=RGB(:,:,2);
RGB_b=RGB(:,:,3);

imgR=imgO(:,:,1);
imgG=imgO(:,:,2);
imgB=imgO(:,:,3);
imgR(nwMask)=RGB_r(nwMask);
imgG(nwMask)=RGB_g(nwMask);
imgB(nwMask)=RGB_b(nwMask);

img(:,:,1)=imgR;
img(:,:,2)=imgG;
img(:,:,3)=imgB;


end

function imgLAB=convertRGBToLAB(imgT)


imgR=imgT(:,:,1);
imgG=imgT(:,:,2);
imgB=imgT(:,:,3);

channelVectors=[imgR(:)';imgG(:)';imgB(:)'];

rgbToLMS=[0.3811 0.5783 0.0404; 0.1967 0.7244 0.0782; 0.0241  0.1288  0.8444];
LMS=rgbToLMS * channelVectors;

lmsToLab1=[1/sqrt(3) 0 0; 0 1/sqrt(6) 0; 0 0 1/sqrt(2)];
lmsToLab2=[1 1 1;1 1 -2; 1 -1 0];

LAB=lmsToLab1 * lmsToLab2 *LMS;

imgLAB(:,:,1)=reshape(LAB(1,:),[size(imgT,1) size(imgT,2)]);
imgLAB(:,:,2)=reshape(LAB(2,:),[size(imgT,1) size(imgT,2)]);
imgLAB(:,:,3)=reshape(LAB(3,:),[size(imgT,1) size(imgT,2)]);
    
end

function imgRGB=convertLABToRGB(imgLAB)

labToLMS1=[1 1 1;1 1 -1;1 -2 0];
labToLMS2=[1/sqrt(3) 0 0; 0 1/sqrt(6) 0; 0 0 1/sqrt(2)];

imgL=imgLAB(:,:,1);
imgA=imgLAB(:,:,2);
imgB=imgLAB(:,:,3);

LAB=[imgL(:)';imgA(:)';imgB(:)'];

LMS=labToLMS1*labToLMS2*LAB;

lmsToRGB=[4.4679 -3.5873  0.1193; -1.2186  2.3809 -0.1624; 0.0497 -0.2439  1.2045];

RGB=lmsToRGB * LMS;


imgRGB(:,:,1)=reshape(RGB(1,:),[size(imgLAB,1) size(imgLAB,2)]);
imgRGB(:,:,2)=reshape(RGB(2,:),[size(imgLAB,1) size(imgLAB,2)]);
imgRGB(:,:,3)=reshape(RGB(3,:),[size(imgLAB,1) size(imgLAB,2)]);

imgRGB=imgRGB/double(intmax('uint8'));
end