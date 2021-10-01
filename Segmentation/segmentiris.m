function [circleiris, circlepupil, ellipsepupil, imagewithnoise, linecoordinates] = segmentiris(eyeimage, eyeimage_filename)

imgsize = size(eyeimage);
figure("Visible", "off", "Name", "tmp"), tmpFigure = axes;

%% find the iris boundary
[ny,nx,~] = size(eyeimage);

Iblur = imgaussfilt(eyeimage,5);
C = imadjust(Iblur);
f = imfill(C,8);
C2 = imadjust(f);
s = imsharpen(C2,'Amount',2);

lirisradius = round(min(nx,ny)/4);
uirisradius = round(max(nx,ny));

    [centers,radii,~] = imfindcircles(s,[lirisradius, uirisradius],'Method','PhaseCode', 'ObjectPolarity','dark', 'Sensitivity',0.85);
    bestCircle = find(min(radii));
    xc = centers(bestCircle,1);
    yc = centers(bestCircle,2);
    radius = radii(bestCircle);

circleiris = [round(yc), round(xc), round(radius)];
irisArea = pi * (radius).^2;
imshow(eyeimage, "Parent", tmpFigure);
viscircles(tmpFigure, [round(xc),round(yc)], round(radius),'EnhanceVisibility',false,'LineWidth',1);
%saveas(gcf,strcat(eyeimage_filename,'-circle_only.jpg'));

rowd = double(yc);
cold = double(xc);
rd = double(radius);

irl = round(rowd-rd);
iru = round(rowd+rd);
icl = round(cold-rd);
icu = round(cold+rd);

if irl < 1
    irl = 1;
end

if icl < 1
    icl = 1;
end

if iru > imgsize(1)
    iru = imgsize(1);
end

if icu > imgsize(2)
    icu = imgsize(2);
end

%% set up array for recording noise regions
% noise pixels will have NaN values
imagewithnoise = double(eyeimage);

%% to find the inner pupil, use just the region within the previously

% detected iris boundary
imagepupil = eyeimage( irl:iru,icl:icu);

[ny,nx,~] = size(eyeimage);
area = nx*ny;

Iblur = imgaussfilt(imagepupil,2);
C = imadjust(Iblur);
BW = imbinarize(C,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);
WB = imcomplement(BW);

s = regionprops('table',WB,C,{...
    'Area',...
    'Centroid',...
    'Eccentricity',...
    'EquivDiameter',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'MeanIntensity',...
    'Orientation'});

t = linspace(0,2*pi,50);

toDelete1 = s.Area <= 1/80*area;
toDelete2 = s.Area >= irisArea;

s(toDelete1,:) = [];
s(toDelete2,:) = [];

toDelete3 = [];
ellipseIndex = 1;
%centerArray = center .* ones(height(s), 2);
ellipses = struct('a',{},'b',{},'phi',{},'Xs',{},'Ys',{});
for k = 1:height(s)
    a = s{k,{'MajorAxisLength'}}/2;
    b = s{k,{'MinorAxisLength'}}/2;
    phi = deg2rad(-s{k,{'Orientation'}});
    centroid = s{k,{'Centroid'}};
    %distance = norm(centroid - center);
    x = centroid(1) + a*cos(t)*cos(phi) - b*sin(t)*sin(phi);
    y = centroid(2) + a*cos(t)*sin(phi) + b*sin(t)*cos(phi);
    externalPoints = sum(x(:)<0)+sum(x(:)>nx)+sum(y(:)<0)+sum(y(:)>ny)-sum(x(:)<0 & y(:)<0)-sum(x(:)<0 & y(:)>ny)-sum(x(:)>nx & y(:)<0)-sum(x(:)>nx & y(:)>ny);
    if externalPoints > 0.2*length(x)
        toDelete3 = horzcat(toDelete3,k);
    else
        ellipses(ellipseIndex) = struct('a',a,'b',b,'phi',phi,'Xs',x,'Ys',y);
        ellipseIndex = ellipseIndex+1;
    end
end
s(toDelete3,:) = [];
sOld = s;
ellipsesOld = ellipses;

if (height(s) == 0)
    if ~isempty(ellipsesOld)
        bestEllipse =  find(sOld.MeanIntensity == min(sOld.MeanIntensity));
        xBest = ellipsesOld(bestEllipse).Xs;
        yBest = ellipsesOld(bestEllipse).Ys;
        centroidBest = sOld{bestEllipse, {'Centroid'}};
        
        radiusBest = (ellipsesOld(bestEllipse).b + ellipsesOld(bestEllipse).a)/2;
    else
        % circleiris = [round(yc), round(xc), round(radius)];
        ellipsepupil = [round(xc)-round(radius), round(xc)+round(radius); round(yc)-round(radius), round(yc)+round(radius)];
        circlepupil = circleiris;
        linecoordinates = NaN;
        return
    end
else
    bestEllipse = find(s.MeanIntensity == min(s.MeanIntensity));
    xBest = ellipses(bestEllipse).Xs;
    yBest = ellipses(bestEllipse).Ys;
    centroidBest = s{bestEllipse, {'Centroid'}};
    radiusBest = (ellipses(bestEllipse).b + ellipses(bestEllipse).a)/2;
end

xBest = xBest + icl;
yBest = yBest + irl;
ellipsepupil = [xBest; yBest];

rowp = round(double(centroidBest(2)));
colp = round(double(centroidBest(1)));
r = round(double(radiusBest));

row = double(irl) + rowp;
col = double(icl) + colp;

row = round(row);
col = round(col);

circlepupil = [row col r];

%% find top eyelid
topeyelid = imagepupil(1:(rowp-r),:);
lines1 = findline(topeyelid);

if size(lines1,1) > 0
    [xlt, ylt] = linecoords(lines1, size(topeyelid));
    ylt = double(ylt) + irl-1;
    xlt = double(xlt) + icl-1;
    
    ylta = max(ylt);
    
    y2t = 1:ylta;
    
    ind3 = sub2ind(size(eyeimage),ylt,xlt);
    imagewithnoise(ind3) = NaN;
    
    imagewithnoise(y2t, xlt) = NaN;
    
    yltaArray = double(ylta) .* ones(1,length(ylt));
end

%% find bottom eyelid
bottomeyelid = imagepupil((rowp+r):size(imagepupil,1),:);
lines2 = findline(bottomeyelid);

if size(lines2,1) > 0
    [xlb, ylb] = linecoords(lines2, size(bottomeyelid));
    ylb = ylb+ irl+rowp+r-2;
    xlb = xlb + icl-1;
    ylba = min(ylb);
    
    y2b = ylba:size(eyeimage,1);
    
    ind4 = sub2ind(size(eyeimage),ylb,xlb);
    imagewithnoise(ind4) = NaN;
    imagewithnoise(y2b, xlb) = NaN;
    
    ylbaArray = double(ylba) .* ones(1,length(ylb));
end
if (size(lines1,1) > 0) && (size(lines2,1) > 0)
    linecoordinates = [xlt;ylt;xlb;ylb;yltaArray;ylbaArray];
else
    linecoordinates = NaN;
end

imagewithnoise(eyeimage < 30) = NaN;

reflecthres = 240;
imagewithnoise(imagewithnoise >= reflecthres) = NaN;
