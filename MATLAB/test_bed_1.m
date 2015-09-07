clear;
close all;
home;

%% define a "Bullet"
bullet_dia = 0.224;
Bullet = Bullet(bullet_dia);

%% define a "Target"
%image_name = '_target_1.jpg';
image_name = '_target_1_no_holes.jpg';
target_style_num = 1;
Target = Target(image_name,target_style_num);

%% define a "Group"
bullets_per_group = 3;
Group = Group(Target,Bullet,bullets_per_group);

imshow(Target.rgb_image);
hold on;
pause(1)
for i = 1:6
    plot(Target.approx_poa_center_locations.pixels(i,1),...
        Target.approx_poa_center_locations.pixels(i,2),'*g');
    h = rectangle('Position',Group.bounding_boxes(i,:));
    h.EdgeColor = 'green';
    drawnow;
    pause(0.25);
end


for i = 1:6
    name = ['group_' int2str(i)];
    figure;
    imshow(Group.info.(name).rgb_image);
    hold on;
    x = Group.info.(name).poa_center(1);
    y = Group.info.(name).poa_center(2);
    plot(x,y,'*g');
    centroids = cat(1,Group.info.(name).bullet_group_props.Centroid);
    bounding_boxes = cat(1,Group.info.(name).bullet_group_props.BoundingBox);
    plot(centroids(:,1),centroids(:,2),'+r');
    for j = 1:size(bounding_boxes,1)
       h = rectangle('Position',bounding_boxes(j,:));
       h.EdgeColor = 'green';
    end
    
    drawnow;
    pause(0.25);
end
