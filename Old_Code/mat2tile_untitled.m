hm =240;
wm =240;

ajTiles=mat2tiles(imread('img1_15_59_56.tif' ), [hm,wm]);
for k=1:25
    subplot(5,5,k); imshow(ajTiles{k});
end

imshow([ajTiles{1,1},ajTiles{1,2},ajTiles{1,3}])
if