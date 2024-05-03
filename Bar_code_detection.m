% Load the image
image = imread('bc5.png');

subplot(2,6,1)
imshow(image)
title("Original Image");

gray=image_to_gray(image);

subplot(2,6,2)
imshow(gray)
title("GrayScale Image");

[gradX, gradY] = compute_gradients(gray);

subplot(2, 6, 3);
imshow(gradX,[]);
title('Gradient along X direction');

subplot(2, 6, 4);
imshow(gradY,[]);
title('Gradient along Y direction');

gradient = abs(gradX) - abs(gradY);

gradient = uint8(gradient);

subplot(2, 6, 5);
imshow(gradient,[]);
title('Gradient');

binary_image=binarize_image(gradient,225);

subplot(2, 6, 6);
imshow(binary_image,[]);
title('Binary Image');

rect_se=create_rectangular_se(21,7);

closed_image=imclose(binary_image,rect_se);

subplot(2, 6, 7);
imshow(closed_image,[]);
title('Initial Closed Image');

disk_se=strel('disk',5);

eroded_image=imerode(closed_image,disk_se);

subplot(2, 6, 8);
imshow(eroded_image,[]);
title('Disk Eroded Image');

dilated_image=dilate_image(eroded_image,disk_se.Neighborhood);

subplot(2, 6, 9);
imshow(dilated_image);
title('Disk Dilated Image');

subplot(2, 6, 10);
cc=connected_components(dilated_image);
%image is plotted uin function declaration 
title('Connected Components');

stats = regionprops(cc, 'Area', 'BoundingBox');

% Sort the regions by area in descending order
[~, idx] = sort([stats.Area], 'descend');

% Extract the bounding box of the two largest regions
box = round(stats(idx(1)).BoundingBox);

% Draw bounding boxes around the detected regions
imageWithBB = insertShape(image, 'Rectangle', box, 'Color', 'green', 'LineWidth', 3);

subplot(2,6,11)
imshow(imageWithBB);
title("Detected BarCode");

function grayImg = image_to_gray(rgb_image)

    % Check if the input image is already grayscale
    if size(rgb_image, 3) == 1
        grayImg = rgb_image;
        return;
    end

    % Convert RGB image to grayscale using luminance method
    grayImg = 0.2989 * rgb_image(:,:,1) + 0.5870 * rgb_image(:,:,2) + 0.1140 * rgb_image(:,:,3);
end

function [gradX, gradY] = compute_gradients(gray)
    % Sobel operators for computing gradients
    sobelX = [-1 0 1; -2 0 2; -1 0 1];
    sobelY = [-1 -2 -1; 0 0 0; 1 2 1];

    % Convolve the image with Sobel operators
    gradX = conv2(double(gray), sobelX, 'same');
    gradY = conv2(double(gray), sobelY, 'same');
end

function binaryImage = binarize_image(inputImage, threshold)
    % Convert the image to grayscale if necessary
    if size(inputImage, 3) == 3
        inputImage = rgb2gray(inputImage);
    end

    % Binarize the image manually
    binaryImage = inputImage >= threshold;

    % Convert the binary image to uint8 format (0 and 1)
    binaryImage = uint8(binaryImage);
end

function se = create_rectangular_se(height, width)
    se = ones(height, width);
end

function dilatedImage = dilate_image(binaryImage, se)
    % Get the size of the structuring element
    [seHeight, seWidth] = size(se);
    
    % Get the size of the input image
    [imageHeight, imageWidth] = size(binaryImage);
    
    % Initialize the dilated image
    dilatedImage = zeros(imageHeight, imageWidth);
    
    % Perform dilation
    for i = 1:imageHeight
        for j = 1:imageWidth
            % Check if the structuring element fits entirely within the image
            if i <= imageHeight - seHeight + 1 && j <= imageWidth - seWidth + 1
                % Check if any foreground pixel is covered by the structuring element
                if any(any(binaryImage(i:i+seHeight-1, j:j+seWidth-1) & se))
                    dilatedImage(i, j) = 1;
                end
            end
        end
    end
end

function erodedImage = erode_image(binaryImage, se)
    % Get the size of the structuring element
    [seHeight, seWidth] = size(se);
    
    % Get the size of the input image
    [imageHeight, imageWidth] = size(binaryImage);
    
    % Initialize the eroded image
    erodedImage = zeros(imageHeight, imageWidth);
    
    % Perform erosion
    for i = 1:imageHeight
        for j = 1:imageWidth
            % Check if the structuring element fits entirely within the image
            if i <= imageHeight - seHeight + 1 && j <= imageWidth - seWidth + 1
                % Check if all foreground pixels are covered by the structuring element
                if all(all(binaryImage(i:i+seHeight-1, j:j+seWidth-1) & se))
                    erodedImage(i, j) = 1;
                end
            end
        end
    end
end

function closed = close_image(binaryImage, se)

    % Perform dilation
    dilatedImage = dilate_image(binaryImage, se);
    
    % Perform erosion
    closed = imerode(dilatedImage, se);
end

function labeledImage = connected_components(binaryImage)
    [height, width] = size(binaryImage);
    labeledImage = zeros(height, width);
    currentLabel = 1;

    for i = 1:height
        for j = 1:width
            if binaryImage(i, j) == 1 && labeledImage(i, j) == 0
                % Start a new connected component
                labeledImage = label_component(binaryImage, labeledImage, i, j, currentLabel);
                currentLabel = currentLabel + 1;
            end
        end
    end

    % Convert labeled image to RGB for visualization
    labeledImageRGB = label2rgb(labeledImage, 'hsv', 'k', 'shuffle');

    % Display the labeled image
    imshow(labeledImageRGB);
end

function labeledImage = label_component(binaryImage, labeledImage, i, j, currentLabel)
    [height, width] = size(binaryImage);
    stack = [i, j];

    while ~isempty(stack)
        currentPixel = stack(1, :);
        stack(1, :) = [];

        x = currentPixel(1);
        y = currentPixel(2);

        labeledImage(x, y) = currentLabel;

        % Check neighbors
        for m = -1:1
            for n = -1:1
                if x+m >= 1 && x+m <= height && y+n >= 1 && y+n <= width && binaryImage(x+m, y+n) == 1 && labeledImage(x+m, y+n) == 0
                    stack = [stack; x+m, y+n];
                    labeledImage(x+m, y+n) = currentLabel;
                end
            end
        end
    end
end



