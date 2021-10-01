function resizedSegment = resizeVerticalSegment(image, start, stop, newStart, newStop, column)

segment = image(start:stop, column);
resizedSegmentHeight = newStop - newStart;
resizedSegment = imresize(segment, [resizedSegmentHeight, 1]);

end

