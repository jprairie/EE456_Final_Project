clear Bullet; clear Group; clear Target;
close all;
home;

%% define a "Bullet"
bullet_dia = 0.224;
Bullet = Bullet(bullet_dia);

%% define a "Target"
%image_name = '_sim_bullet_holes_rotated.jpg';
image_name = '_sim_bullet_holes.jpg';
target_style_num = 1;
Target = Target(image_name,target_style_num);

%% define a "Group"
Group = Group(Target,Bullet);

imshow(Target.rgb_image);
hold on;
pause(3)
for i = 1:6
    plot(Target.approx_poa_center_locations.pixels(i,1),...
        Target.approx_poa_center_locations.pixels(i,2),'*g');
    rectangle('Position',Group.bounding_boxes(i,:));
    drawnow;
    pause(0.50);
end

for i = 1:6
    figure;
    imshow(imcrop(Group.Target.rgb_image,Group.bounding_boxes(i,:)));
    drawnow;
    pause(0.5);
end

% 
% %% plot "+" at centers of bullet holes and bullseye
% figure;
% imshow(Target_1.rgb_image);
% hold on;
% plot(Target_1.poa_center_locations(:,1), Target_1.poa_center_locations(:,2),'+r');
% viscircles(Target_1.poa_center_locations,Target_1.poa_center_radii);
% 
% % plot the rectangular areas
% for i = 1:Target_1.num_bulls
%     h = rectangle('Position',Target_1.rect_boundaries(i,:));
%     h.EdgeColor = 'red';
% end