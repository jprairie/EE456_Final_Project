% see http://www.mathworks.com/help/images/examples/detecting-a-cell-using-image-segmentation.html

close all;
clear all;
clc;
home;

I = rgb2gray(imread('_real.jpg'));
I = im2bw(I,0.5 * graythresh(I));
figure, imshow(I), title('original image');

[~, threshold] = edge(I, 'sobel');
fudgeFactor = .5;
BWs = edge(I,'sobel', threshold * fudgeFactor);
figure, imshow(BWs), title('binary gradient mask');

se90 = strel('line', 10, 90);
se0 = strel('line', 10, 0);

BWsdil = imdilate(BWs, [se90 se0]);
figure, imshow(BWsdil), title('dilated gradient mask');

BWdfill = bwareaopen(BWsdil,2000);
figure, imshow(BWdfill);
title('binary image with filled holes');

seD = strel('diamond',1);
BWfinal = imerode(BWdfill,seD);
BWfinal = imerode(BWfinal,seD);
BWfinal = bwareaopen(BWfinal,2000);
figure, imshow(~BWfinal), title('segmented image');
