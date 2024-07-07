% load a image

%clc
%clear all
%close all
img = imread('/Users/jesusjimenez/Documents/MyGitProjects/Computer-Vision-Final-Project_sose2024/jesus_main/CV-Challenge-24-Datensatz/oil-painting.png');
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
C = cat(1,C,C);
size(C)
% Create a meshgrid for the surface plot
[x, y] = meshgrid(1:size(img, 2), 1:size(img, 1));
[x1, y2] = meshgrid(1:size(img, 2), 1:size(img, 1));
size(x)
x = cat(1, x, x1);
size(x)
y = cat(1,y, ones(size(R)));
z = cat(1,ones(size(R))+100,y2+100);

% Plot the surface with RGB color
figure;
%hold on

axis equal;   % Make the axes scales match
 
surf(x, y, z,  'CData', C,'edgecolor', 'none');
%surf(x1, ones(size(R)), y1,  'CData', C,'edgecolor', 'none');
% Adjust the view
%view(3);

% Add labels and title
xlabel('X-axis');
ylabel('Y-axis');
zlabel('Z-axis');
title('3D Surface Plot of RGB Image');
%hold off
% Optional: Adjust the axis
%axis tight;