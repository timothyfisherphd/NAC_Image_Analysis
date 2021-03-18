%Author: Jakob Nikolas Kather 


function waitFor(elapsedTime,maxTime)
      if elapsedTime>maxTime, elapsedTime = maxTime; end % max. pause = maxTime sec
      warning(['Pausing for ', num2str(elapsedTime), ' seconds...']);
      pause(elapsedTime); disp('continuing...'); 
end