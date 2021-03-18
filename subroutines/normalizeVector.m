% Author:  Jakob Nikolas Kather 

function vec = normalizeVector(vec)
    vec = (vec - min(vec));
    vec = vec / max(vec);
end

