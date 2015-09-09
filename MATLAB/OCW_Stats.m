classdef OCW_Stats < handle
    %OCW_STATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Group;
        group_names;
        delta_names;
        data;
        composite_fig;
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
            
            % create the scanned image figure
            create_scanned_subimages(obj);
            
            % create the composite figure
            create_composite_fig(obj);
            

            
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
                % only do computations if there are centroids to process
                centroids = ...
                    cat(1,obj.Group.info.(names{i}).bullet_group_props. ...
                    Centroid);
                
                if ~isempty(centroids)
                    % flag that POI are present
                    obj.data.(names{i}).POI_present = 1;

                    % calculate the mean POI (centroid)
                    mean_POI = sum(centroids) ./ size(centroids,1);
                    obj.data.(names{i}).mean_POI = mean_POI;
                    
                    % assign the POA
                    POA = obj.Group.info.(names{i}).poa_center;
                    obj.data.(names{i}).POA = POA;
                    
                    % calculate the mean POI to POA distance
                    x1 = POA(1);
                    y1 = POA(2);
                    x2 = mean_POI(1);
                    y2 = mean_POI(2);
                    dx = x2 - x1; % POI is reference
                    dy = y2 - y1; % POI is reference
                    mag = sqrt(dx^2 + dy^2);
                    angle = atand(dy / dx);
                    obj.data.(names{i}).POA_to_POI_RECT = [dx dy];
                    obj.data.(names{i}).POA_to_POI_MA = [mag angle];
                    
                    % calculate the delta data
                    
                else
                    obj.data.(names{i}).POI_present = 0;
                    obj.data.(names{i}).mean_POI = -1;
                    obj.data.(names{i}).POA_to_POI_RECT = [-1 -1];
                    obj.data.(names{i}).POA_to_POI_MA = [-1 -1];
                end
            end
        end
        
        
        % -----------------------------------------------------------------
        % Function PIX2INCH
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
        function inches = pix2inch(obj,pixels)
           dpi = obj.Group.Target.image_dpi;
           inches = pixels ./ dpi;
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_COMPOSITE_FIG
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
        function create_composite_fig(obj)
            
           % get the nominal rectangular box regions for this target
           % style type and set both to be the max of the two
           nom_bounds = [obj.Group.Target.approx_rect_W ...
               obj.Group.Target.approx_rect_H];
           nom_bounds = [max(nom_bounds) max(nom_bounds)];
           
           
           % the center of the bounds will be the normalized POA, this is
           % aleady in inches
           center_POA = nom_bounds ./ 2;
           POA_x = center_POA(1);
           POA_y = center_POA(2);
           
          

           % previously we calculated the distance that each group centroid
           % was from the POA in both x and y coordinates, plot this out
           
           figure;
           xlim([0 nom_bounds(1)]);
           ylim([0 nom_bounds(2)]); 
           hold on;
           grid on;
           axis('square');
           title('Composite Plot of Group Centroids');
           xlabel('Target Width, Inches');
           ylabel('Target Height, Inches');
           plot(center_POA(1),center_POA(2),'Or','MarkerFaceColor','red');
           
           % plot a circle of 1 inch
           r = 0.5;
           x = center_POA(1);
           y = center_POA(2);
           ang=0:0.01:2*pi;
           xp=r*cos(ang);
           yp=r*sin(ang);
           plot(x+xp,y+yp,'LineStyle',':','Color',[0 0 0]);
           
           % plot each of the centroids
           for i = 1:length(obj.group_names)
               present = obj.data.(obj.group_names{i}).POI_present;
               if present
                   x = pix2inch...
                       (obj,obj.data.(obj.group_names{i}).POA_to_POI_RECT(1))...
                       + POA_x;
                   y = POA_y - pix2inch...
                       (obj,obj.data.(obj.group_names{i}).POA_to_POI_RECT(2));
                   plot(x,y,'Ob','MarkerFaceColor','blue');
                   text(x,y,num2str(i),'VerticalAlignment','bottom', ...
                       'HorizontalAlignment','right');
               end
           end
           
           
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_SCANNED_SUBIMAGES
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
        function create_scanned_subimages(obj)
            % choose what to do based on the plot style
            plot_style = obj.Group.Target.style_num;
            
            switch plot_style
                case 1
                    figure;
                    for i = 1:length(obj.group_names)
                       image = ...
                           obj.Group.info.(obj.group_names{i}).rgb_image;
                       subplot(3,2,i);
                       subimage(image);
                       title(sprintf('Group %d',i));
                    end
                otherwise
                    error('Plot style not recognized');
            end  
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_DELTA_PLOT
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
        function create_delta_plot(obj)
            
        end
        
        
    end
    
end

