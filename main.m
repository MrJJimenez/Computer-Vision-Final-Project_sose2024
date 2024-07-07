
% Let the user select the image file
[filename, pathname] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp', 'Image Files (*.png, *.jpg, *.jpeg, *.bmp)'}, 'Select an Image');
if isequal(filename, 0)
    disp('User selected Cancel');
    return;
else
    imagePath = fullfile(pathname, filename);
end

% Load the image
image = imread(imagePath);

% Display the image
figure;
imshow(image);
title('Original Image');
% Ask the user for the number of foreground objects
%numObjects = input('Enter the number of foreground objects: ');
numObjects = 1;


% Initialize the combined mask
combinedMask = false( size(image, 1), size(image, 2));

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


% Save the combined mask
%imwrite(combinedMask, 'combined_mask.png');

% Extract the foreground objects using the combined mask
foreground = bsxfun(@times, image, cast(combinedMask, 'like', image));

% Save the extracted foreground objects
%imwrite(foreground, 'extracted_foreground.png');

% Display the extracted foreground

% Create the background by removing the foreground objects
background = image;
background(repmat(combinedMask, [1, 1, 3])) = 0;



% Fill the holes in the background using inpaintExemplar
backgroundDouble = im2double(background);
filledBackground = inpaintExemplar(backgroundDouble, combinedMask);

% Save the filled background
imwrite(filledBackground, 'filled_background.png');

% Display the filled background
%figure;
%imshow(filledBackground);
%title('Filled Background');



% Load the filled background image
image = imread('filled_background.png');


