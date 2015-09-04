classdef Group < handle
    %GROUP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Target;
        Bullet;
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
        function obj = Group(Target,Bullet)
            obj.Target = Target;
            obj.Bullet = Bullet;
            
            % update the bullet dia in pixels
            obj.Bullet.bullet_dia_pixels = Target.image_dpi * ...
                obj.Bullet.bullet_dia_inches;
            
            % correct any rotation that is present in the scanned images
            correct_image_rotation(obj);
            
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
            
            % TODO: implement remove small object with a parameter for size
            % clean up image
            % remove_small_objects_temp_image(obj);
            
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
                    imrotate(obj.Target.rgb_image,theta);
                obj.Target.gry_image = ...
                    imrotate(obj.Target.gry_image,theta);
                obj.Target.bw_image = imrotate(obj.Target.bw_image,theta);
                
                % TODO: The images are now bigger than they otherwise would be
                % need to figure otu how to shrink them
            end
                   
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
           dia_pix = obj.Target.poa_size.pixels;
           centers = find_round_objects(obj,input_image,dia_pix,num_poa);
        end
        
        
    end
    
end

