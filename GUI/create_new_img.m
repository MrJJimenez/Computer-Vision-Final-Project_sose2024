function new_img = create_new_img(pixels3d, vpx, vpy, f, R, T, h, w)
    % Calculate the center of the point cloud
    pc_center = mean(pixels3d(:, 1:3), 1);
    offset = -pc_center(1:3);
    
    % Center the point cloud
    pixels3d_centered = pixels3d(:, 1:3)' + offset';
    pixels3d_transformed = R * pixels3d_centered + T - offset';
    pixels3d_transformed = pixels3d_transformed';
    
    % Initialize the new image with NaNs
    new_img = NaN(h, w, 3);
    
    % Project the 3D points to 2D
    X2 = round(-f ./ pixels3d_transformed(:, 3) .* (pixels3d_transformed(:, 1) - vpx) + vpx);
    Y2 = -round(-f ./ pixels3d_transformed(:, 3) .* (pixels3d_transformed(:, 2) - vpy) + vpy) + h + 1;
    
    % Filter valid indices
    valid_idx = (Y2 <= h) & (X2 <= w) & (Y2 >= 1) & (X2 >= 1);
    
    % Assign colors to the new image
    valid_pixels = pixels3d(valid_idx, 4:6);
    X2 = X2(valid_idx);
    Y2 = Y2(valid_idx);
    
    % Convert subscripts to linear indices
    linear_idx = sub2ind([h, w], Y2, X2);
    
    % Assign colors to the corresponding pixels in the new image
    for c = 1:3
        temp_img = new_img(:, :, c);
        temp_img(linear_idx) = valid_pixels(:, c);
        new_img(:, :, c) = temp_img;
    end
    
    % Fill missing values using inpainting
    for c = 1:3
        new_img(:,:,c) = inpaint_nans(new_img(:,:,c));
    end
    
    % Convert to uint8
    new_img = uint8(new_img);
end
