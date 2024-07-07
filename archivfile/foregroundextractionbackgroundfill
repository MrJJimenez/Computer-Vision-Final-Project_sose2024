% Ask the user for the number of foreground objects
numObjects = input('Enter the number of foreground objects: ');

% Load the image
imagePath = 'oil-painting.png';
image = imread(imagePath);

% Display the image
figure;
imshow(image);
title('Original Image');

% Initialize the combined mask
combinedMask = false(size(image, 1), size(image, 2));

% Loop to manually select each foreground object
for i = 1:numObjects
    figure;
    imshow(image);
    title(['Select foreground object ' num2str(i)]);
    h = drawpolygon();
    mask = createMask(h);
    
    % Combine the masks
    combinedMask = combinedMask | mask;
end

% Display the combined mask
figure;
imshow(combinedMask);
title('Combined Foreground Mask');

% Save the combined mask
imwrite(combinedMask, 'combined_mask.png');

% Extract the foreground objects using the combined mask
foreground = bsxfun(@times, image, cast(combinedMask, 'like', image));

% Save the extracted foreground objects
imwrite(foreground, 'extracted_foreground.png');

% Display the extracted foreground
figure;
imshow(foreground);
title('Extracted Foreground Object');

% Create the background by removing the foreground objects
background = image;
background(repmat(combinedMask, [1, 1, 3])) = 0;

% Display the background with holes
figure;
imshow(background);
title('Background with Holes');

% Fill the holes in the background using inpaintExemplar
backgroundDouble = im2double(background);
filledBackground = inpaintExemplar(backgroundDouble, combinedMask);

% Save the filled background
imwrite(filledBackground, 'filled_background.png');

% Display the filled background
figure;
imshow(filledBackground);
title('Filled Background');

% Function to fill missing regions using inpainting
function fill_missing_region(imagePath, maskPath, outputPath)
    % Load the image
    image = imread(imagePath);

    % Load the mask
    mask = imread(maskPath);
    mask = imbinarize(mask);  % Ensure mask is binary

    % Display the original image and mask
    figure;
    subplot(1, 2, 1);
    imshow(image);
    title('Original Image');

    subplot(1, 2, 2);
    imshow(mask);
    title('Mask');

    % Convert image to double precision for inpainting
    imageDouble = im2double(image);

    % Fill missing regions using inpainting
    filledImage = inpaintExemplar(imageDouble, mask);

    % Display the filled image
    figure;
    imshow(filledImage);
    title('Filled Image');

    % Save the filled image
    imwrite(filledImage, outputPath);
end

% Paths for the fill_missing_region function
imagePath = 'oil-painting.png';  % Path to your original image
maskPath = 'combined_mask.png';  % Path to your binary mask
outputPath = 'filled_background.png';  % Path to save the filled image

% Call the function to fill missing regions
fill_missing_region(imagePath, maskPath, outputPath);