% run a testbed to get the workspace vars
%test_bed_2;

clc;
home;

% extract a segmented target 1 gry image
image = imread('_Target_B.jpg');
image = rgb2gray(image);

figure;
hold on;
imshow(edge(image,'canny'));




pol = 'bright';
num = 6 * 3;
min_sens = 0.5;
max_sens = 1.0;
divisor = 2.0;
sens = (max_sens + min_sens) / divisor;


iter = 0;
max_iter = 15;
rad_limits = [19 25];

while (true)
    disp(sens);
    % try to get centers at the current sensitivity
    [centers, radii, metric] = ...
        imfindcircles(image,rad_limits,'ObjectPolarity',...
        pol,'Sensitivity',sens,...
        'Method','TwoStage');
    % if the number found is greater than what we want
    if size(centers,1) > num
        max_sens = sens;
    elseif size(centers,1) < num % number less than wanted
        min_sens = sens;
    else % number found is what we wanted
        break;
    end
    
    % increment iter and error if we have dont too many iters
    iter = iter + 1;
    if iter > max_iter
        error('too many iterations, cannot find circles');
    end
    
    % recalculate sens an start over
    sens = (max_sens + min_sens) / divisor;
end



viscircles(centers,radii);
