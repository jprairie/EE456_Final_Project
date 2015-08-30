clear all;
close all;
home;

image_name = '_sim_bullet_holes.jpg';
%image_name = 'test1.jpg';
target_style_num = 1;
Target_1 = Target(image_name,target_style_num);

figure;
imshow(Target_1.bw_image);
figure;
imshow(Target_1.gry_image);
figure;
imshow(Target_1.rgb_image);

%% use edge detection to further enhance
Target_1.bw_image = ~bwareaopen(~Target_1.bw_image,5000);
figure;
imshow(Target_1.bw_image);

%% try to find the 0.5 inch poa
[bull_ring_centers, bull_ring_radii] = imfindcircles(Target_1.bw_image,[70 80]...
    ,'ObjectPolarity','dark','Sensitivity',0.95, 'Method','TwoStage');

 %% plot "+" at centers of bullet holes and bullseye

 figure;
 imshow(Target_1.rgb_image);
 hold on;
 plot(bull_ring_centers(:,1), bull_ring_centers(:,2),'+r');
 viscircles(bull_ring_centers,bull_ring_radii);