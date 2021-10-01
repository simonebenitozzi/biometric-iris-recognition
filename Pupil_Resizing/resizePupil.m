%% file loading

folder = '001';
imageFullName = strcat('C:\Users\simon\Documents\UNISA\4. Tesi\Implementazione\database\', folder, '\', folder, '.bmp');

originalEyeImage = imread(imageFullName);
eyeImage = originalEyeImage;

[imageHeight, imageWidth] = size(eyeImage);

% extracts path, name and extension from the full name
[imagePath, imageName, extension] = fileparts(imageFullName);

%% loading data

% creates folder for hough parameters .mat files
folderPath = strcat(imagePath, '\houghParams');
if ~isfolder(folderPath)
    mkdir(folderPath);
end

saveFile = [folderPath, '\', imageName, '-houghParams.mat'];
[stat,~]=fileattrib(saveFile);

if stat == 1
    load(saveFile);
else
    [circleiris, circlepupil, ellipsepupil, imagewithnoise, linecoordinates] = segmentiris(eyeImage, imageFullName);
    save(saveFile,'circleiris','circlepupil','ellipsepupil','imagewithnoise','linecoordinates');
end

%% get pixel coords for iris' circle and pupil's ellipse

[xCenterIris, yCenterIris, radiusIris] = circleDimensions(circleiris, size(eyeImage));

[xCenterPupilCircle, yCenterPupilCircle, radiusPupilCircle] = circleDimensions(circlepupil, size(eyeImage));
[xCenterPupil, yCenterPupil, xSemiAxePupil, ySemiAxePupil] = ellipseDimensions(ellipsepupil);

%% Convert image data type

imagewithnoise = uint8(imagewithnoise);

imagewithcircles = uint8(eyeImage);
imagewithellipse = uint8(eyeImage);

irisImage = imagewithcircles;
pupilImage = imagewithellipse;

%% loading masks

% creates folder for masks files
folderPath = strcat(imagePath, '\masks');
if ~isfolder(folderPath)
    mkdir(folderPath);
end

maskFile = [folderPath, '\', 'masks.mat'];
[stat, ~]=fileattrib(maskFile);

if stat == 1
    load(maskFile);
else
    %% Iris Extraction
    
    figure("Visible", "on", "Name", "Draw a Circle around Iris"), imshow(irisImage);
    expectedIris = drawcircle("Center", [xCenterIris, yCenterIris], "Radius", radiusIris, "Color", "g");
    wait(expectedIris);
    irisMask = createMask(expectedIris);
    
    %% Pupil Extraction
    
    figure("Visible", "on", "Name", "Draw an Ellipse around pupil");
    imshow(pupilImage);
    expectedPupil = drawellipse("Center", [xCenterPupil, yCenterPupil], "SemiAxes", [xSemiAxePupil, ySemiAxePupil]);
    wait(expectedPupil);
    pupilMask = createMask(expectedPupil);
    
    %% saving masks
    save(maskFile,'irisMask','pupilMask', 'expectedIris', 'expectedPupil');
end

%% Iris and Pupil image fixing

irisImage(~irisMask) = NaN;

zeros = pupilImage==0;
pupilImage(zeros(:)) = pupilImage(zeros(:)) + 1;
pupilImage(~pupilMask) = NaN;

%% Iris Parameters setting

center = expectedIris.Center;
xCenterIris = center(1);
yCenterIris = center(2);
irisRadius = expectedIris.Radius;

%% Pupil Parameters setting

center = expectedPupil.Center; % center coordinates
expectedXCenterPupil = center(1);
expectedYCenterPupil = center(2);

semiAxes = expectedPupil.SemiAxes;
xSemiAxeOriginal = semiAxes(1);
ySemiAxeOriginal = semiAxes(2);

xSemiAxe = xSemiAxeOriginal;
ySemiAxe = ySemiAxeOriginal;

%% Ratio between Iris and Pupil areas

irisArea = pi * (double(irisRadius)).^2;
pupilArea = pi * (xSemiAxe * ySemiAxe);
ratio = (pupilArea / irisArea);

%% storing data

saveFile = strcat(folderPath, '\', 'expectedIris.mat');
if ~isfile(saveFile)
    save(saveFile, 'xCenterIris', 'yCenterIris', 'irisRadius');
end

% creates folder for scaling parameters .mat files
folderPath = strcat(imagePath, '\scalingParams');
if ~isfolder(folderPath)
    mkdir(folderPath);
end

saveFile = strcat(folderPath, '\', imageName, '-scalingParams.mat');
if ~isfile(saveFile)
    saveScalingParameters(saveFile, expectedXCenterPupil, expectedYCenterPupil, xSemiAxe, ySemiAxe, ratio, 1, "", 1);
end

%% Boundaries

[rowsBoundaries, columnsBoundaries, intersectionX1, intersectionX2, intersectionY1, intersectionY2] = eyeBoundaries(irisMask, pupilMask);
currentRowsBoundaries = rowsBoundaries;
currentColumnsBoundaries = columnsBoundaries;

%% Pupil position parameters

if xCenterPupil <= imageWidth - xCenterPupil
    x0PupilImage = 0;
    pupilImageWidth = xCenterPupil*2;
else
    x0PupilImage = round(xCenterPupil - (imageWidth - xCenterPupil));
    pupilImageWidth = 2*(imageWidth - xCenterPupil);
end

if yCenterPupil <= imageHeight - yCenterPupil
    y0PupilImage = 0;
    pupilImageHeight = yCenterPupil*2;
else
    y0PupilImage = round(yCenterPupil - (imageHeight - yCenterPupil));
    pupilImageHeight = 2*(imageHeight - yCenterPupil);
end

%% Pupil image cropping

% pupilImage = image with pupil centered
pupilImageOriginal = imcrop(pupilImage, [x0PupilImage, y0PupilImage, pupilImageWidth, pupilImageHeight]);
pupilImage = pupilImageOriginal;

%% Scaling parameters

scaleHeight = 1;
scaleWidth = 1;
scaleOverall = 1;

%% PUPIL RESIZING

figure("Name", "Scaled"), scaledFigure = axes;
figure("Visible", "off", "Name", "tmp"), tmpFigure = axes;
directions = {'down', 'right', 'left'};

while(1) % iterates until pupil reaches iris dimension
    
    fprintf("scale Overall = %.1f\n", scaleOverall);
    scaleHeight = scaleHeight + 0.1;
    
    for d = 1:length(directions)
        while(1) % iterates until pupil reaches iris boundary
            
            %% Expected Pupil Extraction
            
            dX = (xSemiAxe*scaleWidth - xSemiAxe) / 2;
            dY = (ySemiAxe*scaleHeight - ySemiAxe) / 2;
            
            if strcmp(directions(d), 'left')
                currentXCenterPupil = expectedXCenterPupil - dX;
            else
                currentXCenterPupil = expectedXCenterPupil + dX;
            end
            
            currentYCenterPupil = expectedYCenterPupil + dY;
            
            currentXSemiAxe = xSemiAxe + dX;
            currentYSemiAxe = ySemiAxe + dY;
            
            %% Check if resized Pupil exceedes Iris boundary
            
            % down
            if(currentYCenterPupil + currentYSemiAxe > currentColumnsBoundaries(4, floor(currentXCenterPupil)))
                scaleHeight = 1;
                scaleWidth = 1.1;
                break
            end
            
            % right
            if(currentXCenterPupil + currentXSemiAxe > currentRowsBoundaries(floor(currentYCenterPupil), 4))
                scaleWidth = 1.1;
                break
            end
            
            % left
            if(currentXCenterPupil - currentXSemiAxe < currentRowsBoundaries(floor(currentYCenterPupil), 1))
                scaleWidth = 1;
                break
            end
            
            %% Pupil Resizing
            
            resizedImage = imresize(pupilImage, [(pupilImageHeight*scaleHeight), (pupilImageWidth*scaleWidth)], "nearest");
            [resizedHeight, resizedWidth] = size(resizedImage);
            
            %% Pupil Cropping
            
            startX = (resizedWidth - pupilImageWidth)/2;
            startY = (resizedHeight - pupilImageHeight)/2;
            croppedImage = imcrop(resizedImage, [startX, startY, pupilImageWidth, pupilImageHeight]);
            
            %% Output file name
            
            switch d
                case 1
                    outputName = strcat(imagePath, '\', imageName, sprintf('-%.1f-', scaleOverall), directions(d), sprintf('%.1f', scaleHeight), extension);
                case {2, 3}
                    outputName = strcat(imagePath, '\', imageName, sprintf('-%.1f-', scaleOverall), directions(d), sprintf('%.1f', scaleWidth), extension);
            end
            
            outputName = char(outputName);
            %% Resized Pupil pasting
            
            if ~exist(outputName, "file") % write a new image if it doesn't exist
                
                output = eyeImage;
                for r = 1:pupilImageHeight
                    
                    for c = 1:pupilImageWidth
                        
                        if croppedImage(r, c) ~= 0
                            
                            if (d == 1 && r+y0PupilImage >= yCenterPupil) || (d == 2 && c+x0PupilImage >= xCenterPupil) || (d == 3 && c+x0PupilImage <= xCenterPupil)
                                
                                output(r+y0PupilImage, c+x0PupilImage) = croppedImage(r, c);
                                
                                switch d
                                    
                                    case 1 % down
                                        if croppedImage(r+1, c) == 0
                                            column = c+x0PupilImage;
                                            
                                            irisEdge = currentColumnsBoundaries(4, column-1);
                                            pupilEdge = currentColumnsBoundaries(3, column-1);
                                            if irisEdge ~= 0 && pupilEdge ~= 0
                                                newPupilEdge = r+y0PupilImage;
                                                if newPupilEdge < irisEdge
                                                    output(newPupilEdge+1:irisEdge, column) = resizeVerticalSegment(eyeImage, pupilEdge, irisEdge, newPupilEdge, irisEdge, column);
                                                end
                                            end
                                        end
                                        
                                    case 2 % right
                                        if croppedImage(r, c+1) == 0
                                            row = r+y0PupilImage;
                                            
                                            irisEdge = currentRowsBoundaries(row-1, 4);
                                            pupilEdge = currentRowsBoundaries(row-1, 3);
                                            if irisEdge ~= 0 && pupilEdge ~= 0
                                                newPupilEdge = c+x0PupilImage;
                                                if newPupilEdge < irisEdge
                                                    output(row, newPupilEdge+1:irisEdge ) = resizeHorizontalSegment(eyeImage, pupilEdge, irisEdge, newPupilEdge, irisEdge, row);
                                                end
                                            end
                                            
                                        end
                                        
                                    case 3 % left
                                        if croppedImage(r, c-1) == 0
                                            row = r+y0PupilImage;
                                            
                                            irisEdge = currentRowsBoundaries(row-1, 1);
                                            pupilEdge = currentRowsBoundaries(row-1, 2);
                                            if irisEdge ~= 0 && pupilEdge ~= 0
                                                newPupilEdge = c+x0PupilImage;
                                                if irisEdge < newPupilEdge
                                                    output(row, irisEdge:newPupilEdge-1) = resizeHorizontalSegment(eyeImage, irisEdge, pupilEdge, irisEdge, newPupilEdge, row);
                                                end
                                            end
                                        end
                                end
                            end
                        end
                    end
                end
                
                imwrite(output, outputName);
            else % if the image already exists
                output = imread(outputName);
            end
            
            imshow(output, 'Parent', scaledFigure);
            pause(10/1000);
            
            %% Ratio between Iris and Pupil areas
            
            pupilArea = pi * (currentXSemiAxe * currentYSemiAxe);
            ratio = (pupilArea / irisArea);
            
            %% storing data
            
            [path, name, ~] = fileparts(outputName);
            saveFile = strcat(path, '\scalingParams\', name ,'-scalingParams.mat');
            switch d
                case 1
                    scale = scaleHeight;
                case {2, 3}
                    scale = scaleWidth;
            end
            
            if ~isfile(saveFile)
                saveScalingParameters(saveFile, currentXCenterPupil, currentYCenterPupil, currentXSemiAxe, currentYSemiAxe, ratio, scaleOverall, directions(d), scale);
            end
            %% Increase scaling for the next iteration
            
            switch d
                case 1
                    scaleHeight = scaleHeight + 0.1;
                case {2, 3}
                    scaleWidth = scaleWidth + 0.1;
            end
            
        end
    end
    
    %% Incrementing overall scaling
    
    scaleOverall = scaleOverall + 0.1;
    
    resizedImage = imresize(pupilImageOriginal, scaleOverall, 'nearest');
    [resizedHeight, resizedWidth] = size(resizedImage);
    
    startX = (resizedWidth - pupilImageWidth)/2;
    startY = (resizedHeight - pupilImageHeight)/2;
    pupilImage = imcrop(resizedImage, [startX, startY, pupilImageWidth, pupilImageHeight]);
    
    %% Expected Pupil Extraction
    
    dX = xSemiAxeOriginal*scaleOverall - xSemiAxeOriginal;
    dY = ySemiAxeOriginal*scaleOverall - ySemiAxeOriginal;
    
    xSemiAxe = xSemiAxeOriginal + dX;
    ySemiAxe = ySemiAxeOriginal + dY;
    
    %% Check if resied Pupil exceedes Iris boundaries
    
    if(yCenterPupil - ySemiAxe < columnsBoundaries(1, floor(xCenterPupil))) || (yCenterPupil + ySemiAxe > columnsBoundaries(4, floor(xCenterPupil)))
        break
    end
    
    if(xCenterPupil - xSemiAxe < rowsBoundaries(floor(yCenterPupil), 1)) || (xCenterPupil + xSemiAxe > rowsBoundaries(floor(yCenterPupil), 4))
        break
    end
    
    %% Creating the new mask
    
    figure("Visible", "off", "Name", "Showing Image for new mask creation");
    imshow(originalEyeImage, "Parent", tmpFigure);
    
    expectedPupil = drawellipse(tmpFigure, "Center", [expectedXCenterPupil, expectedYCenterPupil], "SemiAxes", [xSemiAxe, ySemiAxe]);
    pupilMask = createMask(expectedPupil);
    
    %% Boundaries
    
    [currentRowsBoundaries, currentColumnsBoundaries, currentIntersectionX1, currentIntersectionX2, currentIntersectionY1, currentIntersectionY2] = eyeBoundaries(irisMask, pupilMask);
    
    %% Editing Image with Overall Scaling
    savingName = strcat(imagePath, '\', imageName, sprintf('-%.1f-', scaleOverall), extension);
    if ~exist(savingName, "file")
        
        %% Angles Fixing
        eyeImage = originalEyeImage;
        
        for r = 1:imageHeight % rows
            
            b1 = rowsBoundaries(r, 1);
            b2 = rowsBoundaries(r, 4);
            
            if b1 > 0 && (r <= intersectionY1 || r >= intersectionY2)
                
                if b1 < intersectionX1 && (currentIntersectionX1 - b1) > 0
                    eyeImage(r, b1+1:currentIntersectionX1) = resizeHorizontalSegment(eyeImage, b1, intersectionX1, b1, currentIntersectionX1, r);
                end
                
                if b2 > intersectionX2 && (b2 - currentIntersectionX2) > 0
                    eyeImage(r, currentIntersectionX2+1:b2) = resizeHorizontalSegment(eyeImage, intersectionX2, b2, currentIntersectionX2, b2, r);
                end
            end
        end
        
        for c = 1:imageWidth % columns
            
            b1 = columnsBoundaries(1, c);
            b2 = columnsBoundaries(4, c);
            
            if b1 > 0 && (c <= currentIntersectionX1 || c >= currentIntersectionX2)
                
                if b1 < intersectionY1 && (currentIntersectionY1 - b1) > 0
                    eyeImage(b1+1:currentIntersectionY1, c) = resizeVerticalSegment(eyeImage, b1, intersectionY1, b1, currentIntersectionY1, c);
                end
                
                if b2 > intersectionY2 && (b2 - currentIntersectionY2) > 0
                    eyeImage(currentIntersectionY2+1:b2, c) = resizeVerticalSegment(eyeImage, intersectionY2, b2, currentIntersectionY2, b2, c);
                end
            end
        end
        
        %% Pupil overall resizing
        for r = 1:pupilImageHeight
            
            for c = 1:pupilImageWidth
                
                if pupilImage(r, c) ~= 0
                    
                    eyeImage(r+y0PupilImage, c+x0PupilImage) = pupilImage(r, c);
                    %% Stretch Up
                    if r > 1 && pupilImage(r-1, c) == 0 % Il pixel sopra non è pupilla
                        
                        originalX = originalCoordinate(c, startX, pupilImageWidth, resizedWidth, x0PupilImage);
                        
                        originalIrisEdge = columnsBoundaries(1, originalX-1);
                        originalPupilEdge = columnsBoundaries(2, originalX-1);
                        if originalIrisEdge ~= 0 && originalPupilEdge ~= 0
                            newIrisEdge = columnsBoundaries(1, c+x0PupilImage);
                            newPupilEdge = r+y0PupilImage;
                            
                            if newIrisEdge < newPupilEdge - 1 && newIrisEdge > 0 && newPupilEdge > 0
                                eyeImage(newIrisEdge:newPupilEdge-1, c+x0PupilImage) = resizeVerticalSegment(originalEyeImage, originalIrisEdge, originalPupilEdge, newIrisEdge, newPupilEdge, originalX-1);
                            end
                        end
                    end
                    
                    %% Stretch Down
                    if pupilImage(r+1, c) == 0 % Il pixel sotto non è pupilla
                        
                        originalX = originalCoordinate(c, startX, pupilImageWidth, resizedWidth, x0PupilImage);
                        
                        originalPupilEdge = columnsBoundaries(3, originalX-1);
                        originalIrisEdge = columnsBoundaries(4, originalX-1);
                        if originalIrisEdge ~= 0 && originalPupilEdge ~= 0
                            newPupilEdge = r+y0PupilImage;
                            newIrisEdge = columnsBoundaries(4, c+x0PupilImage);
                            
                            if newPupilEdge + 1 < newIrisEdge
                                eyeImage(newPupilEdge+1:newIrisEdge, c+x0PupilImage) = resizeVerticalSegment(originalEyeImage, originalPupilEdge, originalIrisEdge, newPupilEdge, newIrisEdge, originalX-1);
                            end
                        end
                    end
                    
                    %% Stretch Left
                    if c > 1 && pupilImage(r, c-1) == 0 % Il pixel a sinistra non è pupilla
                        
                        originalY = originalCoordinate(r, startY, pupilImageHeight, resizedHeight, y0PupilImage);
                        
                        originalIrisEdge = rowsBoundaries(originalY-1, 1);
                        originalPupilEdge = rowsBoundaries(originalY-1, 2);
                        if originalIrisEdge ~= 0 && originalPupilEdge ~= 0
                            newIrisEdge = rowsBoundaries(r+y0PupilImage, 1);
                            newPupilEdge = c+x0PupilImage;
                            
                            if newIrisEdge < newPupilEdge - 1
                                eyeImage(r+y0PupilImage, newIrisEdge:newPupilEdge-1) = resizeHorizontalSegment(originalEyeImage, originalIrisEdge, originalPupilEdge, newIrisEdge, newPupilEdge, originalY-1);
                            end
                        end
                    end
                    
                    %% Stretch Right
                    if pupilImage(r, c+1) == 0 % Il pixel a destra non è pupilla
                        
                        originalY = originalCoordinate(r, startY, pupilImageHeight, resizedHeight, y0PupilImage);
                        
                        originalPupilEdge = rowsBoundaries(originalY-1, 3);
                        originalIrisEdge = rowsBoundaries(originalY-1, 4);
                        if originalIrisEdge ~= 0 && originalPupilEdge ~= 0
                            newPupilEdge = c+x0PupilImage;
                            newIrisEdge = rowsBoundaries(r+y0PupilImage, 4);
                            
                            if newPupilEdge + 1 < newIrisEdge
                                eyeImage(r+y0PupilImage, newPupilEdge+1:newIrisEdge) = resizeHorizontalSegment(originalEyeImage, originalPupilEdge, originalIrisEdge, newPupilEdge, newIrisEdge, originalY-1);
                            end
                        end
                        
                    end
                    
                end
            end
        end
        
        %% Saving the new resized image
        imwrite(eyeImage, savingName);
    else
        eyeImage = imread(savingName);
    end
    
    imshow(eyeImage, 'Parent', scaledFigure);
    pause(10/1000);
    %% Ratio between Iris and current Pupil areas
    
    pupilArea = pi * (xSemiAxe * ySemiAxe);
    ratio = pupilArea / irisArea;
    
    %% storing data
    [path, name, ~] = fileparts(savingName);
    saveFile = strcat(path, '\scalingParams\', name ,'-scalingParams.mat');
    if ~isfile(saveFile)
        saveScalingParameters(saveFile, expectedXCenterPupil, expectedYCenterPupil, xSemiAxe, ySemiAxe, ratio, scaleOverall, " ", 1);
    end
    fprintf(repmat('\b', 1, 20));
end

%% Variables cleaning

% clear ax
close all
clear k r c direction

clear scaleHeight scaleWidth scaleOverall
clear currentPupilArea currentXCenterPupil currentYCenterPupil currentXSemiAxe currentYSemiAxe dX dY
clear x0PupilImage y0PupilImage startX startY
clear ratio

clear output pupilImage resizedImage
clear eyeimage_filename outputName savingName savefile
clear savedXCenterPupil savedYCenterPupil savedXSemiAxe savedYSemiAxe
clear resizedHeight resizedWidth

clear expectedCircle expectedEllipse
clear pupilArea irisArea

%% Utility Functions

function original = originalCoordinate(coord, diff1, size, resizedSize, diff2)

resizedCoord = coord + diff1; % coordinata corrispondente in resized Image
pupilCoord = round((size * resizedCoord) / resizedSize); % y corrispondente in pupil Image originale
original = pupilCoord + diff2; % coordinata corrispondente in eyeimage originale

end

function saveScalingParameters(saveFile, xCenterPupil, yCenterPupil, xSemiAxe, ySemiAxe, ratio, scaleOverall, direction, scale)

save(saveFile, 'xCenterPupil', 'yCenterPupil', 'xSemiAxe', 'ySemiAxe', 'ratio', 'scaleOverall', 'direction', 'scale');
% save saveFile xCenterPupil yCenterPupil xSemiAxe ySemiAxe ratio scaleOverall direction scale

end