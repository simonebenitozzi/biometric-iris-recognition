function distance = masksDistance(mask1, mask2, size)

area1 = 0;
area2 = 0;
intersectionArea = 0;

for r = 1:size(1)
    for c = 1:size(2)
        if(mask1(r, c) && mask2(r, c))
            area1 = area1 + 1;
            area2 = area2 + 1;
            intersectionArea = intersectionArea + 1;
        elseif mask1(r, c)
            area1 = area1 + 1;
        elseif mask2(r, c)
            area2 = area2 + 1;
        end
    end
end

distance = (area1 + area2 - (2 * intersectionArea)) / (area1 + area2);

end

