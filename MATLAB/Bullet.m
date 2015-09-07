classdef Bullet < handle
    %BULLET Class representation of a bullet
    %   Bullet class object contains information about the bullets used
    %   
    %   Property descriptions:
    %       bullet_dia_inches -- the bullet diameter in inches
    %       bullet_dia_pixels -- the bullet diameter in pixels
    
    properties
        bullet_dia_inches;
        bullet_dia_pixels;
    end
    
    methods
        % -----------------------------------------------------------------
        % Function BULLET (Class Constructor)
        %
        % Description:
        %   This is the class constructor for the "BULLET" class. 
        %
        % Inputs:
        %   bullet_dia_inches -- The nominal bullet diameter in inches
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function obj = Bullet(bullet_dia_inches)
           % set the bullet_dia property
           obj.bullet_dia_inches = bullet_dia_inches;
           % default value of 300 dpi, this will be set properlay in the
           % class constructor for the GROUP class
           obj.bullet_dia_pixels = 300 * bullet_dia_inches;
           
        end
        
    end
    
end

