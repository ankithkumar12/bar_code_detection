% Load the image
image = imread('bc4.png');

subplot(1,5,1)
imshow(image)

% Resize image
%image = imresize(image, 0.7);

% Convert to grayscale
gray = im2gray(image);

%show=1;
% Calculate x & y gradient
[gradX, gradY] = imgradientxy(gray);

% Subtract the y-gradient from the x-gradient
gradient = abs(gradX) - abs(gradY);

% Convert to unsigned 8-bit integer
gradient = uint8(gradient);

%blurred = imgaussfilt(gradient, 3);
blurred=gradient;
thresh = imbinarize(blurred, 225/255);
thresh = uint8(thresh * 255);

% Construct a closing kernel
se = strel('rectangle', [21, 7]);

% Apply the closing operation to the thresholded image
closed = imclose(thresh, se);
subplot(1,5,2)
imshow(closed)

closed = imerode(closed, strel('disk', 1));


subplot(1,5,3)
imshow(closed)

closed = imdilate(closed, strel('disk', 5));

subplot(1,5,4)
imshow(closed)

% Find the connected components (contours) in the thresholded image
CC = bwconncomp(closed);
stats = regionprops(CC, 'Area', 'BoundingBox');

% Sort the regions by area in descending order
[~, idx] = sort([stats.Area], 'descend');

% Extract the bounding box of the two largest regions
box = round(stats(idx(1)).BoundingBox);
%box1 = round(stats(idx(2)).BoundingBox);

% Convert the bounding box points to integer format
%box = [box(1:2); box(1:2) + box(3:4); box(1)+box(3), box(2); box(1), box(2)+box(4)];
%box1 = [box1(1:2); box1(1:2) + box1(3:4); box1(1)+box1(3), box1(2); box1(1), box1(2)+box1(4)];

% Draw bounding boxes around the detected regions
imageWithBB = insertShape(image, 'Rectangle', box, 'Color', 'green', 'LineWidth', 3);
%imageWithBB = insertShape(imageWithBB, 'Rectangle', box1, 'Color', 'green', 'LineWidth', 3);

subplot(1,5,5)
imshow(imageWithBB);


