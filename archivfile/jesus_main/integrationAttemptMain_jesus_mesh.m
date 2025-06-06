
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


% Save the combined mask
imwrite(combinedMask, 'combined_mask.png');

% Extract the foreground objects using the combined mask
foreground = bsxfun(@times, image, cast(combinedMask, 'like', image));

% Save the extracted foreground objects
imwrite(foreground, 'extracted_foreground.png');

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
figure;
imshow(filledBackground);
title('Filled Background');



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
[px_vertices2d, grad] = select_points(image);

% focal length estimation
f=focal_length(px_vertices2d)
% #########################################################
% calcule Vertices in 3D using camera focal length
[px_h, px_w, c] = size(image);
% invert "y" pixel s
vertices2d(:, 1) = px_vertices2d(:, 1);
vertices2d(:, 2) = (px_h - px_vertices2d(:, 2) + 1);

vertices3d = vertices3D(vertices2d, f);

% #########################################################
% save all pixel coordinate into a new matrix (px_x, px_y, rgb values)
px_coord2d = zeros(px_h*px_w, 5);



for i=1:px_h
    for j=1:px_w
        px_coord2d(j+(i-1)*px_w,1)=j;
        px_coord2d(j+(i-1)*px_w,2)=i;
        px_coord2d(j+(i-1)*px_w,3:5)=image(i,j,:);
    end
end

% save all foregroung pixel in a matirx (px_x, px_y, rgb values)
foreground_size =  size(combinedMask(combinedMask(:,:) == 1), 1)
size(image)
size(foreground)
px_foreground_coord2d = zeros(foreground_size, 5);

itemp = 0;

for i=1:px_h
    for j=1:px_w
        if combinedMask(i,j)== 1 
            itemp = itemp+1;
           
            px_foreground_coord2d(itemp,1)=j;
            px_foreground_coord2d(itemp,2)=i;
            px_foreground_coord2d(itemp,3:5)=foreground(i,j,:);
        end
    end
end



itemp = itemp
% invert "y" pixel 
px_coord2d(:, 2) = px_h - px_coord2d(:, 2) + 1;
px_foreground_coord2d(:, 2) = px_h - px_foreground_coord2d(:, 2) + 1;
% scale coordinates
%px_coord2d(:, 1) =  px_coord2d(:, 1) / px_w;
%px_coord2d(:, 2) =  px_coord2d(:, 2) / px_h;

height  = vertices3d(7,2);
leftx   = vertices3d(1,1);
rightx  = vertices3d(4,1);

%coord3d = image2dto3d(px_coord2d, vertices2d,vertices3d,f,height,leftx,rightx,px_h, px_w, px_foreground_coord2d);

vpx = vertices2d(13,1);
vpy = vertices2d(13,2);

vertices = vertices2d;



coord3d = pixels2Dto3D(image,grad,vpx,vpy,vertices2d,vertices3d,f);

xx=coord3d(:,1);
yy=coord3d(:,2);
zz=coord3d(:,3);

color=coord3d(:,4:6)/255;

pcshow([xx yy zz],color,'VerticalAxisDir','Down')
%set(gcf,'color','[0.94,0.94,0.94]');
%set(gca,'color','[0.94,0.94,0.94]');
view([0, 0]);

function f = focal_length(px_coord2d)

    len1=sqrt( (px_coord2d(13,1)-px_coord2d(5,1))^2 + (px_coord2d(13,2)-px_coord2d(5,2))^2)
    len2=sqrt( (px_coord2d(13,1)-px_coord2d(4,1))^2 + (px_coord2d(13,2)-px_coord2d(4,2))^2)
    len3=sqrt( (px_coord2d(13,1)-px_coord2d(11,1))^2 + (px_coord2d(13,2)-px_coord2d(11,2))^2)
    len4= sqrt( (px_coord2d(13,1)-px_coord2d(10,1))^2 + (px_coord2d(13,2)-px_coord2d(10,2))^2)

    f =  max([len1, len2, len3, len4]);
 

