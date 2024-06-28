% load a image
image = imread('cocina.JPG');

rectangle_coordinate = drawRectangleAndReturnCoordinates(image)


function coords = drawRectangleAndReturnCoordinates(image)
    % Read the image
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

    rec_p1  = [x1, y1]; % Top left
    rec_p2 = [x2, y1]; % Top right
    rec_p3  = [x2, y2]; % Bottom right
    rec_p4 = [x1, y2]; % Bottom left

    % Return the coordinates
    coords = [x1, y1; x2, y2];
    
    % Annotate the coordinates on the image
    hold on;
    plot([x1, x2], [y1, y1], 'r', 'LineWidth', 2); % Top edge
    plot([x1, x2], [y2, y2], 'r', 'LineWidth', 2); % Bottom edge
    plot([x1, x1], [y1, y2], 'r', 'LineWidth', 2); % Left edge
    plot([x2, x2], [y1, y2], 'r', 'LineWidth', 2); % Right edge

    plot(rec_p1(1), rec_p1(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 1
    text(rec_p1(1), rec_p1(2), '1','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');
    
    plot(rec_p2(1), rec_p2(2), '.', 'MarkerSize', 15, 'LineWidth', 5,'Color', 'green'); % Point 2
    text(rec_p2(1), rec_p2(2), '2','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    plot(rec_p3(1), rec_p3(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 3
    text(rec_p3(1), rec_p3(2), '3','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');

    plot(rec_p4(1), rec_p4(2), '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green'); % Point 4
    text(rec_p4(1), rec_p4(2), '4','Color', 'green', 'FontSize', 30,'FontWeight', 'bold');
    
    plot(1, 50, '.', 'MarkerSize', 15, 'LineWidth', 5, 'Color', 'green');

    hold off;
    


    % Get vanish point vp
    % Wait for the user to click on the image,
    vpoint = ginput(1);
    
    % Round the coordinates to the nearest integer (pixel coordinates)
    vpoint = round(vpoint);
    

    % Annotate the point on the image
    hold on;
    plot(vpoint(1), vpoint(2), '.', 'MarkerSize', 30, 'LineWidth', 5, 'Color', 'green'); % Plot the vanish point
    text(vpoint(1), vpoint(2), 'vp', 'Color', 'green', 'FontSize', 30, 'FontWeight', 'bold'); % Display vanish point
    hold off;
    intersections = findLineEdgeIntersections(image, vpoint, rec_p4);
end