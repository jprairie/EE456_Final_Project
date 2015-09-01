classdef Target < handle
    %TARGET Class represent a paper target
    %   Target class object contains all necessary functions to have a
    %   complete description of an OCW target.
    %   
    %   Property descriptions:
    %       style_num -- The style number descriptor for the target
    %       dpi -- dots per inch of the scanned in target
    %       poa_dia_inches -- diameter of the center bullseye in inches
    %       poa_dia_pixels -- diameter of the center bullseye in pixels
    %       num_bulls -- the number of bullseyes on the target, varies with
    %           style_num
    %       rotation_deg -- the determined number of degrees that the scan
    %           is rotated. This is a small error and will be automatically
    %           corrected
    %       rgb_image -- the full color scanned target image
    %       gry_image -- grayscale converted target image
    %       bw_image -- black and white converted target image
    %       image_info -- image information about the rgb image as
    %           determined by the imfinfo function
    %       temp_process_image -- a temporary location to store processed
    %           images
    %       poa_order -- 1 = top right to bottom left ordering, others may
    %           be added
    %       rect_boundaries -- 2D array that specifies the rectangular
    %           bounds between the different POA
    %       rect_size_pixels -- the size of the rectangles separating
    %           groups in pixels.
    %       rect_size_inches -- the size of the rectangles separating
    %           groups in inches.
    
    properties
        style_num;
        dpi;
        poa_dia_inches;
        poa_dia_pixels;
        num_bulls;
        rotation_deg;
        rgb_image;
        gry_image;
        bw_image;
        image_info;
        temp_process_image;
        poa_center_locations;
        poa_center_radii;
        poa_order;
        rect_boundaries;
        rect_size_inches;
        rect_size_pixels;
    end
    
    methods
        % Class Constructor
        % rgb_image -- the filename of an image of the target
        % style_num -- the target style number, determines target specifics
        function obj = Target(rgb_image_filename,style_num)
            obj.image_info = imfinfo(rgb_image_filename);
            obj.style_num = style_num; 
            
            % based on style_num, assign values to some specific properties
            switch style_num
                case 1
                    obj.poa_dia_inches = 0.5; % 1/2 inch center bullseye
                    obj.num_bulls = 6;
                    obj.poa_order = 1; %top left to bottom right
                    obj.rect_size_inches = [3.5 3.25];
  
                otherwise
                    error('Target style number unknown');         
            end
            
            % get the image dpi
            find_image_dpi(obj);
            
            % determine the poa and rectangle size in pixels
            obj.poa_dia_pixels = obj.poa_dia_inches * obj.dpi;
            obj.rect_size_pixels = obj.rect_size_inches .* obj.dpi;
            
            % create rgb, gry, and bw image representations
            obj.rgb_image = imread(rgb_image_filename);
            obj.gry_image = rgb2gray(obj.rgb_image);
            obj.bw_image = im2bw(obj.gry_image,graythresh(obj.gry_image));

            % correct any image rotation
            correct_image_rotation(obj);
            
            % determine the POA locations
            obj.temp_process_image = obj.bw_image;
            find_poa_centers_temp_image(obj,obj.num_bulls);
            
            % find group borders
            obj.temp_process_image = obj.bw_image;
            find_rect_boundaries_temp_image(obj);  
        end

        
        % -----------------------------------------------------------------
        % get image dpi
        function find_image_dpi(obj)
            % image dpi in x and y directions is listed in the image_info
            % struct as XResolution and YResolution respectively
            dpi_x = obj.image_info.XResolution;
            dpi_y = obj.image_info.YResolution;
            if (dpi_x ~= dpi_y)  % x and y resolutions should be the same
                error('X and Y image resolutions are not equal!!');
            end
            obj.dpi = dpi_x;
            
        end
        
        % -----------------------------------------------------------------
        % find_poa_centers
        function find_poa_centers_temp_image(obj,num_poa)
            % use imfindcircles to determine circles that are roughly the
            % same size as our poa. Imfindcircles takes radius as input.
            buffer = 10; % not exactly sure on poa size
            limits = [floor(obj.poa_dia_pixels / 2) - buffer ...
                floor(obj.poa_dia_pixels / 2) + buffer];
            imfindcircle_sens = 0.90;
            inc = 0.1;
            
            while (true)
                [poa_centers, poa_radii] = ...
                    imfindcircles(obj.temp_process_image,limits,...
                    'ObjectPolarity','dark','Sensitivity',imfindcircle_sens,...
                    'Method','TwoStage');
                if length(poa_centers) == num_poa
                    break;
                else
                    imfindcircle_sens = imfindcircle_sens + inc;
                    if imfindcircle_sens > 100
                        error('Cannot detect POA properly');
                    end
                end
            end
            
            obj.poa_center_locations = poa_centers;
            obj.poa_center_radii = poa_radii; 
        end
        
        % -----------------------------------------------------------------
        % remove small objects
        function remove_small_objects_temp_image(obj)               
            % remove small objects smaller than poa_dia_pixels (99%), will
            % remove bullet holes as well, image must be inverted for best
            % results, after operation, image is reverted
            safety_factor = 0.99;
            poa_area = ...
                floor(safety_factor * pi * (obj.poa_dia_pixels / 2)^2);
            obj.temp_process_image = ...
                ~bwareaopen(~obj.temp_process_image,poa_area);
        end
        
        % -----------------------------------------------------------------
        % find rectangle boundaries
        function find_rect_boundaries_temp_image(obj)    
            remove_small_objects_temp_image(obj);
            
            % find the rectangles that form the border between the
            % different groups.
            nominal_area = obj.rect_size_pixels(1) * obj.rect_size_pixels(1);           
            
            % now find the region properties and trim out anything that is
            % not the rectangle we are looking for
            props = regionprops(obj.temp_process_image);
            area = cat(1, props.Area);
            bounds = cat(1, props.BoundingBox);
            indices = find((area > (0.75 * nominal_area)) & ...
                (area < (1.25 * nominal_area)));
            obj.rect_boundaries = bounds(indices,:);            
            
            % check to make sure we found the right number of regions
            if length(obj.rect_boundaries) ~= obj.num_bulls
                error('Could not detect rectangular regions');
            end
            
        end
        
        
        % -----------------------------------------------------------------
        % correct image rotation
        function correct_image_rotation(obj)
            % assign the bw image to the temp_process image
            obj.temp_process_image = obj.bw_image;
            
            % crop the image based on style num
            switch obj.style_num
                case 1
                    % crop out just the top 2 inches
                    obj.temp_process_image = ...
                        imcrop(obj.temp_process_image, [0 0 ...
                        (8 * obj.dpi) (2 * obj.dpi)]); 
                    num_poa = 2;
                otherwise
                    error('Target style not recognized');
            end
            
            % clean up image
            remove_small_objects_temp_image(obj);
            
            % find the POA circles
            find_poa_centers_temp_image(obj,num_poa)
            
            % obj.poa_center_locations should now have the found POA
            % use imrotate after calculating the angle, CW is a neg angle,
            % CCW is a pos angle
            x_values = obj.poa_center_locations(:,1);
            y_values = obj.poa_center_locations(:,2);
            
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
                obj.rgb_image = imrotate(obj.rgb_image,theta);
                obj.gry_image = imrotate(obj.gry_image,theta);
                obj.bw_image = imrotate(obj.bw_image,theta);
                disp('Corrected rotation in images...');
            end
                   
        end    
        
    end
    
end

