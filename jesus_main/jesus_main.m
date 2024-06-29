% load a image
image = imread('cocina.JPG');
size(image)
px_points_coordinate = select_points(image);
px_points_coordinate

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

 
    % Extract the coordinates of the rectangle
    x1 = position(1);
    y1 = position(2);
    x2 = x1 + position(3);
    y2 = y1 + position(4);
    
    p1 = [x1, y2]; % Bottom left
    p2  = [x2, y2]; % Bottom right
    p7  = [x1, y1]; % Top left
    p8 = [x2, y1]; % Top right
    

    
    
    % Annotate the coordinates on the image
    hold on;
    plot([x1, x2], [y1, y1], 'r', 'LineWidth', 2); % Top edge
    plot([x1, x2], [y2, y2], 'r', 'LineWidth', 2); % Bottom edge
    plot([x1, x1], [y1, y2], 'r', 'LineWidth', 2); % Left edge
    plot([x2, x2], [y1, y2], 'r', 'LineWidth', 2); % Right edge

    plot(p1(1), p1(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 1
    text(p1(1), p1(2), '1','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');
    plot(p2(1), p2(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 2
    text(p2(1), p2(2), '2','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    plot(p7(1), p7(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 3
    text(p7(1), p7(2), '7','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');
    
    plot(p8(1), p8(2), '.', 'MarkerSize', 15, 'LineWidth', 5,'Color', 'green'); % Point 4
    text(p8(1), p8(2), '8','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    

    

    % Get vanish point vp
    % Wait for the user to click on the image,
    vpoint = ginput(1);
    
    % Round the coordinates to the nearest integer (pixel coordinates)
    vpoint = round(vpoint);
    

    % plot vanish point on image
    plot(10, 500, '.', 'MarkerSize', 30, 'LineWidth', 5, 'Color', 'green'); % Plot the vanish point
    plot(vpoint(1), vpoint(2), '.', 'MarkerSize', 30, 'LineWidth', 5, 'Color', 'green'); % Plot the vanish point
    text(vpoint(1), vpoint(2), 'vp', 'Color', 'green', 'FontSize', 30, 'FontWeight', 'bold'); % Display vanish point
    
    p3 = findLineEdgeIntersections(image, vpoint, p1);
    plot([vpoint(1), p3(1)], [vpoint(2), p3(2)], 'r-', 'LineWidth', 2, 'Color', 'red'); % Plot the line
    text(p3(1), p3(2), '3','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    p6 = findLineEdgeIntersections(image, vpoint, p2);
    plot([vpoint(1), p6(1)], [vpoint(2), p6(2)], 'r-', 'LineWidth', 2, 'Color', 'red'); % Plot the line
    text(p6(1), p6(2), '6','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    
    p9 = findLineEdgeIntersections(image, vpoint, p7);
    plot([vpoint(1), p9(1)], [vpoint(2), p9(2)], 'r-', 'LineWidth', 2, 'Color', 'red'); % Plot the line
    text(p9(1), p9(2), '9','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    p12 = findLineEdgeIntersections(image, vpoint, p8);
    plot([vpoint(1), p12(1)], [vpoint(2), p12(2)], 'r-', 'LineWidth', 2, 'Color', 'red'); % Plot the line
    text(p12(1), p12 (2), '12','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');
    
    

    
 
    hold off;

    % Return the coordinates
    coords = [vpoint; p1; p2; p7; p8];
end

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
end