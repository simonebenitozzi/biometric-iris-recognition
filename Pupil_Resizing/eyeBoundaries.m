function [rowsBoundaries, columnsBoundaries, intersectionX1, intersectionX2, intersectionY1, intersectionY2] = eyeBoundaries(irisMask, pupilMask)

%% Boundaries

[height, width] = size(irisMask);

rowsBoundaries = zeros(height, 4);
columnsBoundaries = zeros(4, width);

%% rows Boundaries + Y intersections
for k = 1 : height
    
    if any( irisMask(k, :) == 1 )
       rowsBoundaries(k, 1) = find(irisMask(k, :), 1, 'first'); 
       rowsBoundaries(k, 4) = find(irisMask(k, :), 1, 'last');
    end
    
    if any( pupilMask(k, :) == 1 )
        rowsBoundaries(k, 2) = find(pupilMask(k, :), 1, 'first');
        rowsBoundaries(k, 3) = find(pupilMask(k, :), 1, 'last');
    end
    
    if any( irisMask(k, :) == 1 ) && ~any( pupilMask(k, :) == 1 ) && k < height && any( pupilMask(k+1, :) == 1 )
        intersectionY1 = k;
    elseif any( irisMask(k, :) == 1 ) && any( pupilMask(k, :) == 1 ) && k < height && ~any( pupilMask(k+1, :) == 1 )
        intersectionY2 = k;
    end
    
end

%% columns Boundaries + X intersections
for k = 1 : width
    
    if any( irisMask(:, k) == 1 )
        columnsBoundaries(1, k) = find(irisMask(:, k), 1, 'first');
        columnsBoundaries(4, k) = find(irisMask(:, k), 1, 'last');
    end
    
    if any( pupilMask(:, k) == 1 )
        columnsBoundaries(2, k) = find(pupilMask(:, k), 1, 'first');
        columnsBoundaries(3, k) = find(pupilMask(:, k), 1, 'last');
    end
    
    if any( irisMask(:, k) == 1 ) && ~any( pupilMask(:, k) == 1 ) && k < width && any( pupilMask(:, k+1) == 1 )
        intersectionX1 = k;
    elseif any( irisMask(:, k) == 1 ) && any( pupilMask(:, k) == 1 ) && k < width && ~any( pupilMask(:, k+1) == 1 )
        intersectionX2 = k;
    end
    
end

return

end