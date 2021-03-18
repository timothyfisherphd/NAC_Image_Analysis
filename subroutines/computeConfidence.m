% Author:  Jakob Nikolas Kather 

function [decision, confidence] = computeConfidence( committeeVotes )

    decision = find(committeeVotes==max(committeeVotes));

    others = committeeVotes;
    others(committeeVotes==max(committeeVotes)) = [];
    confidence = max(committeeVotes)/mean(others);
    
end

