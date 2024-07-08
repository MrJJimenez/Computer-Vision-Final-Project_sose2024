function new_img = create_new_img(pixels3d, vpx, vpy, f, R, T, h, w)
    
    pc_center=mean(pixels3d,1);
    offset=-pc_center(1:3);

    pixels3d_centered=pixels3d(:,1:3)'+offset';
    pixels3d_transformed=R*pixels3d_centered+T-offset';
    pixels3d_transformed = pixels3d_transformed';

   
    new_img=NaN(h,w,3);
    for i=1:size(pixels3d,1)
        % Estimate X 2d coordinate
        idx2= int32(round(-f/pixels3d_transformed(i,3)*(pixels3d_transformed(i,1)-vpx)+vpx));
        % Estimate Y 2d coordinate and also invert so match for the new image
        idx1= int32(-round(-f/pixels3d_transformed(i,3)*(pixels3d_transformed(i,2)-vpy)+vpy)+h+1);

        if idx1<=h &&idx2<=w &&idx1>=1 && idx2>=1
      
            new_img(idx1,idx2,1:3)=pixels3d(i,4:6);
        
        end
      
    end
    new_img=new_img(:,:,1:3);
    new_img=fillmissing(new_img,'movmedian',5);
    new_img=uint8(new_img);

end