classdef OCW_Stats < handle
    %OCW_STATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Group;
        group_names;
        delta_names;
    end
    
    methods
        % -----------------------------------------------------------------
        % Function OCW_STATS (Class Constructor)
        %
        % Description:
        %   This is the class constructor for the "OCW_Stats" class.
        %
        % Inputs:
        %   
        %
        % Outputs:
        %   none
        % -----------------------------------------------------------------
        function obj = OCW_Stats(Group)
            % assign the Group Class property
            obj.Group = Group;
            
            % create a cell array containing 'group_names'
            create_group_names(obj);
            
            % create a cell array containing 'delta_names'
            create_delta_names(obj,obj.group_names);
            
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_GROUP_NAMES
        %
        % Description:
        %   
        %
        % Inputs:
        %   
        %
        % Outputs:
        %   
        % -----------------------------------------------------------------
        function create_group_names(obj)
            obj.group_names = fieldnames(obj.Group.info);
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_DELTA_NAMES
        %
        % Description:
        %   
        %
        % Inputs:
        %   
        %
        % Outputs:
        %   
        % -----------------------------------------------------------------
        function create_delta_names(obj, group_names)
            for i = 1:(size(group_names,1) - 1)
                obj.delta_names{i} = ...
                    [group_names{i} '_to_' group_names{i + 1}];
            end
            
            % transpose to match "group_names"
            obj.delta_names = obj.delta_names';
            
        end
        
    end
    
end

