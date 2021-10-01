%% Coordinates and radius for a circle
function [xCenter, yCenter, radius] = circleDimensions(circle, size)

[x,y] = circlecoords([circle(2),circle(1)],circle(3),size);

radius = (max(x) - min(x))/2;

xCenter = min(x) + radius;
yCenter = min(y) + radius;
end

