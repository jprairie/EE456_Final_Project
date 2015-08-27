classdef Bullet_Holes
    %BULLET_HOLES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        num_holes;
        centers;
        caliber_dia;
    end
    
    methods
        % -----------------------------------------------------------------
        % Class Constructor
        function obj = Bullet_Holes()
            obj.num_holes = 0;
            obj.centers = []; 
            obj.caliber_dia = 0.224;
        end
    end
    
end

