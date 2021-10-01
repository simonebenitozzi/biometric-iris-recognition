%% Paths setting
close all
imageName = 'C:\Users\simon\Documents\UNISA\4. Tesi\Implementazione\database\001\001-3.2-right1.1.bmp';
[~, name, ~] = fileparts(imageName);
eyeImage = imread(imageName);

%% Hough Parameters retrieving for original implementation

[circleiris, ~, ellipsepupil, ~, ~] = segmentirisOriginal(eyeImage, imageName);

%% Iris Extraction for original implementation

figure("Visible", "on", "Name", strcat(name, " [Original]"))
imshow(eyeImage);

[xCenterIrisDetected, yCenterIrisDetected, irisRadiusDetected] = circleDimensions(circleiris, size(eyeImage));
drawcircle("Center", [xCenterIrisDetected, yCenterIrisDetected], "Radius", irisRadiusDetected, "Color", "g");

%% Pupil Extraction for original implementation

if ~isnan(ellipsepupil)
    [xCenterPupil, yCenterPupil, xSemiAxe, ySemiAxe] = ellipseDimensions(ellipsepupil);
    drawellipse("Center", [xCenterPupil, yCenterPupil], "SemiAxes", [xSemiAxe, ySemiAxe], "Color", "b");
end

pupilArea = irisRadiusDetected * irisRadiusDetected * pi;
[x, y] = size(eyeImage);
imageAreaThird = (x*y)/3;

if pupilArea > imageAreaThird
    a = 5
end

%% Hough Parameters retrieving for updated implementation

[circleiris, ~, ellipsepupil, ~, ~] = segmentiris(eyeImage, imageName);

%% Iris Extraction for updated implementation

figure("Visible", "on", "Name", strcat(name, " [Updated]"))
imshow(eyeImage);

[xCenterIrisDetected, yCenterIrisDetected, irisRadiusDetected] = circleDimensions(circleiris, size(eyeImage));
drawcircle("Center", [xCenterIrisDetected, yCenterIrisDetected], "Radius", irisRadiusDetected, "Color", "g");

%% Pupil Extraction for updated implementation

[xCenterPupil, yCenterPupil, xSemiAxe, ySemiAxe] = ellipseDimensions(ellipsepupil);
drawellipse("Center", [xCenterPupil, yCenterPupil], "SemiAxes", [xSemiAxe, ySemiAxe], "Color", "b");