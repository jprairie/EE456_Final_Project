clear;
close all;
home;

%% define a "Bullet"
bullet_dia = 0.224;
Bullet = Bullet(bullet_dia);

%% define a "Target"
image_name = '_target_1.jpg';
%image_name = '_target_1_no_holes.jpg';
target_style_num = 1;
Target = Target(image_name,target_style_num);

%% define a "Group"
bullets_per_group = 3;
Group = Group(Target,Bullet,bullets_per_group);

%% create the OCW stats
OCW_Stats = OCW_Stats(Group);
