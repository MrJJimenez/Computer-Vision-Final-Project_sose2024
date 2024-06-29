% load a image
image = imread('cocina.JPG');

% #########################################################
% STEP 1 select points on image and get vertices
px_points_coord = select_points(image)

%  point 1; down left 
%  point 2; down right
%  point 7; up left
%  point 8; up right
%  vanish point

% #########################################################
% STEP 2 save all pixel coordinate into a new matrix (px_x, px_y, rgb values)
% for better procesing letter
%{
[px_h, px_w, rgb] = size(image);
px_coord2d = zeros(px_h*px_w, 5);
for i=1:px_h
    for j=1:px_w
        px_coord2d(j+(i-1)*px_w,1)=j;
        px_coord2d(j+(i-1)*px_w,2)=i;
        px_coord2d(j+(i-1)*px_w,3:5)=image(i,j,:);
    end
end

% #########################################################
% STEP 3 transform and scale selected points to new coordinate system 

% invert "y" pixel 
px_coord2d(:, 2) = px_h - px_coord2d(:, 2) + 1;
px_points_coord(:, 2) = px_h - px_points_coord(:, 2) + 1;

% scale coordinates
px_coord2d(:, 1) =  px_coord2d(:, 1) / px_w;
px_coord2d(:, 2) =  px_coord2d(:, 1) / px_h;

px_points_coord(:, 1) = px_points_coord(:, 1) / px_w;
px_points_coord(:, 2) = px_points_coord(:, 1) / px_w;
%}

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

    vertices2D_px(3,:) = [(y_max-y_vp)/gradient(1) + x_vp; y_max];
    vertices2D_px(5,:) = [1; (1-x_vp)*gradient(1) + y_vp];
    vertices2D_px(4,:) = [(y_max-y_vp)/gradient(2) + x_vp; y_max];
    vertices2D_px(6,:) = [x_max; (x_max-x_vp)*gradient(2) + y_vp];
    vertices2D_px(10,:) = [(1-y_vp)/gradient(3) + x_vp; 1];
    vertices2D_px(12,:) = [x_max; (x_max-x_vp)*gradient(3) + y_vp];
    vertices2D_px(9,:) = [(1-y_vp)/gradient(4) + x_vp; 1];
    vertices2D_px(11,:) = [1; (1-x_vp)*gradient(4) + y_vp];

    hold on;
    for i = 1:12
        plot([vertices2D_px(i,1),x_vp],[vertices2D_px(i,2),y_vp],'r-','lineWidth',3)
        plot(vertices2D_px(i,1), vertices2D_px(i,2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 2
        text(vertices2D_px(i,1),vertices2D_px(i,2),num2str(i),'Color', 'green', 'FontSize', 30,'FontWeight', 'bold')
    end
    hold off;
  
    % Return the coordinates
    coords = [vertices2D_px; vpoint];
end
%{
function intersection_point = findLineEdgeIntersections(image, vspoint, point2)
    % this fuction find the intersection point between the line (vanish_point, one rectangle edge) and the image border
    % copy image img
    img = image;
    
    % Get the image dimensions
    [height, width, ~] = size(img);
    
    % Define the edges of the image
    edges = [0, 0, width-1, 0;               % Top edge
             0, height-1, width-1, height-1; % Bottom edge
             0, 0, 0, height-1;              % Left edge
             width-1, 0, width-1, height-1]; % Right edge
    
    % Define the line by the two points
    line = [vspoint; point2];
    
    % Initialize the intersections array
    intersection = [];
    intersection_point = [];
    % Iterate through each edge
    for i = 1:size(edges, 1)
        % Get the intersection point
        intersection = calculateIntersection(line, edges(i, :));
        
        % Check if the intersection point is within the image bounds
        if ~isempty(intersection) && ...
           intersection(1) >= 0 && intersection(1) <= width-1 && ...
           intersection(2) >= 0 && intersection(2) <= height-1
    
            vec1 = [point2(1) - vspoint(1), point2(2) - vspoint(2)];
            vec2 = [intersection(1) - vspoint(1), intersection(2) - vspoint(2)];
            % Normalize the vectors
            normVec1 = vec1 / norm(vec1);
            normVec2 = vec2 / norm(vec2);
            % Calculate the dot product
            dotProduct = dot(normVec1, normVec2);
    
            % Check if the dot product is close to 1
            isSameDirection = abs(dotProduct - 1) < 0.2;

            if isSameDirection
                intersection_point = intersection;
            end
            
        end
    end
    
end

function intersection = calculateIntersection(line, edge)
    % Extract points from the line
    x1 = line(1, 1);
    y1 = line(1, 2);
    x2 = line(2, 1);
    y2 = line(2, 2);
    
    % Extract points from the edge
    x3 = edge(1);
    y3 = edge(2);
    x4 = edge(3);
    y4 = edge(4);
    
    % Calculate the intersection point using line equations
    denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
    if denominator == 0
        intersection = [];
        return;
    end
    px = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / denominator;
    py = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / denominator;
    
    % Round the coordinates to the nearest integer (pixel coordinates)
    intersection = round([px, py]);
end%}