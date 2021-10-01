%% Coordinates and axes for an ellipse

function [xCenter, yCenter, xSemiAxe, ySemiAxe] = ellipseDimensions(ellipse)

x = ellipse(1,:);
y = ellipse(2,:);

xSemiAxe = (max(x) - min(x))/2;
ySemiAxe = (max(y) - min(y))/2;

xCenter = min(x) + xSemiAxe;
yCenter = min(y) + ySemiAxe;

end