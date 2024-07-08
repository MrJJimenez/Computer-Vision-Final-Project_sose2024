function new_img = create_new_img(pixels3d, vpx, vpy, f, R, T, h, w)
    
    pc_center=mean(pixels3d,1);
    offset=-pc_center(1:3);

    pixels3d_centered=pixels3d(:,1:3)'+offset';
    pixels3d_transformed=R*pixels3d_centered+T-offset';
    pixels3d_transformed = pixels3d_transformed';

    length=size(pixels3d,1);
    vector2d=zeros(length,5);
    new_img=NaN(h,w,3);
    for i=1:length
        % Estimate X 2d coordinate
        vector2d(i,1)= round(-f/pixels3d_transformed(i,3)*(pixels3d_transformed(i,1)-vpx)+vpx);
        % Estimate Y 2d coordinate and also invert so match for the new image
        vector2d(i,2)= -round(-f/pixels3d_transformed(i,3)*(pixels3d_transformed(i,2)-vpy)+vpy)+h+1;
        vector2d(i,3:5)=pixels3d(i,4:6);
        
        idx1=int32(vector2d(i,2));
        idx2=int32(vector2d(i,1));

        if idx1<=h &&idx2<=w &&idx1>=1 && idx2>=1
      
            new_img(idx1,idx2,1:3)=vector2d(i,3:5);
        
        end
      
    end
    new_img=new_img(:,:,1:3);
    new_img=fillmissing(new_img,'movmedian',5);
    new_img=uint8(new_img);

end