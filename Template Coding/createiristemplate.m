% createiristemplate - generates a biometric template from an iris in
% an eye image.
%
% Usage: 
% [template, mask] = createiristemplate(eyeimage_filename)
%
% Arguments:
%	eyeimage_filename   - the file name of the eye image
%
% Output:
%	template		    - the binary iris biometric template
%	mask			    - the binary iris noise mask
%
% Author: 
% Libor Masek
% masekl01@csse.uwa.edu.au
% School of Computer Science & Software Engineering
% The University of Western Australia
% November 2003

function [template, mask] = createiristemplate(eyeimage, eyeimage_filename)

%% path for writing diagnostic images
global DIAGPATH
DIAGPATH = 'diagnostics';

%normalisation parameters
radial_res = 20;
angular_res = 240;
% with these settings a 9600 bit iris template is
% created

%% feature encoding parameters
nscales=1;
minWaveLength=18;
mult=1; % not applicable if using nscales = 1
sigmaOnf=0.5;

%eyeimage = imread(eyeimage_filename); 

%% loading data

[path, name, ~] = fileparts(eyeimage_filename);
savefile = [path, '\houghParams\', name,'-houghParams.mat'];

[stat,~]=fileattrib(savefile);

if stat == 1
    % if this file has been processed before
    % then load the circle parameters and
    % noise information for that file.
    load(savefile);
    
else
    
    % if this file has not been processed before
    % then perform automatic segmentation and
    % save the results to a file
    
    [circleiris, circlepupil, ellipsepupil, imagewithnoise, linecoordinates] = segmentiris(eyeimage, eyeimage_filename);

    save(savefile,'circleiris','circlepupil','ellipsepupil','imagewithnoise','linecoordinates');
    
end

%% WRITE NOISE IMAGE

imagewithnoise2 = uint8(imagewithnoise);
imagewithcircles = uint8(eyeimage);
imagewithellipse = uint8(eyeimage);

%% get pixel coords for circle around iris
[x,y] = circlecoords([circleiris(2),circleiris(1)],circleiris(3),size(eyeimage));
ind2 = sub2ind(size(eyeimage),double(y),double(x)); 

%% get pixel coords for circle and ellipse around pupil
[xp,yp] = circlecoords([circlepupil(2),circlepupil(1)],circlepupil(3),size(eyeimage));
ind1 = sub2ind(size(eyeimage),double(yp),double(xp));
xPupil = ellipsepupil(1,:);
yPupil = ellipsepupil(2,:);
indEllipse = sub2ind(size(eyeimage),int32(yPupil),int32(xPupil));

%% Write noise regions
imagewithnoise2(ind2) = 255;
imagewithnoise2(ind1) = 255;

%% Write circles overlayed
imagewithcircles(ind2) = 255;
imagewithcircles(ind1) = 255;

%% Write circle and ellipse overlayed
imagewithellipse(indEllipse) = 255;
imagewithellipse(ind2) = 255;
figure('Visible','off', 'Name', 'ellipse'),imshow(imagewithellipse);

hold on
plot(xPupil,yPupil,'b','Linewidth',1)
hold off
%%
% saveas(gcf,strcat(eyeimage_filename,'-ellipse.jpg'));
w = cd;
cd(DIAGPATH);
% imwrite(imagewithnoise2,[eyeimage_filename,'-noise.jpg'],'jpg');
% imwrite(imagewithcircles,[eyeimage_filename,'-segmented.jpg'],'jpg');
figure('Visible','off'), imshow(imagewithcircles);
% imwrite(imagewithellipse,[eyeimage_filename,'-ellipse.jpg'],'jpg');
cd(w);

%% Print segmented image with circles and lines
if ~isnan(linecoordinates)
    xlt = linecoordinates(1,:);
    ylt = linecoordinates(2,:);
    xlb = linecoordinates(3,:);
    ylb = linecoordinates(4,:);
    y2t = linecoordinates(5,:);
    y2b = linecoordinates(6,:);

    figure('Visible','off'),imshow(imagewithcircles);
    hold on
    plot(xlt,ylt,'r','Linewidth',1);
    plot(xlb,ylb,'r','Linewidth',1);
    plot(xlt,y2t,'y','Linewidth',1);
    plot(xlt,y2b,'y','Linewidth',1);
    hold off
 %   saveas(gcf,strcat(eyeimage_filename,'-lines.jpg'));
end

%% perform normalisation
[polar_array noise_array] = normaliseiris(imagewithnoise, circleiris(2),...
    circleiris(1), circleiris(3), circlepupil(2), circlepupil(1), circlepupil(3),eyeimage_filename, radial_res, angular_res);


%% WRITE NORMALISED PATTERN, AND NOISE PATTERN
w = cd;
cd(DIAGPATH);
% imwrite(polar_array,[eyeimage_filename,'-polar.jpg'],'jpg');
% imwrite(noise_array,[eyeimage_filename,'-polarnoise.jpg'],'jpg');
cd(w);

%% perform feature encoding
 [template, mask] = encode(polar_array, noise_array, nscales, minWaveLength, mult, sigmaOnf); 