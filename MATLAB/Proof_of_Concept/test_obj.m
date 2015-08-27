% bullet hole finding proof of concept
close all;
clear all;
home;

%% load and display the original test image
image_name = 'test5.jpg';
pixels_per_inch = 187;
Target_1 = Target(image_name);
Target_1.set_pixels_per_inch(pixels_per_inch);
ppi = Target_1.get_pix_per_in();
