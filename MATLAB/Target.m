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
        poa_order;
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
  
                otherwise
                    error('Target style number unknown');         
            end
            
            % get the image dpi
            find_image_dpi(obj);
            
            % determine the poa in pixels
            obj.poa_dia_pixels = obj.poa_dia_inches * obj.dpi;
            
            % create rgb, gry, and bw image representations
            obj.rgb_image = imread(rgb_image_filename);
            obj.gry_image = rgb2gray(obj.rgb_image);
            obj.bw_image = im2bw(obj.gry_image,graythresh(obj.gry_image));
            
            % determine the POA locations
            find_poa_centers(obj);
            
            
            
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
        % fin_poa_centers
        function find_poa_centers(obj)
            % assign the bw image to the temp_process image
            obj.temp_process_image = obj.bw_image;
            
            % remove small objects smaller than poa_dia_pixels (99%), will
            % remove bullet holes as well, image must be inverted for best
            % results, after operation, image is reverted
            safety_factor = 0.99;
            poa_area = ...
                floor(safety_factor * pi * (obj.poa_dia_pixels / 2)^2);
            obj.temp_process_image = ...
                ~bwareaopen(~obj.temp_process_image,poa_area);
            
            % use imfindcircles to determine circles that are roughly the
            % same size as our poa. Imfindcircles takes radius as input.
            buffer = 10; % not exactly sure on poa size
            limits = [floor(obj.poa_dia_pixels / 2) - buffer ...
                floor(obj.poa_dia_pixels / 2) + buffer];
            imfindcircle_sens = 0.95;
            [poa_centers, poa_radii] = ...
                imfindcircles(obj.temp_process_image,limits,...
                'ObjectPolarity','dark','Sensitivity',imfindcircle_sens,...
                'Method','TwoStage');
            obj.poa_center_locations = poa_centers;
            
            %TODO: make the finding of circle a more robust iterative
            %approach
            
            
            switch obj.poa_order
                case 1
                    %TODO: sort the order of the centers to match the target
                otherwise
                    error('Ordering of target bullseyes not defined');
            end
            
        end
        
        
        
        
    end
    
end

