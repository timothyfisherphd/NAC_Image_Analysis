function tile = use_example(image, min_x , min_y, level, contour_width, contour_height)% ,full_name, rownames, contour) %image, x_coor , y_coor, ~, full_name, rownames,contour_width,contour_height, contour)

% Path to the python executable
%py_path = '/home/user/python/env/bin/python';
%pe = pyenv('Version', py_path);
%imf = '/path/to/slide/sample.ndpi';
py_img = py.read_slide.read_img(image, [ min_x , min_y], level, [contour_width, contour_height]);
mat_img = nparray2mat(py_img);
% imshow(mat_img/255);
tile = mat_img/255;

% imwrite(contour_ROI,'tiles/'+full_name.extractBefore('_L1')+'/'+char(table2cell(rownames(contour,1)))+'_'+contour_width+'_'+contour_height+'.tif');
end
%return



