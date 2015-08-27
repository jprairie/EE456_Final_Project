classdef Target < handle
    %TARGET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        RGB;    % the orginal RGB picture
        GRY;    % grayscale of the RGB image
        BW;     % black and white of RGB image
        gray_thresh_level;
        pixels_per_inch;
        Bullet_Holes;
        Bullseye;

        
    end
    
    methods
        % -----------------------------------------------------------------
        % Class Constructor
        function obj = Target(rgb_filename)
            obj.RGB = imread(rgb_filename);
            obj.GRY = rgb2gray(obj.RGB);
            obj.gray_thresh_level = graythresh(obj.GRY);
            obj.BW = im2bw(obj.GRY,obj.gray_thresh_level);
            obj.Bullet_Holes = Bullet_Holes();
            obj.Bullseye = Bullseye();
        end
        
        % -----------------------------------------------------------------
        % Set pixels per inch
        function set_pixels_per_inch(obj,ppi)
            obj.pixels_per_inch = round(ppi);
        end
        
        % -----------------------------------------------------------------
        % Get pixels per inch
        function ppi = get_pix_per_in(obj)
            ppi = obj.pixels_per_inch;
        end
  
        % -----------------------------------------------------------------
        % Show RGB
        function h = show_RGB(obj)
           h = figure;
           imshow(obj.RGB);
        end
        
        % -----------------------------------------------------------------
        % Show GRY
        function h = show_GRY(obj)
           h = figure;
           imshow(obj.GRY);
        end
        
        % -----------------------------------------------------------------
        % Show BW
        function h = show_BW(obj)
           h = figure;
           imshow(obj.BW);
        end
        
    end
    
end

