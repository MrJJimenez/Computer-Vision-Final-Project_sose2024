% Load and display the image
clc
clear all
close all
img = imread('oil-painting.png');
imshow(img);

% Assume you have the coordinates of the vanishing point
[vpx, vpy] = getpts;
[x1, y1]=getpts;
[x2, y2]=getpts;
[x3, y3]=getpts;
[x4, y4]=getpts;
x=[x1,x2,x3,x4];
y=[y1,y2,y3,y4];
% Define the main lines of the image
lines = [vpx, vpy, x1, y1; % Line 1
         vpx, vpy, x2, y2; % Line 2
         vpx, vpy, x3, y3; % Line 1
         vpx, vpy, x4, y4
        ];
% Draw the lines
% Draw the lines
hold on;
for i = 1:size(lines, 1)
    % Calculate the direction of the line
    dx = lines(i, 3) - lines(i, 1);
    dy = lines(i, 4) - lines(i, 2);
    
    % Extend the line in the same direction
    ex = lines(i, 3) + dx * 10000;
    ey = lines(i, 4) + dy * 10000;
    
    plot([lines(i, 1), ex], [lines(i, 2), ey], 'r-');
end

% Plot the square
plot([x1, x2, x3, x4, x1], [y1, y2, y3, y4, y1], 'b-');


% Display the plot
hold off;

function [vertices,grad] = getVertices(vpx,vpy,x,y,h,w)
     
    vertices=zeros(12,2);
    grad=zeros(4,1);
    grad(1)=(y(1)-vpy)/(x(1)-vpx);
    grad(2)=(y(2)-vpy)/(x(2)-vpx);
    grad(3)=(y(3)-vpy)/(x(3)-vpx);
    grad(4)=(y(4)-vpy)/(x(4)-vpx);
    
    vertices(1,1)=x(1);
    vertices(1,2)=y(1);

    vertices(2,1)=x(2);
    vertices(2,2)=y(2);
    
    vertices(7,1)=x(3);
    vertices(7,2)=y(3);

    vertices(8,1)=x(4);
    vertices(8,2)=y(4);
    
    vertices(3,1)=(h-vpy+vpx*grad(1))/grad(1);
    vertices(3,2)=h;

    vertices(4,1)=(h-vpy+vpx*grad(2))/grad(2);
    vertices(4,2)=h;

    vertices(5,1)=1;
    vertices(5,2)=grad(1)+vpy-vpx*grad(1); 

    vertices(6,1)=w;
    vertices(6,2)=grad(2)*w+vpy-vpx*grad(2); 
        
    vertices(9,1)=(1-vpy+vpx*grad(3))/grad(3);
    vertices(9,2)=1;

    vertices(10,1)=(1-vpy+vpx*grad(4))/grad(4);
    vertices(10,2)=1;

    vertices(11,1)=1;
    vertices(11,2)=grad(3)+vpy-vpx*grad(3);

    vertices(12,1)=w;
    vertices(12,2)=grad(4)*w+vpy-vpx*grad(4);
end

[vertices2D ,grad]=getVertices(vpx,vpy,x,y,size(img,1),size(img,2))

function vertices3D = convertVert3D(vpx,vpy,vertices,f)
    l=12;
    vertices3D=ones(l,3);
    view_x=vpx;
    view_y=vpy;
    view_z=0;

    for i=1:6
        g=(-view_y)/(vertices(i,2)-view_y);
        vertices3D(i,1)=g*(vertices(i,1)-view_x)+view_x;
        vertices3D(i,3)=g*(-f-view_z)+view_z;
        vertices3D(i,2)=0;
    
    end

    
    H=-(vertices(8,2)-vertices(2,2))*vertices3D(2,3)/f;
    
    vertices3D(7,1)=vertices3D(1,1);
    vertices3D(7,2)=H;
    vertices3D(7,3)=vertices3D(1,3);
    
    vertices3D(8,1)=vertices3D(2,1);
    vertices3D(8,2)=H;
    vertices3D(8,3)=vertices3D(2,3);

    for i=9:12
        g=(H-view_y)/(vertices(i,2)-view_y);
        vertices3D(i,1)=g*(vertices(i,1)-view_x)+view_x;
        vertices3D(i,3)=g*(-f-view_z)+view_z;
        vertices3D(i,2)=H;
    end

end


f=500;
vertices3D=convertVert3D(vpx,vpy,vertices2D,f);
vertices3D(:,1);
img(1,1,:);


function pixels3D = pixels2Dto3D(x1,x2,y3,img,grad,vpx,vpy,vertices,vertices3D,f)

m=size(img,1);
n=size(img,2);
x=ceil(max(abs(vertices3D(:,1))));
y=ceil(max(abs(vertices3D(:,2))));
z=ceil(max(abs(vertices3D(:,3))));
val=max([x,y,z]);

pixels3D=zeros(m*n,6);
leftx=vertices(1,1);
rightx=vertices(2,1);
H=vertices(1,2)-vertices(7,2);
vpz=vertices3D(1,3);
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


pixels=pixels2Dto3D(img,grad,vpx,vpy,vertices2D,vertices3D,f);

xx=pixels(:,1);
yy=pixels(:,2);
zz=pixels(:,3);
color=pixels(:,4:6)/255;

pcshow([xx yy zz],color)
set(gcf,'color','[0.94,0.94,0.94]');
set(gca,'color','[0.94,0.94,0.94]');
view([20, 80]);
