classdef Target < handle
    %TARGET Class represent a paper target
    %   Detailed explanation goes here
    
    properties
        style_num;
        dpi;
        poa_dia_inches;
        poa_dia_pixels;
        num_bulls;
        paper_size_inches;
        paper_size_pixels;
        rotation_deg;
        rgb_image;
        gry_image;
        bw_image;
        gray_thresh_level;
        image_info;
        
        %TODO:  Figure out how the Target class should own a Group class
        
        
    end
    
    methods
        % Class Constructor
        % rgb_image -- the filename of an image of the target
        % style_num -- the target style number, determines target specifics
        function obj = Target(rgb_image_filename,style_num)
            obj.image_info = imfinfo(rgb_image_filename);
            obj.style_num = style_num;
            
            
            % based on the style_num, assign values to properties
            switch style_num
                case 1
                    % paper size is 8.5 x 11
                    obj.paper_size_inches = [8.5 11];  % [x y]
                    obj.poa_dia_inches = 0.5; % 1/2 inch center bullseye
                    
                    
                    
                otherwise
                    error('Target style number unknown');         
            end
            
            obj.dpi = find_image_dpi(obj);
            obj.rgb_image = imread(rgb_image_filename);
            obj.gry_image = rgb2gray(obj.rgb_image);
            obj.gray_thresh_level = graythresh(obj.gry_image);
            obj.bw_image = im2bw(obj.gry_image,obj.gray_thresh_level);
            obj.poa_dia_pixels = obj.poa_dia_inches * obj.dpi;
            obj.paper_size_pixels = obj.paper_size_inches .* obj.dpi;
            
        end
        
%         % -----------------------------------------------------------------
%         % Determine bullseye or POA locations
%         function poas = find_poas(obj)
%             
%         end
        
        % -----------------------------------------------------------------
        % get image dpi
        function dpi = find_image_dpi(obj)
            % image dpi in x and y directions is listed in the image_info
            % struct as XResolution and YResolution respectively
            dpi_x = obj.image_info.XResolution;
            dpi_y = obj.image_info.YResolution;
            if (dpi_x ~= dpi_y)  % x and y resolutions should be the same
                error('X and Y image resolutions are not equal!!');
            end
            dpi = dpi_x;
            
        end
        
        
        
        
    end
    
end

