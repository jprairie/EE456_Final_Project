classdef Group < handle
    %GROUP Summary of this class goes here
    %   Detailed explanation goes here
    
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
        %   This is the class constructor for the "GROUP" class. Enter more
        %   description here later.
        %
        % Inputs:
        %   input 1 -- description
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
               f_name = ['group_' int2str(i)];
               
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
               obj.info.(f_name).poa_center = [0 0];
               obj.info.(f_name).bullet_centers = [];
               obj.info.(f_name).nominal_num_holes = obj.bullets_per_group;
            end
            
            
            
        end
        
        
        % -----------------------------------------------------------------
        % Function CORRECT_IMAGE_ROTATION
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
        function rotated = correct_image_rotation(obj)
            % assign the bw image to the temp_process image
            temp_process_image = obj.Target.bw_image;
            
            % crop the image based on style num
            switch obj.Target.style_num
                case 1
                    % crop out just the top 2 inches (8" x 2" chunk)
                    temp_process_image = ...
                        imcrop(temp_process_image, [0 0 ...
                        (8 * obj.Target.image_dpi) ...
                        (2 * obj.Target.image_dpi)]); 
                    num_poa = 2;
                otherwise
                    error('Target style not recognized');
            end
                        
            % find the POA circles
            poa_centers = find_poa_centers(obj,temp_process_image,num_poa);
            
            % obj.poa_center_locations should now have the found POA
            % use imrotate after calculating the angle, CW is a neg angle,
            % CCW is a pos angle
            x_values = poa_centers(:,1);
            y_values = poa_centers(:,2);
            
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
            theta_threshold = 0.15;
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
        %   TODO:  Rewrite this description
        %   Determine the center coordinates for "num_poa" bullseyes or
        %   points of aim (POA). Uses the MATLAB function "imfindcircles"
        %   to determine circular objects that are close to the same size
        %   as the POA (as defined by the style_num). Uses an iterative
        %   approach by setting the algorithm sensitivty to 90% and walking
        %   up by 1% until the correct number of POA are found or we pass
        %   100%. If 100% is passed, the functions errors. At the
        %   conclusion of the function, the properties
        %   "poa_center_location" and "poa_center_radii" have correctly
        %   populated values.
        %
        % Inputs:
        %   num_poa = number of bullseyes or poa as determined earlier by
        %   the target style
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function centers = find_round_objects(obj,in_image,dia_pix,num)
            % use imfindcircles to determine circles that are roughly the
            % same size as dia. Imfindcircles takes radius as input.
            buffer = 10; % not exactly sure on poa size (in pixels)
            limits = [floor(dia_pix / 2) - buffer ...
                floor(dia_pix / 2) + buffer];
            imfindcircle_sens = 0.90;
            inc = 0.1;
            
            while (true)
                [centers, radii] = ...
                    imfindcircles(in_image,limits,...
                    'ObjectPolarity','dark','Sensitivity',imfindcircle_sens,...
                    'Method','TwoStage');
                
                if length(find(centers(:,1))) == num
                    break;
                else
                    imfindcircle_sens = imfindcircle_sens + inc;
                    if imfindcircle_sens > 100
                        error('Cannot detect POA properly');
                    end
                end
            end
        end
        
        
        % -----------------------------------------------------------------
        % Function FIND_POA_CENTERS
        %
        % Description:
        %   TODO:  Rewrite this description
        %   This functions wraps...
        %
        % Inputs:
        %   num_poa = number of bullseyes or poa as determined earlier by
        %   the target style
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function centers = find_poa_centers(obj,input_image,num_poa)
           % wrap functionality of find_round_objects
           % define dia_pix, this should be half the bullet_dia in pixels
           dia_pix = obj.Target.poa_dia.pixels;
           centers = find_round_objects(obj,input_image,dia_pix,num_poa);
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
            indices = find((area > (0.75 * nominal_area)) & ...
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

