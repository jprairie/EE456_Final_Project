clear all;
close all;
home;

image_name = '_sim_bullet_holes.jpg';
%image_name = 'test1.jpg';
target_style_num = 1;
Target_1 = Target(image_name,target_style_num);

figure;
imshow(Target_1.rgb_image);
