boundary = 1.5;

while boundary < 3.6
    
    %% Folder opening
    folder = '005';
    folderPath = strcat('C:\Users\simon\Documents\UNISA\4. Tesi\Implementazione\database\', folder);
    
    if ~isfolder(folderPath)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
        uiwait(warndlg(errorMessage));
        return;
    end
    
    templatesFolderPath = strcat(folderPath, '\templates');
    if ~isfolder(templatesFolderPath)
        mkdir(templatesFolderPath);
    end
    
    filePattern = fullfile(folderPath, '*.bmp'); % all bmp files in the folder
    images = dir(filePattern);
    
    %% original image setting
    
    originalImageName = [folderPath, '\', folder, '.bmp'];
    
    templateFile = [folderPath, '\templates\', folder,'-template.mat'];
    [stat,~]=fileattrib(templateFile);
    
    if stat == 1
        load(templateFile);
    else
        [template, mask] = createiristemplate(eyeImage, fullImageName);
        save(templateFile, 'template', 'mask');
    end
    
    %% matching parameters
    
    blocks = 32;
    previousOverallCode = templateToCode(template, blocks);
    previousOverallMask = templateToCode(mask, blocks);
    
    currentOverall = 1;
    currentDirection = "";
    sum = 0;
    count = 0;
    
    exceedings = 0;
    
    threshold = 0.33;
    
    distances = NaN(1, length(images));
    
    %% Images reading
    
    for k = 1:length(images)
        
        fprintf("%3d/%3d", k, length(images));
        
        imageName = images(k).name;
        fullImageName = fullfile(folderPath, imageName);
        [path, name, extension] = fileparts(fullImageName);
        eyeImage = imread(fullImageName);
        
        if strcmp(fullImageName, originalImageName) == 1
            fprintf(repmat('\b', 1, 7));
            continue % skip the loop iteration, so it doesn't get compared to itself
        end
        
        %% Template retrieving
        
        templateFile = [path, '\templates\', name,'-template.mat'];
        [stat,~]=fileattrib(templateFile);
        
        if stat == 1
            load(templateFile);
        else
            try
                [template, mask] = createiristemplate(eyeImage, fullImageName);
            catch
                fprintf(repmat('\b', 1, 7));
                continue
            end
            save(templateFile, 'template', 'mask');
        end
        
        %% Scaling Parameters retrieving
        
        scalingFile = [path, '\scalingParams\', name,'-scalingParams.mat'];
        [stat,~]=fileattrib(scalingFile);
        
        if stat == 1
            load(scalingFile);
        else
            warning('File missing: %s', scalingFile);
            continue
        end
        
        %% matching
        
        currentCode = templateToCode(template, blocks);
        currentMask = templateToCode(mask, blocks);
        
        distance = gethammingdistance(currentCode, currentMask, previousOverallCode, previousOverallMask, 1);
        distance = round(distance, 2);
        
        %% parameters update
        if scale < boundary
            count = count + 1;
            
            sum = sum + distance;
            distances(count) = distance;
            
            if distance > threshold
                exceedings = exceedings + 1;
            end
        end
        
        %% check if overall changed
        
        % scale overall retrieved from -scalingParams.mat file
        if scaleOverall > currentOverall
            currentOverall = scaleOverall;
            previousOverallCode = currentCode;
            previousOverallMask = currentMask;
        end
        
        if strcmp(direction, currentDirection) == 0
            currentDirection = direction;
        end
        
        %%
        close all
        fprintf(repmat('\b', 1, 7));
    end
    
    %% report results
    
    avg = sum / count;
    
    % removes every NaN value from the array
    distances = rmmissing(distances);
    stdDev = std(distances);
    percentage = exceedings / count * 100;
    
    fprintf("Boundary = %f\tAverage = %f\tStandard Dev: %f\tExceedings = %d/%d (%f%%)\n", boundary, avg, stdDev, exceedings, count, percentage);
    
    %% Boundary update
    boundary = boundary + 0.5;
end
