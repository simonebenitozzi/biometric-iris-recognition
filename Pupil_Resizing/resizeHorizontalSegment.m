function resizedSegment = resizeHorizontalSegment(image, start, stop, newStart, newStop, row)

segment = image(row, start:stop);
resizedSegmentWidth = newStop - newStart;
resizedSegment = imresize(segment, [1, resizedSegmentWidth]);

end

