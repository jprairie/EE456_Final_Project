classdef Target < handle
    %TARGET Class representation of a paper target
    %   Target class object contains information about the paper target
    %   itself, not information about groups or POA/POI
    %   
    %   Property descriptions:
    %       style_num -- The style number descriptor for the target
    %       rgb_image -- The original scanned RGB image
    %       gry_image -- Grayscale converted image
    %       bw_image -- Black and white image
    %       image_dpi -- the dots per inch in the X and Y direction, must
    %           be the same
    %       target_paper_size -- a struct that contains info about target x
    %           and y size in pixels and inches
    %       rotation_correction_amount -- if rotation correction is
    %           necessary, this value is populated by the amount of
    %           rotation needed


    
    properties
        % see definitions above
        style_num;
        rgb_image;
        gry_image;
        bw_image;
        image_dpi;
        target_paper_size;
        approx_poa_center_locations;
        approx_rect_area;
        poa_dia;
        num_bulls;
        fiducial_dia_pix;
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
            % create rgb, gry, and bw image representations
            obj.rgb_image = imread(rgb_image_filename);
            obj.gry_image = rgb2gray(obj.rgb_image);
            obj.bw_image = im2bw(obj.gry_image,graythresh(obj.gry_image));
                        
            % save the style_num
            obj.style_num = style_num;
            
            % extract and save the image dpi, x and y must be the same
            image_info = imfinfo(rgb_image_filename);
            dpi_x = image_info.XResolution;
            dpi_y = image_info.YResolution;
            if (dpi_x == dpi_y)
                obj.image_dpi = dpi_x;
            else
                error(['X and Y resolution of scanned image' ...
                    ,' are not the same']);
            end
            
            % using image info for the total X and Y pixels, determine the
            % paper size in inches
            obj.target_paper_size.X_pixels = image_info.Width;
            obj.target_paper_size.Y_pixels = image_info.Height;
            obj.target_paper_size.X_inches = ...
                obj.target_paper_size.X_pixels / obj.image_dpi;
            obj.target_paper_size.Y_Inches = ...
                obj.target_paper_size.Y_pixels / obj.image_dpi;
            
            % based on the style number, define the approximate bullseye
            % centers
            switch style_num
                case 1
                    % style 1, approximate center locations
                    obj.approx_poa_center_locations.inches = ...
                        [2.5 1.25; 6.0 1.25; 2.5 4.5; 6.0 4.5; 2.5 7.75;...
                        6.0 7.75];
                    obj.approx_poa_center_locations.pixels = ...
                        obj.image_dpi .* ...
                        obj.approx_poa_center_locations.inches;
                    obj.num_bulls = 6;
                    obj.poa_dia.inches = 1.0;
                    obj.poa_dia.pixels = obj.poa_dia.inches * ...
                        obj.image_dpi;
                    obj.approx_rect_area.inches = 3.5 * 3.25;
                    obj.approx_rect_area.pixels = ...
                        obj.approx_rect_area.inches * obj.image_dpi^2;
                    obj.fiducial_dia_pix = floor(obj.image_dpi * 0.125);
                otherwise
                    error('Target style not recognized');
            end
            
        end  
    
    end
    
end

