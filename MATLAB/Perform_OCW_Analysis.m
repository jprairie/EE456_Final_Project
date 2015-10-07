% -------------------------------------------------------------------------
% Main Program for OCW Analysis
% 
% Created by:   Jason Prairie
% Last Edited:         10/7/2015

clear;
close all;
home;

%% Query user for a bullet diameter (in inches)
prompt = 'Please enter the bullet diameter in inches and press return';
dlg_title = 'Bullet Diameter (inches)';
bullet_dia = str2double(inputdlg(prompt,dlg_title));

% create a Bullet Object
Bullet = Bullet(bullet_dia);

%% Prompt user to select the scanned in target file
[filename, pathname] = uigetfile('Select the scanned target image...');
image_name = fullfile(pathname, filename);

% get the target style # from the user
prompt = 'Please enter target style # and press return';
dlg_title = 'Target Style #';
target_style_num = str2double(inputdlg(prompt,dlg_title));

% create a "Target" object
Target = Target(image_name,target_style_num);

%% define a "Group"
prompt = 'Please enter the # bullet holes per target';
dlg_title = 'Bullets Per Target';
bullets_per_group = str2double(inputdlg(prompt,dlg_title));
Group = Group(Target,Bullet,bullets_per_group);

%% create the OCW stats and visualize results
OCW_Stats = OCW_Stats(Group);
