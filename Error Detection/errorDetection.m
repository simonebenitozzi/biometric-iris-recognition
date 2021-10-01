%% Paths setting

folderPath = 'C:\Users\simon\Documents\UNISA\4. Tesi\Implementazione\database\001';

if ~isfolder(folderPath)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', folderPath);
    uiwait(warndlg(errorMessage));
    return;
end

%% File initialization

% creates folder for data report files
dataFolderPath = strcat(folderPath, '\data');
if ~isfolder(dataFolderPath)
    mkdir(dataFolderPath);
end

dataFilename = strcat(dataFolderPath, '\distanceReport1.xlsx');
recycle on
if isfile(dataFilename)
    delete(dataFilename);
end

writematrix(["overall", "direction", "scale", "ratio", "iris distance", "pupil distance", "overall distance"], dataFilename);

currentOverall = 1;
currentDirection = "";

%% Folder opening

filePattern = fullfile(folderPath, '*.bmp');
images = dir(filePattern);

%% arrays containing distances for max, average and sd calculation

irisDistances = NaN(1, length(images));
pupilDistances = NaN(1, length(images));
overallDistances = NaN(1, length(images));

%% Expected Iris retrieving

irisFile = strcat(folderPath, '\masks\expectedIris.mat');
if isfile(irisFile)
    load(irisFile);
else
    errorMessage = sprintf('Error: The following file does not exist:\n%s', irisFile);
    uiwait(warndlg(errorMessage));
    return;
end

%% Images reading
figure("Visible", "off", "Name", "Expected Ellipse"), expectedFigure = axes;
figure("Visible", "off", "Name", "Detected Ellipse"), detectedFigure = axes;

for k = 1:length(images)
     
    fprintf("%3d/%3d", k, length(images));
    
    imageName = images(k).name;
    fullImageName = fullfile(folderPath, imageName);
    [path, name, extension] = fileparts(fullImageName);
    eyeImage = imread(fullImageName);
    
    %% Scaling Parameters retrieving

    scalingFile = [path, '\scalingParams\', name,'-scalingParams.mat'];
    [stat,~]=fileattrib(scalingFile);
    
    if stat == 1
        load(scalingFile);
    else
        warning('\nFile missing: %s', scalingFile);
        continue
    end
    
    %% Expected Iris
    
    imshow(eyeImage, "Parent", expectedFigure);
    
    % parameters retrieved from expectedIris.mat
    expectedIrisCircle = drawcircle(expectedFigure, "Center", [xCenterIris, yCenterIris], "Radius", irisRadius, "Color", "g");
    expectedIrisMask = createMask(expectedIrisCircle);
    
    %% Expected Ellipse
    
    % parameters retrieved from -scalingParams.mat
    expectedPupilEllipse = drawellipse(expectedFigure, "Center", [xCenterPupil, yCenterPupil], "SemiAxes", [xSemiAxe, ySemiAxe], "Color", "b");
    expectedPupilMask = createMask(expectedPupilEllipse);
    
    %% Hough Parameters retrieving
    
    houghFile = [path, '\houghParams\', name,'-houghParams.mat'];
    [stat,~]=fileattrib(houghFile);
    
     if stat == 1
         load(houghFile);
     else
        [circleiris, circlepupil, ellipsepupil, imagewithnoise, linecoordinates] = segmentiris(eyeImage, fullImageName);
        save(houghFile,'circleiris','circlepupil','ellipsepupil','imagewithnoise','linecoordinates');
    end
    
    %% Detected Iris Extraction
 
    imshow(eyeImage, "Parent", detectedFigure);
    
    [xCenterIrisDetected, yCenterIrisDetected, irisRadiusDetected] = circleDimensions(circleiris, size(eyeImage));
    detectedIrisCircle = drawcircle(detectedFigure, "Center", [xCenterIrisDetected, yCenterIrisDetected], "Radius", irisRadiusDetected, "Color", "y");
    detectedIrisMask = createMask(detectedIrisCircle);
    
    irisDistance = masksDistance(expectedIrisMask, detectedIrisMask, size(eyeImage));
    
    %% Detected Pupil Extraction
    
    % check if segmentiris didn't return NaN for ellipsepupil
    if ~isnan(ellipsepupil)
        
        [xCenterPupil, yCenterPupil, xSemiAxe, ySemiAxe] = ellipseDimensions(ellipsepupil);
        
        detectedPupilEllipse = drawellipse(detectedFigure, "Center", [xCenterPupil, yCenterPupil], "SemiAxes", [xSemiAxe, ySemiAxe], "Color", "r");
        detectedPupilMask = createMask(detectedPupilEllipse);
        
        pupilDistance = masksDistance(expectedPupilMask, detectedPupilMask, size(eyeImage));
        
    else
        pupilDistance = 1;
    end
    
    %pause(500/1000);    
    %% Data writing

    if scaleOverall > currentOverall
        currentOverall = scaleOverall;
        writematrix([" "; " "] ,dataFilename,'WriteMode','append');
    end

    if strcmp(direction, currentDirection) == 0
        writematrix(" " ,dataFilename,'WriteMode','append');
        currentDirection = direction;
    end
    
    writecell([scaleOverall, cellstr(direction), scale, ratio, irisDistance, pupilDistance, irisDistance+pupilDistance],dataFilename,'WriteMode','append');
    
    %% Distances Update

    irisDistances(k) = irisDistance;
    pupilDistances(k) = pupilDistance;
    overallDistances(k) = irisDistance + pupilDistance;
    
    fprintf(repmat('\b', 1, 7));
end

%% Max and Average Distance
avgIris = mean(irisDistances, "all");
avgPupil = mean(pupilDistances, "all");
avgOverall = mean(overallDistances, "all");

maxIris = max(irisDistances);
maxPupil = max(pupilDistances);
maxOverall = max(overallDistances);

%% Standard Deviation

% removes every NaN value from the array
irisDistances = rmmissing(irisDistances);
pupilDistances = rmmissing(pupilDistances);
ovearallDistances = rmmissing(overallDistances);

irisStd = std(irisDistances);
pupilStd = std(pupilDistances);
overallStd = std(overallDistances);

%% data reporting
writematrix([sprintf("Average Iris distance = %f", avgIris), sprintf("Max Iris distance = %f", maxIris), sprintf("Iris standard deviation = %f", irisStd)],dataFilename, 'Range', 'I3:K3');
writematrix([sprintf("Average Pupil distance = %f", avgPupil), sprintf("Max Pupil distance = %f", maxPupil), sprintf("Pupil standard deviation = %f", pupilStd)],dataFilename, 'Range', 'I4:K4');

writematrix([sprintf("Average Overall distance = %f", avgOverall), sprintf("Max overall distance = %f", maxOverall), sprintf("Overall standard deviation = %f", overallStd)],dataFilename, 'Range', 'I6:K6');
close all