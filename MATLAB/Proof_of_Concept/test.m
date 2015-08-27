% bullet hole finding proof of concept
close all;
clear all;
home;

%% load and display the original test image
image_name = 'test1.jpg';
RGB = imread(image_name);
RGB_comp = imcomplement(RGB);

%% convert the rgb image to a black and white image
% first, convert to a grayscale image, then perform the b/w conversion on
% the new grayscale image
GRY = rgb2gray(RGB);
level = graythresh(GRY);
BW = im2bw(GRY,level);

%% use edge detection to further enhance
BW_edge = edge(BW,'Canny');
% get rid of small objects
BW_edge = bwareaopen(BW_edge,150);
figure;
imshow(BW_edge);

%% determine different distances
% previous use of the "imdistline" tool says that the bullseye of 1 inch is
% 186.57 pixels, will need to automate this process in the future, but for
% now we can use it to convert to distances
pixels_per_inch = 187;
bullet_dia_in = 0.224;  % the bullet hole nominal diameter
bullet_dia_pix = round(bullet_dia_in * pixels_per_inch);
bullet_pix_ll = round(bullet_dia_pix / 2 * 0.92);
bullet_pix_ul = round(bullet_dia_pix / 2 * 1.00);

bull_inner_ring_dia_in = 0.5;
bull_inner_ring_dia_pix = round(bull_inner_ring_dia_in * pixels_per_inch);
bull_inner_ring_pix_ll = round(bull_inner_ring_dia_pix / 2 * 0.98);
bull_inner_ring_pix_ul = round(bull_inner_ring_dia_pix / 2 * 1.05);


%% detect bullet holes
[bullet_centers, bullet_radii] = imfindcircles(BW_edge,[bullet_pix_ll bullet_pix_ul]...
    ,'ObjectPolarity','bright','Sensitivity',0.95, 'Method','TwoStage');


%% detect bull center
[bull_ring_centers, bull_ring_radii] = imfindcircles(BW_edge,[bull_inner_ring_pix_ll bull_inner_ring_pix_ul]...
    ,'ObjectPolarity','bright','Sensitivity',0.95, 'Method','TwoStage');




%% display on image
 figure;
 imshow(RGB);
 h_bullets = viscircles(bullet_centers,bullet_radii);
 h_bull_ring = viscircles(bull_ring_centers,bull_ring_radii);
 
 %% plot "+" at centers of bullet holes and bullseye
 hold on;
 plot(bullet_centers(:,1), bullet_centers(:,2),'+');
 plot(bull_ring_centers(1), bull_ring_centers(2),'+');

















% rgb = imread('test3_OL.jpg');
% figure;
% imshow(rgb);
% 
% 
% gray_image = rgb2gray(rgb);
% imshow(gray_image);
% 
% % find and mark bullet holes
% [centers, radii] = imfindcircles(rgb,[19 21],'ObjectPolarity','dark', ...
%     'Sensitivity',0.97, 'Method','twostage','EdgeThreshold',0.2);
% imshow(rgb);
% h_bullets = viscircles(centers,radii);
% 
% % find and mark the bull sticker
% [centers_bull, radii_bull] = imfindcircles(rgb,[45 50],'ObjectPolarity','dark', ...
%     'Sensitivity',0.97, 'Method','twostage','EdgeThreshold',0.3);
% h_bulls = viscircles(centers_bull,radii_bull);