end


function [coords, grad] = select_points(image)
    % this function take as input a image 
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


    % gradient for the foreground
    for i =1:4
        grad(i) = (rec_vertices_px(i,2)-y_vp)/(rec_vertices_px(i,1)-x_vp);
    end
    

    vertices2D_px = zeros(12,2);
    vertices2D_px(1,:) = p1;
    vertices2D_px(2,:) = p2;
    vertices2D_px(8,:) = p8;
    vertices2D_px(7,:) = p7;

    vertices2D_px(3,:)  = [(y_max-y_vp)/grad(1) + x_vp;       y_max];
    vertices2D_px(5,:)  = [1;                                     (1-x_vp)*grad(1) + y_vp];
    vertices2D_px(4,:)  = [(y_max-y_vp)/grad(2) + x_vp;       y_max];
    vertices2D_px(6,:)  = [x_max;                                 (x_max-x_vp)*grad(2) + y_vp];
    vertices2D_px(10,:) = [(1-y_vp)/grad(3) + x_vp;           1];
    vertices2D_px(12,:) = [x_max;                                 (x_max-x_vp)*grad(3) + y_vp];
    vertices2D_px(9,:)  = [(1-y_vp)/grad(4) + x_vp;           1];
    vertices2D_px(11,:) = [1;                                     (1-x_vp)*grad(4) + y_vp];

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
    % this convert the 2D vertices to 3D
    % create vertices3d where new coordinates will be saved
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

