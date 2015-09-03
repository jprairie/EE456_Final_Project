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
        
        
        % -----------------------------------------------------------------
        % Function TARGET (Class Constructor)
        %
        % Description:
        %   This is the class constructor for the "Target" class. Upon
        %   creating a new object of "Target" most of the class properties
        %   will be defined as well as target POA and rectangular regions
        %   located and defined
        %
        % Inputs:
        %   rgb_image_filename - the filename or full path to the scanned
        %       target image to load
        %   style_num - an integer representing the target style number, a
        %       number which is unique to the particular target. Various
        %       class properties will be defined based on this target style
        %       number
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function obj = Target(rgb_image_filename,style_num)
            % assign the properties of the two inputs
            obj.image_info = imfinfo(rgb_image_filename);
            obj.style_num = style_num; 
            
            % based on style_num, assign values to some specific properties
            switch style_num
                case 1
                    obj.poa_dia_inches = 0.5; % 1/2 inch center bullseye
                    obj.num_bulls = 6;
                    obj.poa_order = 1; %top left to bottom right
                    obj.rect_size_inches = [3.5 3.25]; % Horz Vert
  
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

            % correct any image rotation if needed
            correct_image_rotation(obj);
            
            % determine the POA locations
            obj.temp_process_image = obj.bw_image;
            find_poa_centers_temp_image(obj,obj.num_bulls);
            
            % find group borders/rectanglur regions
            obj.temp_process_image = obj.bw_image;
            find_rect_boundaries_temp_image(obj);
            
            % TODO: determine which POA are in which rectangular region,
            % also determine the correct ordering (region numbers) for
            % each area
        end

        
        % -----------------------------------------------------------------
        % Function FIND_IMAGE_DPI
        %
        % Description:
        %   Find the "dots per inch" (dpi) of the scanned image. This
        %   information was stored in the property "image_info" by using
        %   the "imfinfo" MATLAB function. For purposes of this project,
        %   the scanning equipment will set X and Y resoultion the same and
        %   this function will error if it is not the same. The property
        %   "dpi" is set when the function returns
        %
        % Inputs:
        %   none
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
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
        % Function FIND_POA_CENTERS
        %
        % Description:
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
        function find_poa_centers_temp_image(obj,num_poa)
            % use imfindcircles to determine circles that are roughly the
            % same size as our poa. Imfindcircles takes radius as input.
            buffer = 10; % not exactly sure on poa size (in pixels)
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
        % Function REMOVE_SMALL_OBJECTS_TEMP_IMAGE
        %
        % Description:
        %   Remove small objects from the "temp_process_image" that would
        %   otherwise be noise to enhance image segmentation algorithms
        %
        % Inputs:
        %   none
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
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
        % Function FIND_RECT_BOUNDARIES_TEMP_IMAGE
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
        % Function CORRECT_IMAGE_ROTATION
        %
        % Description:
        %   Correct for image rotation introducted during scanning of the
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
        %   none
        % -----------------------------------------------------------------
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
            end
                   
        end    
        
    end
    
end

