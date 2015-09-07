classdef Group < handle
    %GROUP Class representation of a bullet/shot grouping
    %   The GROUP class ties together both the TARGET and BULLET classes.
    %   Instantiating an object of this class will more or less compute
    %   everything needed for arriving at the center positions for single
    %   hole impacts or if the bullet holes overlay, then there will be one
    %   centroid reported for each overlapped bullet group.
    %   
    %   Property descriptions:
    %       Target -- an instance of the Target Class
    %       Bullet -- an instance of the Bullet Class
    %       bounding_boxes -- the bounds of the rectangular regions that
    %           seperate each grouping
    %       info -- a structure containing information about each group
    %       bullets_per_group -- the number of bullet holes per grouping
    
    properties
        Target;
        Bullet;
        bounding_boxes;
        info;
        bullets_per_group;
    end
    
    methods
        % -----------------------------------------------------------------
        % Function GROUP (Class Constructor)
        %
        % Description:
        %   This is the class constructor for the "Group" class. Upon
        %   creating a new object of "Group" the target will be processed
        %   by finding points of aim (bullseyes) and bullet holes. Bullet
        %   holes that touch will be reproted as one bullet with a location
        %   that is the centroid of the touching set.
        %
        % Inputs:
        %   Target - an instance of the Target class, create this first
        %       before calling this class constructor
        %   Bullet - an instance of the Bullet class, create this first
        %       before calling this class constructor
        %   bullets_per_group - the nominal number of bullets per grouping,
        %       there can be fewer holes detected than this number
        %       (produces a warning) but there may not be more than this
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function obj = Group(Target,Bullet,bullets_per_group)
            obj.Target = Target;
            obj.Bullet = Bullet;
            obj.bullets_per_group = bullets_per_group;
                        
            % update the bullet dia in pixels
            obj.Bullet.bullet_dia_pixels = Target.image_dpi * ...
                obj.Bullet.bullet_dia_inches;
            
            % correct any rotation that is present in the scanned images
            correct_image_rotation(obj);
            
            % find the bounding boxes for each rectangular area
            obj.bounding_boxes = ...
                find_rect_boundaries(obj,obj.Target.bw_image);
            
            % the bounding boxes are in no particular order in the returned
            % array, sort them
            sort_bounding_boxes(obj);

            % group info will be stored in a struct called info, with the
            % first layer being titled group_1, group_2, and so on up to
            % the number of bullseyes on the target, start populating with
            % known values, leave unknow values empty for now
            for i = 1:obj.Target.num_bulls
               % set the group name
               f_name = ['group_' int2str(i)];
               
               % set various information under this group name
               obj.info.(f_name).num_poa = 1;
               
               obj.info.(f_name).bullet_hole_dia = ...
                   obj.Bullet.bullet_dia_pixels;
               
               obj.info.(f_name).poa_dia = ...
                   obj.Target.poa_dia.pixels;
               
               obj.info.(f_name).image_dpi = obj.Target.image_dpi;
               
               obj.info.(f_name).rgb_image = ...
                   imcrop(obj.Target.rgb_image,obj.bounding_boxes(i,:));
               
               obj.info.(f_name).bw_image = ...
                   imcrop(obj.Target.bw_image,obj.bounding_boxes(i,:));
               
               obj.info.(f_name).poa_center = ...
                   find_poa_centers(obj,obj.info.(f_name).bw_image,...
                   obj.info.(f_name).num_poa);
               
               obj.info.(f_name).bullet_group_props = ...
                   find_bullet_group_props(obj,...
                    obj.info.(f_name).rgb_image,obj.bullets_per_group);
               
               obj.info.(f_name).nominal_num_holes = obj.bullets_per_group;

            end 
        end
        
        
        % -----------------------------------------------------------------
        % Function CORRECT_IMAGE_ROTATION
        %
        % Description:
        %   Correct for image rotation introduced during scanning of the
        %   image. Based on the style number, detect the fiducials. X and y
        %   values should be the same, determine the rotation angle in
        %   degrees by the mismatch of the x or y coordinate. Once the
        %   rotation is determined, if above a threshold, use the MATLAB
        %   "imrotate" function to rotate the images back to orthogonal.
        %
        % Inputs:
        %   none
        %
        % Outputs:
        %   rotated -- return 1 if images were rotated, 0 if not
        % -----------------------------------------------------------------
        function rotated = correct_image_rotation(obj)
            % assign the gry image to the temp_process image
            temp_process_image = obj.Target.gry_image;
            
            % assign the image dpi
            dpi = obj.Target.image_dpi;

            % crop the image based on style num
            switch obj.Target.style_num
                case 1
                    % crop out just the top 1 inches, keep the full width
                    x_orig = 0.05 * dpi;
                    y_orig = 0.05 * dpi;
                    temp_process_image = ...
                        imcrop(temp_process_image, [x_orig y_orig...
                        size(temp_process_image,2) ...
                        (1.0 * obj.Target.image_dpi)]); 
                otherwise
                    error('Target style not recognized');
            end
            
            % convert to a bw image, a scale factor changes the determined
            % gray threshold value, if chosen correctly, it will retain
            % black marks and reject ink. A value of 0.5 works well in
            % practice.
            scale = 0.5;
            temp_process_image = im2bw(temp_process_image,...
                scale * graythresh(temp_process_image));
           
            % find the fiducial circles, use radius based upper and lower
            % limits for the search
            radius = obj.Target.fiducial_dia_pix / 2;
            percent = 0.05;
            lower_lim = floor(radius - (radius * percent));
            upper_lim = ceil(radius + (radius * percent));
            rad_limits = [lower_lim upper_lim];
            num = 2;
            pol = 'dark';
            centers = find_round_objects...
                (obj,temp_process_image,rad_limits,num,pol);
            
            % centers should now have the center locations of the 2
            % fiducials, use imrotate after calculating the angle, CW is a
            % neg angle, CCW is a pos angle
            x_values = centers(:,1);
            y_values = centers(:,2);
            
            % make sure the center location with the smallest x value is
            % point 1
            min_index = find(x_values == min(x_values));
            max_index = find(x_values == max(x_values));
            
            x1 = x_values(min_index);
            x2 = x_values(max_index);
            y1 = y_values(min_index);
            y2 = y_values(max_index);
            
            delta_x = x2 - x1;
            delta_y = y2 - y1;
            
            theta = atand(delta_y / delta_x);
            
            % only rotate things if abs(theta) is >= some threshold
            theta_threshold = 0.05;
            if abs(theta) >= theta_threshold
                % rotate all images
                obj.Target.rgb_image = ...
                    imrotate(obj.Target.rgb_image,theta,'nearest','crop');
                obj.Target.gry_image = ...
                    imrotate(obj.Target.gry_image,theta,'nearest','crop');
                obj.Target.bw_image = ...
                    imrotate(obj.Target.bw_image,theta,'nearest','crop');
                
                rotated = 1;
                return;
            end
            
            rotated = 0;
            return;           
        end
        
        
        % -----------------------------------------------------------------
        % Function FIND_ROUND_OBJECTS
        %
        % Description:
        %   Uses MATLAB built-in function "imfindcircles" (uses the
        %   Hough-Transform) to find circular objects). In this
        %   implementation the sensitivty for the algorithm is adjusted in
        %   a binary search approach between a min and max, if the correct
        %   number of circular objects are found, the function returns. If
        %   the correct number is not found before the number of iterations
        %   is used up, the functions errors.
        %
        % Inputs:
        %   image - the image to perform the search on, make sure this
        %       image is set up to help the algorithm suceed
        %   rad_limits - the radius limits to search between
        %   num - the number of circular objects that should be detected
        %   pol - a string ('bright' or 'dark') passed as a parameter to
        %       imfindcircles
        %
        % Outputs:
        %   centers - 2D array of the coordinates of the circular objects
        %   found, each row is a set, col 1 is X, col 2 is Y
        % -----------------------------------------------------------------
        function centers = find_round_objects(obj,image,rad_limits,num,pol)
            % check pol to make sure it is correct
            if ~( strcmp(pol,'bright') || strcmp(pol,'dark') )
               error('input must be dark or bright'); 
            end
            
            
            % initial sensitivity setup, somewhat arbitrary, works in
            % practice
            min_sens = 0.8;
            max_sens = 1.0;
            divisor = 2;
            sens = (max_sens + min_sens) / divisor;
            
            iter = 0;
            max_iter = 30;
            
            while (true)
                % try to get centers at the current sensitivity
                [centers, radii] = ...
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
        end
        
        
        % -----------------------------------------------------------------
        % Function FIND_POA_CENTERS
        %
        % Description:
        %   This function will wrap the functionality of FIND_ROUND_OBJECTS
        %   to determine the target point of aim.
        %
        % Inputs:
        %   num_poa = number of bullseyes or poa as determined earlier by
        %   the target style
        %
        % Outputs:
        %   centers - 2D array of the coordinates of the circular objects
        %   found, each row is a set, col 1 is X, col 2 is Y
        % -----------------------------------------------------------------
        function centers = find_poa_centers(obj,input_image,num_poa)
           % wrap functionality of find_round_objects
           radius = obj.Target.poa_dia.pixels / 2;
           percent = 0.05;
           lower_limit = floor(radius - (percent * radius));
           upper_limit = ceil(radius + (percent * radius));
           limits = [lower_limit upper_limit];
           pol = 'dark';
           centers = find_round_objects...
               (obj,input_image,limits,num_poa,pol);
        end
        
        
        % -----------------------------------------------------------------
        % Function FIND_BULLET_CENTERS
        %
        % Description:
        %   Bullet centers are more challenging to detect because of the
        %   sometimes erratic shapes caused by loose target paper obscuring
        %   the holes. In addition, it is not possible to always be sure
        %   that each bullet will have its own hole, some will overlap. In
        %   this implementation, we will do a great amount of processing to
        %   essentially remove everything except the bullet holes. The
        %   remaining holes will be detected using the MATLAB function
        %   "regionprops". If more than the nominal number of holes is
        %   detected, the function will error out, if fewer, the function
        %   will warn the user (overlapping bullets most likely). The
        %   function will return the region properties which can be used
        %   later to process some statistics about the groups.
        %
        % Inputs:
        %   input_image - the image to process, must be an RGB image
        %   num_bullets - the number of bullets to attempt to detect
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function group_props = find_bullet_group_props...
                (obj,input_image,num_bullets)
            
            % first, take the passed in rgb image and convert to bw
            gry_image = rgb2gray(input_image);
            bw_image = im2bw(gry_image, 0.5 * graythresh(gry_image));
            
            % some edge detection
            bw_image = edge(bw_image,'canny');
            
            
            % dilate it, helps ensure that unenclosed bullet regions get
            % closed, adjust dil_scale for the percent of the bullet
            % diameter to dilate by, use a horizontal and vertical
            % line structuring element, between 0.1 and 0.2 should work
            % good in practice, this does make the bullet holes appear
            % larger at this point
            dil_scale = 0.15;
            dilate_amt = ceil(dil_scale * obj.Bullet.bullet_dia_pixels);
            se90 = strel('line', dilate_amt, 90);
            se0 = strel('line', dilate_amt, 0);
            bw_image = imdilate(bw_image, [se90 se0]);
            
            % now fill the holes
            bw_image = imfill(bw_image, 'holes');
            
            % remove small connected areas, use a size that is much less
            % than the smallest expected bullet size
            smallest_bullet_dia = (0.17 * obj.Target.image_dpi) * 0.5;
            smallest_area = floor(pi * (smallest_bullet_dia / 2)^2);
            bw_image = bwareaopen(bw_image,smallest_area);

            % final erode to smooth it out
            iter = 2;
            smoothing_element = strel('diamond',1);
            for i = 1:iter
                bw_image = imerode(bw_image,smoothing_element);
            end
     
            % at this point all we should have is blobs that represent the
            % holes. Nominally we have specified how many bullets per POA,
            % if the bullets were touching then we will only get one blob
            % per set of touching bullets. Make sure to warn the user about
            % this and return back the regionprops
            group_props = regionprops(bw_image);
            if (size(group_props,1) < num_bullets)
                warning('Did not find all bullets seperately');
            elseif (size(group_props,1) > num_bullets)
                error('Found too many blob objects');
            end
        end
        
        
        % -----------------------------------------------------------------
        % Function FIND_RECT_BOUNDARIES
        %
        % Description:
        %   Determine the rectangular regions that seperate various POA
        %   bullesyes from one another. Makes use of the MATLAB regionprops
        %   function to identify connected regions in the image. We then
        %   search for regions whose area resembles the expected area of
        %   the rectangular regions.
        %
        % Inputs:
        %   none
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function boundaries = find_rect_boundaries(obj,image)    

            % determine the nominal rectangular area size
            nominal_area = obj.Target.approx_rect_area.pixels;         
            
            % now find the region properties and trim out anything that is
            % not the rectangle we are looking for
            props = regionprops(image);
            area = cat(1, props.Area);
            bounds = cat(1, props.BoundingBox);
            indices = find((area > (0.70 * nominal_area)) & ...
                (area < (1.25 * nominal_area)));
            boundaries = bounds(indices,:);            
            
            % check to make sure we found the right number of regions
            if length(boundaries) ~= obj.Target.num_bulls
                error('Could not detect rectangular regions');
            end
            
        end
        
        
        % -----------------------------------------------------------------
        % Function SORT_BOUNDING_BOXES
        %
        % Description:
        %   Correct for image rotation introduced during scanning of the
        %   image. Based on the style number, detect two POA. Assuming
        %   either x or y values should be the same, determine the rotation
        %   angle in degrees by the mismatch of the x or y coordinate that
        %   should have been the same. Once the rotation is determined, if
        %   above a threshold, use the MATLAB "imrotate" function to rotate
        %   the images back to orthogonal.
        %
        % Inputs:
        %   none
        %
        % Outputs:
        %   rotated -- return 1 if images were rotated, 0 if not
        % -----------------------------------------------------------------
        function sort_bounding_boxes(obj)
            % the rows of obj.Target.approx_poa_center_locations are in
            % order. For each row...
            temp_data = zeros(size(obj.bounding_boxes));
            for i = 1:size(obj.Target.approx_poa_center_locations.pixels,1)
                center_x = ...
                    obj.Target.approx_poa_center_locations.pixels(i,1);
                center_y = ...
                    obj.Target.approx_poa_center_locations.pixels(i,2);
                for j = 1:size(obj.bounding_boxes,1) % number of rows
                    % for each row in bounding boxes
                    % determine the max/min x and y pixel values of the box
                    bounds = obj.bounding_boxes(j,:);
                    min_x = bounds(1);
                    min_y = bounds(2);
                    max_x = min_x + bounds(3);
                    max_y = min_y + bounds(4);
                    if ( (center_x >= min_x) && (center_x <= max_x) && ...
                            (center_y >= min_y) && (center_y <= max_y) )
                       % this poa center is within this bounding box
                       temp_data(i,:) = bounds;
                       break;
                    end
                end
            end
            
            obj.bounding_boxes = temp_data;
            
            % get the approximate poa center locations one by one
        end
        
    end
    
end