function [coord3d] = image2dto3d(coord2d,corners2d,corners3d,f,height,leftx,rightx, px_heigth, px_width, foreground_coord2d)
    % % input:
    % coord2d: 2d coordinates of all pixels  
    % corners2d: 2d coordinates of corners points 
    % corners3d: 3d coordinates of corners points 
    % f:focal length 
    % height: ceil y coordinate 
    % leftx: left wall x coordinate
    % rightx: right  wall x coordinate
    % output:
    % coord3: 3d coordinates of all pixels  
    % %
    %coord2d(:,1)=coord2d(:,1);%;
    %coord2d(:,2)=coord2d(:,2);%;
    
    
    vp=corners3d(13,:);
    t1=corners2d(1,:)-vp(1:2);
    t2=corners2d(2,:)-vp(1:2);
    t7=corners2d(7,:)-vp(1:2);
    t8=corners2d(8,:)-vp(1:2);
    is_bottom__plane = @(point2d) (point2d(2) <= t1(2)) && (point2d(2) <= point2d(1)*t1(2)/t1(1)) && (point2d(2) <= point2d(1)*t2(2)/t2(1));
    is_right_plane = @(point2d) (point2d(1) >= t2(1)) && (point2d(2) <= point2d(1)*t8(2)/t8(1)) && (point2d(2)>= point2d(1)*t2(2)/t2(1));
    is_top_plane = @(point2d) (point2d(2)>=t8(2)) && (point2d(2) >= point2d(1)*t8(2)/t8(1)) && (point2d(2)>=point2d(1) * t7(2)/t7(1));
    is_left_plane = @(point2d) (point2d(1) <= t7(1)) && (point2d(2)<=point2d(1) *t7(2)/t7(1)) && (point2d(2)>=point2d(1)*t1(2)/t1(1) );
    is_center_plane = @(point2d)  (point2d(1)<=t2(1)) && (point2d(1) >=t1(1)) && (point2d(2)<=t7(2)) && (point2d(2) >=t1(2));
    
    length=size(coord2d,1);
    length_foreground=size(foreground_coord2d,1);
    coord3d=zeros(length+length_foreground,6);

    for i=1:length
        point2d=coord2d(i,1:2);
        coord3d(i,4:6)=coord2d(i,3:5);
        if is_bottom__plane(point2d-vp(1:2))
            coord3d(i,2)=0;
            coord3d(i,3)=-vp(2)/(vp(2)-point2d(2))*f;
            coord3d(i,1)=-coord3d(i,3)/f*(point2d(1)-vp(1))+vp(1);
        elseif is_top_plane(point2d-vp(1:2))
            coord3d(i,2)=height;
            coord3d(i,3)=-(vp(2)-height)/(vp(2)-point2d(2))*f;
            coord3d(i,1)=-coord3d(i,3)/f*(point2d(1)-vp(1))+vp(1); 
        elseif is_left_plane(point2d-vp(1:2))
            coord3d(i,1)=leftx;
            coord3d(i,3)=-(vp(1)-leftx)/(vp(1)-point2d(1))*f;
            coord3d(i,2)=-coord3d(i,3)/f*(point2d(2)-vp(2))+vp(2);
        elseif is_right_plane(point2d-vp(1:2))
            coord3d(i,1)=rightx;
            coord3d(i,3)=-(vp(1)-rightx)/(vp(1)-point2d(1))*f;
            coord3d(i,2)=-coord3d(i,3)/f*(point2d(2)-vp(2))+vp(2);
        elseif is_center_plane(point2d-vp(1:2))
            coord3d(i,3)= vp(3); 
            coord3d(i,2)=-vp(3)/f*(point2d(2)-vp(2))+vp(2);
            coord3d(i,1)=-vp(3)/f*(point2d(1)-vp(1))+vp(1); 

        
        end
    end
    
    fz_temp = 0;
    %[fore_x_min, fore_x_min] = [min(foreground_coord2d(:,1)), max(foreground_coord2d(:,1))];
    %[fore_y_min, fore_y_min] = [min(foreground_coord2d(:,1)), max(foreground_coord2d(:,1))];

     % foreground deep estimation
    % Calculate points to estimate the object depth
    
    fore_x = min(foreground_coord2d(:,1))

    % select x coordinate if object is near to the right side
    if px_width - max(foreground_coord2d(:,1)) < fore_x
        fore_x = max(foreground_coord2d(:,1))
    end
    fore_y = floor((min(foreground_coord2d(:,2))+min(foreground_coord2d(:,2)))/2)
    
    point2d = [fore_x , fore_y]

    if is_bottom__plane(point2d-vp(1:2))
        fz_temp=-vp(2)/(vp(2)-point2d(2))*f;
    
    elseif is_top_plane(point2d-vp(1:2))
        fz_temp=-(vp(2)-height)/(vp(2)-point2d(2))*f;
        
    elseif is_left_plane(point2d-vp(1:2))
        fz_temp=-(vp(1)-leftx)/(vp(1)-point2d(1))*f;
    elseif is_right_plane(point2d-vp(1:2))
        fz_temp= -(vp(1)-rightx)/(vp(1)-point2d(1))*f;
    elseif is_center_plane(point2d-vp(1:2))
        fz_temp=vp(3); 
    end
    % Calculate foregound z
    vp(3)
    %fz_temp =-1000
    z_for = fz_temp
    
    point2d=foreground_coord2d(:,1:2);
    
    % Convert foreground 2d coordinate to 3d
    % Copy all rgb value to the last part of coord3d
    coord3d(1+length:end,4:6)=foreground_coord2d(:,3:5);
    
    % Convert foreground 2d coordinate to 3d
    coord3d(1+length:end,3)= z_for; 
    coord3d(1+length:end,2)=-z_for/f*(point2d(:,2)-vp(2))+vp(2);
    coord3d(1+length:end,1)=-z_for/f*(point2d(:,1)-vp(1))+vp(1); 
    
end

