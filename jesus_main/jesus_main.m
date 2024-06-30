% load a image
image = imread('metro-station.png');
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
px_vertices2d = select_points(image)
f=focal_length(px_vertices2d)
% #########################################################
% STEP2  calcule Vertices in 3D using camera focal length
[px_h, px_w, c] = size(image);
% invert "y" pixel s
vertices2d(:, 1) = px_vertices2d(:, 1);
vertices2d(:, 2) = (px_h - px_vertices2d(:, 2) + 1);

vertices3d = vertices3D(vertices2d, f);

% invert "y" pixel 
%vertices2d(:, 1) = px_points_coord(:, 1) / px_w;
%vertices2d(:, 2) = (px_h - px_vertices2d(:, 2) + 1)/ px_w;

%{ 
plot  points
figure
scatter3(vertices3d(:,1), vertices3d(:,2), vertices3d(:,3))
for i=1:13
    c=num2str(i);
    c=[' ',c];
    text(vertices3d(i,1), vertices3d(i,2),vertices3d(i,3),c)
end
xlabel('X')
ylabel('Y')
zlabel('Z')
%}
% #########################################################
% STEP 2 save all pixel coordinate into a new matrix (px_x, px_y, rgb values)
px_coord2d = zeros(px_h*px_w, 5);


for i=1:px_h
    for j=1:px_w
        px_coord2d(j+(i-1)*px_w,1)=j;
        px_coord2d(j+(i-1)*px_w,2)=i;
        px_coord2d(j+(i-1)*px_w,3:5)=image(i,j,:);
    end
end


% invert "y" pixel 
px_coord2d(:, 2) = px_h - px_coord2d(:, 2) + 1;
% scale coordinates
%px_coord2d(:, 1) =  px_coord2d(:, 1) / px_w;
%px_coord2d(:, 2) =  px_coord2d(:, 2) / px_h;

height  = vertices3d(7,2);
leftx   = vertices3d(1,1);
rightx  = vertices3d(4,1);
coord3d = image2dto3d(px_coord2d, vertices2d,vertices3d,px_h,px_w,f,height,leftx,rightx);
%coord3d_big = zeros( ceil(max(coord3d(:,1))),ceil(max(coord3d(:,2))),ceil(max(coord3d(:,3))));
%coord3d_big(:,1)=coord3d(:,1);
%size(coord3d)
%coord3d_big= fillmissing(coord3d_big, "movmedian", 10);
%size( coord3d_big(coord3d_big~=0))

xx=coord3d(:,1);
yy=coord3d(:,2);
zz=coord3d(:,3);
max(coord3d(:,1))
max(coord3d(:,2))
max(abs(coord3d(:,3)))
vertices3d(1,3)
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

function [coord3d] = image2dto3d(coord2d,corners2d,corners3d,m,n,f,height,leftx,rightx)
    % % input:
    % coord2d: 2d coordinates of all pixels  
    % corners2d: 2d coordinates of corners points 
    % corners3d: 3d coordinates of corners points 
    % m,n: size of image
    % f:focal length 
    % height: ceil y coordinate 
    % leftx: left wall x coordinate
    % rightx: right  wall x coordinate
    % output:
    % coord3: 3d coordinates of all pixels  
    % %
    coord2d(:,1)=coord2d(:,1);%/n;
    coord2d(:,2)=coord2d(:,2);%/m;
    
    
    vp=corners3d(13,:);
    t1=corners2d(1,:)-vp(1:2);
    t2=corners2d(2,:)-vp(1:2);
    t7=corners2d(7,:)-vp(1:2);
    t8=corners2d(8,:)-vp(1:2);
    is_bottom__plane_2= @(point2d) (point2d(2) <= t1(2)) && (point2d(2) <= point2d(1)*t1(2)/t1(1)) && (point2d(2) <= point2d(1)*t2(2)/t2(1));
    is_right_plane_2= @(point2d) (point2d(1) >= t2(1)) && (point2d(2) <= point2d(1)*t8(2)/t8(1)) && (point2d(2)>= point2d(1)*t2(2)/t2(1));
    is_top_plane_2= @(point2d) (point2d(2)>=t8(2)) && (point2d(2) >= point2d(1)*t8(2)/t8(1)) && (point2d(2)>=point2d(1) * t7(2)/t7(1));
    is_left_plane_2=@(point2d) (point2d(1) <= t7(1)) && (point2d(2)<=point2d(1) *t7(2)/t7(1)) && (point2d(2)>=point2d(1)*t1(2)/t1(1) );
    is_center_plane_2 = @(point2d)  (point2d(1)<=t2(1)) && (point2d(1) >=t1(1)) && (point2d(2)<=t7(2)) && (point2d(2) >=t1(2));
    
    length=size(coord2d,1);
    coord3d=zeros(length,6);

    for i=1:length
        point2d=coord2d(i,1:2);
        coord3d(i,4:6)=coord2d(i,3:5);
        if is_bottom__plane_2(point2d-vp(1:2))
            coord3d(i,2)=0;
            coord3d(i,3)=-vp(2)/(vp(2)-point2d(2))*f;
            coord3d(i,1)=-coord3d(i,3)/f*(point2d(1)-vp(1))+vp(1);
        elseif is_top_plane_2(point2d-vp(1:2))
            coord3d(i,2)=height;
            coord3d(i,3)=-(vp(2)-height)/(vp(2)-point2d(2))*f;
            coord3d(i,1)=-coord3d(i,3)/f*(point2d(1)-vp(1))+vp(1); 
        elseif is_left_plane_2(point2d-vp(1:2))
            coord3d(i,1)=leftx;
            coord3d(i,3)=-(vp(1)-leftx)/(vp(1)-point2d(1))*f;
            coord3d(i,2)=-coord3d(i,3)/f*(point2d(2)-vp(2))+vp(2);
        elseif is_right_plane_2(point2d-vp(1:2))
            coord3d(i,1)=rightx;
            coord3d(i,3)=-(vp(1)-rightx)/(vp(1)-point2d(1))*f;
            coord3d(i,2)=-coord3d(i,3)/f*(point2d(2)-vp(2))+vp(2);
        elseif is_center_plane_2(point2d-vp(1:2))
            coord3d(i,3)=vp(3);
            coord3d(i,2)=-coord3d(i,3)/f*(point2d(2)-vp(2))+vp(2);
            coord3d(i,1)=-coord3d(i,3)/f*(point2d(1)-vp(1))+vp(1);

        
        end
    end
end
    