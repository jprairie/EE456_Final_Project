classdef Bullet
    %BULLET Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bullet_dia_inches;
    end
    
    methods
        % -----------------------------------------------------------------
        % Function BULLET (Class Constructor)
        %
        % Description:
        %   This is the class constructor for the "BULLET" class. Enter more
        %   description here later.
        %
        % Inputs:
        %   input 1 -- description
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function obj = Bullet(bullet_dia_inches)
           % set the bullet_dia property
           obj.bullet_dia_inches = bullet_dia_inches;
        end
        
    end
    
end

