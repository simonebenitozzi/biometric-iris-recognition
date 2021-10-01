function code = templateToCode(matrix, blocks)

blockWidth = size(matrix, 2) / blocks;
threshold = mean(matrix, 'all');
code = zeros(1, blocks);
k = 1;

for i = 1:blocks

    block = matrix(:, k : k + blockWidth-1);
    if mean(block, 'all') > threshold
        code(1, i) = 1;
    else
        code(1, i) = 0;
    end
    k = k+blockWidth;
end

code = logical(code);
end