function pixels3D = pixels2Dto3D(img,grad,vpx,vpy,vertices,vertices3d,f)
    %p1 = [x1, y2]; % Bottom left
    %p2  = [x2, y2]; % Bottom right
    %p8 = [x2, y1]; % Top right
    %p7  = [x1, y1]; % Top left

    %[x1, y1]=getpts;
    %[x2, y2]=getpts;
    %[x3, y3]=getpts;
    %[x4, y4]=getpts;

    x1 = vertices(1,1)
    x2 = vertices(2,1)
    y3 = vertices(7,2)

    m=size(img,1);
    n=size(img,2);
    x=ceil(max(abs(vertices3d(:,1))));
    y=ceil(max(abs(vertices3d(:,2))));
    z=ceil(max(abs(vertices3d(:,3))));
    val=max([x,y,z]);
    
    pixels3D=zeros(m*n,6);
    leftx=vertices(1,1);
    rightx=vertices(2,1);
    H=vertices(1,2)-vertices(7,2);
    vpz=vertices3d(1,3);
    b=zeros(4,1);
    h=vpz/f*(y3-vpy)+vpy;
    vertices(7,2)
    b(1)=vpy-vpx*grad(1);
    b(2)=vpy-vpx*grad(2);
    b(3)=vpy-vpx*grad(3);
    b(4)=vpy-vpx*grad(4);
    
    
    for i=1:size(img,1)
        for j=1:size(img,2)
            
            idx=i+n*(j-1);
            %left wall
            if (j<=leftx) && (i>= grad(3)*j+b(3)) && (i<= grad(1)*j+b(1))
                nl=-vpz/f*(x1-vpx)+vpx;
                g=-(vpx-nl)/(vpx-j);
                pixels3D(idx,1)=nl;
                pixels3D(idx,3)=g*f;
                %y=vpz/f*(i-vpy)+vpy;
                %maxim=vpz/f*(0-vpy);
                %minim=vpz/f*(size(img,1)-vpy);
                %pixels3D(idx,2)=rescale(y, 0, h, 'InputMin', minim, 'InputMax', maxim);
                pixels3D(idx,2)=g*(i-vpy)+vpy;
    
    
            %back wall
            elseif (j>=leftx) && (j<=rightx) && (i<=vertices(1,2)) && (i>= vertices(7,2))
                pixels3D(idx,3)=vpz;
                pixels3D(idx,2)=vpz/f*(i-vpy)+vpy;
                pixels3D(idx,1)=-vpz/f*(j-vpx)+vpx;
    
    
            %ceiling
            elseif (i<= vertices(7,2)) & (j >=(i-b(3))/grad(3)) & (j<=(i-b(4))/grad(4))
               h=vpz/f*(y3-vpy)+vpy;
               pixels3D(idx,2)=h;
               %pixels3D(idx,3)=-(vpy-H)/(vpy-i)*f;
               %pixels3D(idx,1)=-vpz/f*(j-vpx)+vpx; 
               g=(h-vpy)/(i-vpy);
               pixels3D(idx,1)=-g*(j-vpx)+vpx;
               pixels3D(idx,3)=g*f;
               
    
            
            %right wall
            elseif (j>=rightx) && (i>= grad(4)*j+b(4)) && (i<= grad(2)*j+b(2))
                nr=-vpz/f*(x2-vpx)+vpx;
                g=-(vpx-nr)/(vpx-j);
                pixels3D(idx,1)=nr;
                pixels3D(idx,3)=g*f;
                pixels3D(idx,2)=g*(i-vpy)+vpy;
    
    
            %floor;
            elseif i>= vertices(1,2) && j >=(i-b(1))/grad(1) && j<=(i-b(2))/grad(2)
                pixels3D(idx,2)=0;
                %pixels3D(idx,3)=-vpy/(vpy-i)*f;
                %pixels3D(idx,1)=-vpz/f*(j-vpx)+vpx;
    
                g=(-vpy)/(i-vpy);
                pixels3D(idx,1)=-g*(j-vpx)+vpx;
                pixels3D(idx,3)=g*f;
    
            end
            
            pixels3D(idx,4:6)=img(i,j,:);
    %
        %
        end
    end

end