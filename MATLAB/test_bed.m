close all;
home;

%% define a "Bullet"
bullet_dia = 0.224;
Bullet = Bullet(bullet_dia);

%% define a "Target"
image_name = '_sim_bullet_holes_rotated.jpg';
%image_name = 'test1.jpg';
target_style_num = 1;
Target = Target(image_name,target_style_num);

%% define a "Group"
Group = Group(Target,Bullet);

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