% Author:  Jakob Nikolas Kather 

function gaborMeans_red = reduceGabor(gaborMeans,numOffsets)
    gaborMeans_red = zeros(1,numOffsets);
    % reduce gaborMeans to make it invariant wrt rotation
    numDirections = numel(gaborMeans)/numOffsets;
    
    for i = 1:numOffsets
        idx = linspace(1,numel(gaborMeans)-numOffsets+1,numDirections)+i-1;
        gaborMeans_red(i) = (mean(gaborMeans(idx)));
    end
    
end