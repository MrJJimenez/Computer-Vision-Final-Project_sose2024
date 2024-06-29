% load a image
img = imread('cocina.JPG');
% Separate the image into R, G, B components
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% Convert each channel to double and normalize
R = double(R) / 255;
G = double(G) / 255;
B = double(B) / 255;

% Combine the normalized channels into an RGB image
C = cat(3, R, G, B);
size(C)
% Create a meshgrid for the surface plot
[x, y] = meshgrid(1:size(img, 2), 1:size(img, 1));
size(x)
% Plot the surface with RGB color
figure;
surf(x, zeros(size(R)), y,  'CData', C,'edgecolor', 'none');

% Adjust the view
view(3);

% Add labels and title
xlabel('X-axis');
ylabel('Y-axis');
zlabel('Z-axis');
title('3D Surface Plot of RGB Image');

% Optional: Adjust the axis
axis tight;