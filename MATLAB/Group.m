classdef Group
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
        end
        
    end
    
end

