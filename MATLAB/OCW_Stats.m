classdef OCW_Stats < handle
    %OCW_STATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Group;
        group_names;
        delta_names;
        data;
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
            
            % calculate data
            calculate_data(obj);
            
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
        
        
        % -----------------------------------------------------------------
        % Function CALCULATE_DATA
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
        function calculate_data(obj)
            % assign the POA
            
            
            
            names = obj.group_names;
            for i = 1:size(names,1)
                % assign the POA
                POA = obj.Group.info.(names{i}).poa_center;
                obj.data.(names{i}).POA = POA;
                
                % calculate the mean POI (centroid)
                centroids = ...
                    cat(1,obj.Group.info.(names{i}).bullet_group_props. ...
                    Centroid);
                mean_POI = sum(centroids) ./ size(centroids,1);
                obj.data.(names{i}).mean_POI = mean_POI;
                
                % calculate the mean POI to POA distance
               x1 = POA(1);
               y1 = POA(2);           
               x2 = mean_POI(1);
               y2 = mean_POI(2);
               dx = x1 - x2; % POA is reference
               dy = -(y1 - y2); % POA is reference, in image, y is flipped
               mag = sqrt(dx^2 + dy^2);
               angle = atand(dy / dx);
               obj.data.(names{i}).POA_to_POI_RECT = [dx dy];             
               obj.data.(names{i}).POA_to_POI_MA = [mag angle]; 

            end
            
            
        end
        
        
        
    end
    
end