f = 300;
% #########################################################
% STEP 1 select points on image and get vertices
% [point 1;
%  point 2;
%  point 3;
%  point 4;
%  point 5;
%  point 6;
%  point 7;
%  point 8;
%  point 9;
%  point 10;
%  point 11;
%  point 12;
%  vanish point
px_vertices2d= select_points(image);

% focal length estimation
f=focal_length(px_vertices2d)
% #########################################################
% calcule Vertices in 3D using camera focal length
[px_h, px_w, c] = size(image);
% invert "y" pixels
vertices2d(:, 1) = px_vertices2d(:, 1);
vertices2d(:, 2) = (px_h - px_vertices2d(:, 2) + 1);

% Estimate 3d vertices or coorners
vertices3d = vertices3D(vertices2d, f);

% Move 2d pixels to the 5 walls
pixels3D = pixels2Dto3D(image, vertices2d,vertices3d,f, foreground, combinedMask);


color=pixels3D(:,4:6)/255;

% Display 3D
pcshow([pixels3D(:,1) pixels3D(:,2) pixels3D(:,3)],color,'VerticalAxisDir','Down')
%set(gcf,'color','[0.94,0.94,0.94]');
%set(gca,'color','[0.94,0.94,0.94]');
view([0, 0]);

function f = focal_length(px_coord2d)
    % This function estimate the camera focal length base on the size and position of the selected rectangle
    % select the maximal distance from the rectangle coorner to the image side
    len1=sqrt( (px_coord2d(13,1)-px_coord2d(5,1))^2 + (px_coord2d(13,2)-px_coord2d(5,2))^2)
    len2=sqrt( (px_coord2d(13,1)-px_coord2d(4,1))^2 + (px_coord2d(13,2)-px_coord2d(4,2))^2)
    len3=sqrt( (px_coord2d(13,1)-px_coord2d(11,1))^2 + (px_coord2d(13,2)-px_coord2d(11,2))^2)
    len4= sqrt( (px_coord2d(13,1)-px_coord2d(10,1))^2 + (px_coord2d(13,2)-px_coord2d(10,2))^2)

    f =  max([len1, len2, len3, len4]);
 

end


function coords = select_points(image)
    % This function take as input a image and estimate estimate the 12 points described in the paper. 
    % The vertices are in the image coordinate system
    % return
    % [point 1;
    %  point 2;
    %  point 3;
    %  point 4;
    %  point 5;
    %  point 6;
    %  point 7;
    %  point 8;
    %  point 9;
    %  point 10;
    %  point 11;
    %  point 12;
    %  vanish point]

    % copy the image
    img = image;
    
    % Display the image
    figure;
    imshow(img);
    title('Draw a rectangle on the image');
    
    % Use imrect to draw a rectangle
    h = imrect;
    
    % Wait for the user to double-click on the rectangle to finalize it
    position = wait(h);

 
    % Extract rectangle coordinates
    x1 = position(1);
    y1 = position(2);
    x2 = x1 + position(3);
    y2 = y1 + position(4);
    
    p1 = [x1, y2]; % Bottom left
    p2  = [x2, y2]; % Bottom right
    p8 = [x2, y1]; % Top right
    p7  = [x1, y1]; % Top left

    % Get vanish point vp
    % Wait for the user to click on the image,
    vpoint = ginput(1);
    
    % Round the coordinates to the nearest integer (pixel coordinates)
    vpoint = round(vpoint);

    [img_heigth,img_width, p]=size(img);
    x_max = img_width;
    y_max = img_heigth;

    x_vp = vpoint(1);
    y_vp = vpoint(2);

    rec_vertices_px(1,:)= p1; %1
    rec_vertices_px(2,:) = p2; %2
    rec_vertices_px(3,:) = p8; %8
    rec_vertices_px(4,:) = p7; %7


    % Gradient for the foreground
    
    grad(1) = (rec_vertices_px(1,2)-y_vp)/(rec_vertices_px(1,1)-x_vp);
    grad(2) = (rec_vertices_px(2,2)-y_vp)/(rec_vertices_px(2,1)-x_vp);
    grad(3) = (rec_vertices_px(4,2)-y_vp)/(rec_vertices_px(4,1)-x_vp);
    grad(4) = (rec_vertices_px(3,2)-y_vp)/(rec_vertices_px(3,1)-x_vp);

    vertices2D_px = zeros(12,2);
    vertices2D_px(1,:) = p1;
    vertices2D_px(2,:) = p2;
    vertices2D_px(8,:) = p8;
    vertices2D_px(7,:) = p7;

    vertices2D_px(3,:)  = [(y_max-y_vp)/grad(1) + x_vp;       y_max];
    vertices2D_px(5,:)  = [1;                                     (1-x_vp)*grad(1) + y_vp];
    vertices2D_px(4,:)  = [(y_max-y_vp)/grad(2) + x_vp;       y_max];
    vertices2D_px(6,:)  = [x_max;                                 (x_max-x_vp)*grad(2) + y_vp];
    vertices2D_px(10,:) = [(1-y_vp)/grad(4) + x_vp;           1];
    vertices2D_px(12,:) = [x_max;                                 (x_max-x_vp)*grad(4) + y_vp];
    vertices2D_px(9,:)  = [(1-y_vp)/grad(3) + x_vp;           1];
    vertices2D_px(11,:) = [1;                                     (1-x_vp)*grad(3) + y_vp];

    hold on;
    for i = 1:12
        plot([vertices2D_px(i,1),x_vp],[vertices2D_px(i,2),y_vp],'r-','lineWidth',3)
        plot(vertices2D_px(i,1), vertices2D_px(i,2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 2
        text(vertices2D_px(i,1),vertices2D_px(i,2),num2str(i),'Color', 'green', 'FontSize', 30,'FontWeight', 'bold')
    end
    hold off;
  
    % Return coordinates
    coords = [vertices2D_px; vpoint];
    
end
function vertices3d = vertices3D(vertices2d, f)
    % This function convert the 2D vertices to 3D

    % Create vertices3d where new coordinates will be saved
    vertices3d = ones(size(vertices2d, 1), 3);
    view_x = vertices2d(13,1);
    view_y = vertices2d(13,2);
    view_z = 0;

    for i=1:6
        g                = -view_y / (vertices2d(i,2) - view_y);
        vertices3d(i,1) = g * (vertices2d(i,1) - view_x) + view_x;
        vertices3d(i,3) = g * (-f - view_z) + view_z;
        vertices3d(i,2) = 0;
        
    end
    vertices3d(13,1) = view_x;
    vertices3d(13,2) = view_y;
    vertices3d(13,3) = vertices3d(2,3);

    height=-(vertices2d(7,2)-vertices2d(1,2))* vertices3d(1,3)/f;

     vertices3d(7,1) = vertices3d(1,1);
     vertices3d(7,2) = height;
     vertices3d(7,3) = vertices3d(1,3);

     vertices3d(8,1) = vertices3d(2,1);
     vertices3d(8,2) = height;
     vertices3d(8,3) = vertices3d(2,3);

    for i=9:12
        g                = (height - view_y) / (vertices2d(i,2) - view_y);
         vertices3d(i,1) = g * (vertices2d(i,1) - view_x) + view_x;
         vertices3d(i,3) = g * (-f - view_z) + view_z;
         vertices3d(i,2) = height;
    end


    
end

function [pixels3D] = pixels2Dto3D(img, vertices2d,vertices3d,f, foreground, combinedMask)

    % This function map from 2d coordinate  3d coordinates on the 5 estimated walls
    % img: image without fore ground objects
    % vertices2d : vertices 2d fouded above but in new coordinate system where Y is inverted
    % vertices3d: estimated vertices in 3d, vertices 3d define the dimention of our walls
    % f: estimated camera focal length since our coordinate system is not scaled to one real reference the focal length is just a scalar.
    % foreground: image of selected object, size(foreground) == size(img) 
    % combinedMask: mask of selected object

  
    H  = vertices3d(7,2); % height
    leftx   = vertices3d(1,1);
    rightx  = vertices3d(4,1);
    
    vp=vertices3d(13,:);
    vpx= vertices3d(13,1);
    vpy= vertices3d(13,2);

    
    b1=vertices2d(1,:)-vp(1:2); 
    b2=vertices2d(2,:)-vp(1:2); 
    b7=vertices2d(7,:)-vp(1:2); 
    b8=vertices2d(8,:)-vp(1:2); 

    grad(1) = (vertices2d(1,2)-vpy)/(vertices2d(1,1)-vpx); %  
    grad(2) = (vertices2d(2,2)-vpy)/(vertices2d(2,1)-vpx); %  
    grad(3) = (vertices2d(8,2)-vpy)/(vertices2d(8,1)-vpx); %  
    grad(4) = (vertices2d(7,2)-vpy)/(vertices2d(7,1)-vpx); %  
 
    bottom = @(point2d) (point2d(2) <= b1(2)) && (point2d(2) <= point2d(1)*grad(1)) && (point2d(2) <= point2d(1)*grad(2));
    right_wall = @(point2d) (point2d(1) >= b2(1)) && (point2d(2) <= point2d(1)*grad(3)) && (point2d(2)>= point2d(1)*grad(2));
    ceiling = @(point2d) (point2d(2)>=b8(2)) && (point2d(2) >= point2d(1)*grad(3)) && (point2d(2)>=point2d(1) * grad(4));
    left_wall = @(point2d) (point2d(1) <= b7(1)) && (point2d(2) <= point2d(1) * grad(4)) && (point2d(2)>=point2d(1)*grad(1) );
    back_wall = @(point2d)  (point2d(1)<=b2(1)) && (point2d(1) >=b1(1)) && (point2d(2)<=b7(2)) && (point2d(2) >=b1(2));
    
 
   

    foreground_size = size(combinedMask(combinedMask(:,:) == 1), 1)
    [h, w, c] = size(img);
    length = h*w;
    pixels3D = zeros(length+foreground_size,6);

    for i=1:size(img,1)
        for j=1:size(img,2)

            
            point2d = [j,h-i+1];
            idx=j+(i-1)*w;
           
            pixels3D(idx,4:6) = img(i,j,:);
            
            % left wall
            if left_wall(point2d-vp(1:2))
            
                pixels3D(idx,1)=leftx;
                pixels3D(idx,3)=-(vp(1)-leftx)/(vp(1)-point2d(1))*f;
                pixels3D(idx,2)=-pixels3D(idx,3)/f*(point2d(2)-vp(2))+vp(2);
            % back wall
            elseif back_wall(point2d-vp(1:2))
                pixels3D(idx,3)= vp(3); 
                pixels3D(idx,2)=-vp(3)/f*(point2d(2)-vp(2))+vp(2);
                pixels3D(idx,1)=-vp(3)/f*(point2d(1)-vp(1))+vp(1); 
            
            % ceiling
            elseif ceiling(point2d-vp(1:2))
                pixels3D(idx,2)=H;
                pixels3D(idx,3)=-(vp(2)-H)/(vp(2)-point2d(2))*f;
                pixels3D(idx,1)=-pixels3D(idx,3)/f*(point2d(1)-vp(1))+vp(1); 
            
            % right wall
            elseif right_wall(point2d-vp(1:2))
            pixels3D(idx,1)=rightx;
            pixels3D(idx,3)=-(vp(1)-rightx)/(vp(1)-point2d(1))*f;
            pixels3D(idx,2)=-pixels3D(idx,3)/f*(point2d(2)-vp(2))+vp(2);
            
            % floor
            elseif bottom(point2d-vp(1:2))
                pixels3D(idx,2)=0;
                pixels3D(idx,3)=-vp(2)/(vp(2)-point2d(2))*f;
                pixels3D(idx,1)=-pixels3D(idx,3)/f*(point2d(1)-vp(1))+vp(1);
            
            
            end
        end
    end
    
       % save all foregroung pixel in a matirx (px_x, px_y, rgb values)
    

    foreground_coord2d = zeros(foreground_size, 5);

    itemp = 0;

    for i=1:h
        for j=1:w
            if combinedMask(i,j)== 1 
                itemp = itemp+1;
            
                foreground_coord2d(itemp,1)=j;
                foreground_coord2d(itemp,2)=i;
                foreground_coord2d(itemp,3:5)=foreground(i,j,:);
            end
        end
    end
    % invert "y" pixel 

    foreground_coord2d(:, 2) = h - foreground_coord2d(:, 2) + 1;
    % scale coordinates
    

    
    fz_temp = 0;
    %[fore_x_min, fore_x_min] = [min(foreground_coord2d(:,1)), max(foreground_coord2d(:,1))];
    %[fore_y_min, fore_y_min] = [min(foreground_coord2d(:,1)), max(foreground_coord2d(:,1))];

     % foreground deep estimation
    % Calculate points to estimate the object depth
    
    fore_x = min(foreground_coord2d(:,1))

    % select x coordinate if object is near to the right side
    if w- max(foreground_coord2d(:,1)) < fore_x
        fore_x = max(foreground_coord2d(:,1))
    end
    fore_y = floor((min(foreground_coord2d(:,2))+min(foreground_coord2d(:,2)))/2)
    
    point2d = [fore_x , fore_y]

    if bottom(point2d-vp(1:2))
        fz_temp=-vp(2)/(vp(2)-point2d(2))*f;
    
    elseif ceiling(point2d-vp(1:2))
        fz_temp=-(vp(2)-H)/(vp(2)-point2d(2))*f;
        
    elseif left_wall(point2d-vp(1:2))
        fz_temp=-(vp(1)-leftx)/(vp(1)-point2d(1))*f;
    elseif right_wall(point2d-vp(1:2))
        fz_temp= -(vp(1)-rightx)/(vp(1)-point2d(1))*f;
    elseif back_wall(point2d-vp(1:2))
        fz_temp=vp(3); 
    end
    % Calculate foregound z
    
    %fz_temp =-1000
    z_for = fz_temp
    
    point2d=foreground_coord2d(:,1:2);
    
    % Convert foreground 2d coordinate to 3d
    % Copy all rgb value to the last part of pixels3D
    pixels3D(1+length:end,4:6)=foreground_coord2d(:,3:5);
    
    % Convert foreground 2d coordinate to 3d
    pixels3D(1+length:end,3)= z_for; 
    pixels3D(1+length:end,2)=-z_for/f*(point2d(:,2)-vp(2))+vp(2);
    pixels3D(1+length:end,1)=-z_for/f*(point2d(:,1)-vp(1))+vp(1); 
    
end

