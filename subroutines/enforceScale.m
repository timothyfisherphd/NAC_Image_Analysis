% Author:  Jakob Nikolas Kather 

function source_and_target = enforceScale(source_and_target)
    for i=1:(size(source_and_target,2)-1)
            source_and_target(:,i) = (source_and_target(:,i) ...
                - mean(source_and_target(:,i))) ...
                /  std(source_and_target(:,i));
        end, disp([10,'forced parameter scaling!',10]);
end