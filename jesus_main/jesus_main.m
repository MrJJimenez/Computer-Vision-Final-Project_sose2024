% load a image
image = imread('cocina.JPG');

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
px_vertices2d = select_points(image)

% #########################################################
% STEP 2 transform and scale 2D vertices to new coordinate system 
[px_h, px_w, rgb] = size(image);
% invert "y" pixel 
vertices2d(:, 1) = px_points_coord(:, 1) / px_w;
vertices2d(:, 2) = (px_h - px_vertices2d(:, 2) + 1)/ px_w;

vertices3d = vertices3D(px_vertices2d, 10)
vertices3d(:,1)
figure
scatter3(vertices3d(:,1), vertices3d(:,2), vertices3d(:,3))
for i=1:13
    c=num2str(i);
    c=[' ',c];
    text(vertices3d(i,1),vertices3d(i,2),vertices3d(i,3),c)
end
xlabel('X')
ylabel('Y')
zlabel('Z')


% #########################################################
% STEP 2 save all pixel coordinate into a new matrix (px_x, px_y, rgb values)
%px_coord2d = zeros(px_h*px_w, 5);

%{
% for i=1:px_h
    for j=1:px_w
        px_coord2d(j+(i-1)*px_w,1)=j;
        px_coord2d(j+(i-1)*px_w,2)=i;
        px_coord2d(j+(i-1)*px_w,3:5)=image(i,j,:);
    end
end
%}


% invert "y" pixel 
%px_coord2d(:, 2) = px_h - px_coord2d(:, 2) + 1;
% scale coordinates
%px_coord2d(:, 1) =  px_coord2d(:, 1) / px_w;
%px_coord2d(:, 2) =  px_coord2d(:, 1) / px_h;




function coords = select_points(image)
    % this function take as input a image 
    %return [ vanish point; 
    %         point 1; down left 
    %         point 2: down right
    %         point 7: up left
    %         point 8] up right

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
        gradient(i) = (rec_vertices_px(i,2)-y_vp)/(rec_vertices_px(i,1)-x_vp);
    end

    vertices2D_px = zeros(12,2);
    vertices2D_px(1,:) = p1;
    vertices2D_px(2,:) = p2;
    vertices2D_px(8,:) = p8;
    vertices2D_px(7,:) = p7;

    vertices2D_px(3,:)  = [(y_max-y_vp)/gradient(1) + x_vp;       y_max];
    vertices2D_px(5,:)  = [1;                                     (1-x_vp)*gradient(1) + y_vp];
    vertices2D_px(4,:)  = [(y_max-y_vp)/gradient(2) + x_vp;       y_max];
    vertices2D_px(6,:)  = [x_max;                                 (x_max-x_vp)*gradient(2) + y_vp];
    vertices2D_px(10,:) = [(1-y_vp)/gradient(3) + x_vp;           1];
    vertices2D_px(12,:) = [x_max;                                 (x_max-x_vp)*gradient(3) + y_vp];
    vertices2D_px(9,:)  = [(1-y_vp)/gradient(4) + x_vp;           1];
    vertices2D_px(11,:) = [1;                                     (1-x_vp)*gradient(4) + y_vp];

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

     vertices3d(7,1)= vertices3d(1,1);
     vertices3d(7,2)=height;
     vertices3d(7,3)= vertices3d(1,3);

     vertices3d(8,1)= vertices3d(2,1);
     vertices3d(8,2)=height;
     vertices3d(8,3)= vertices3d(2,3);

    for i=9:12
        g                = (height - view_y) / (vertices2d(i,2) - view_y);
         vertices3d(i,1) = g * (vertices2d(i,1) - view_x) + view_x;
         vertices3d(i,3) = g * (-f - view_z) + view_z;
         vertices3d(i,2) = height;
    end


    
end