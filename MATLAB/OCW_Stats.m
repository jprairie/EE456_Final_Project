classdef OCW_Stats < handle
    %OCW_STATS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Group;
        group_names;
        delta_names;
        data;
        biege;
        orange;
        blue;
        green;
        black;
        gold;
        composite_fig_handle;
        delta_fig_handle;
        scanned_subimages_handle;
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
            % setup the colors to use in the plots
            base = 255;
            obj.biege = [242 240 230] ./ base;
            obj.orange = [243 112 33] ./ base;
            obj.blue = [75 143 204] ./ base;
            obj.green = [0 168 81] ./ base;
            obj.black = [35 31 32] ./ base;
            obj.gold = [253 185 36] ./ base;
            
            % assign the Group Class property
            obj.Group = Group;
            
            % create a cell array containing 'group_names'
            create_group_names(obj);
            
            % create a cell array containing 'delta_names'
            create_delta_names(obj,obj.group_names);
            
            % calculate data
            calculate_data(obj);
            
            % create the scanned image figure
            obj.scanned_subimages_handle = create_scanned_subimages(obj);
            
            % create the composite figure
            obj.composite_fig_handle = create_composite_fig(obj);
            
            % create the delta measurements figure
            obj.delta_fig_handle = create_delta_fig(obj);
            
            % TODO: present a UI dialog to select a location to save all
            % plots as pdfs
            save_to_pdf(obj);
            

            
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
            
            % assign the non-delta data
            for i = 1:size(names,1)
                % only do computations if there are centroids to process
                centroids = ...
                    cat(1,obj.Group.info.(names{i}).bullet_group_props. ...
                    Centroid);
                
                if ~isempty(centroids)
                    % flag that POI are present
                    obj.data.(names{i}).POI_present = 1;

                    % calculate the mean POI (centroid)
                    mean_POI = sum(centroids,1) ./ size(centroids,1);
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
                else
                    obj.data.(names{i}).POI_present = 0;
                    obj.data.(names{i}).mean_POI = -1;
                    obj.data.(names{i}).POA_to_POI_RECT = [-1 -1];
                    obj.data.(names{i}).POA_to_POI_MA = [-1 -1];
                end
            end
            
            % calculate the delta data, first check to make sure we have a
            % valid target, holes must appear in group 1 and 2 at a
            % minimum. Test this by scanning through the POI_present flag
            % to make sure it starts ON and may not go OFF before 3. If it
            % goes off at 3 or after, it may not go back on at all
            locked = 0;
            for i = 1:length(obj.group_names)
               status = obj.data.(names{i}).POI_present;
               if ( ((i == 1) || (i == 2)) && (status == 0) )
                   error('Target invalid shooting sequence');
               elseif (status == 0)
                   locked = 1;
               elseif (locked == 1)
                   error('Target invalid shooting sequence');
               end
            end
            
            % we are guaranteed we have a correct shooting sequence now, so
            % if we start at index 2 and quit the first time we see
            % POI_present = 0 we will be good
            names = obj.delta_names;
            for i = 2:length(obj.group_names)
                % get the mean POI for group_i and group_i-1, i-1 is the
                % refence point, find the delta x and y, then find the
                % magnitude of the distance between the points, assign
                % appropriately
                if ( obj.data.(obj.group_names{i}).POI_present ...
                        ||  obj.data.(obj.group_names{i-1}).POI_present)
                    x2 = obj.data.(obj.group_names{i}).mean_POI(1);
                    x1 = obj.data.(obj.group_names{i-1}).mean_POI(1);
                    y2 = obj.data.(obj.group_names{i}).mean_POI(2);
                    y1 = obj.data.(obj.group_names{i-1}).mean_POI(2);
                    
                    obj.data.(names{i-1}).delta_x = pix2inch(obj,x2 - x1);
                    % yaxis is flipped with the image data
                    obj.data.(names{i-1}).delta_y = pix2inch(obj,y1 - y2);
                    obj.data.(names{i-1}).mag = pix2inch(obj,...
                        sqrt((x2 - x1)^2 + (y2 - y1)^2));  
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
        function h = create_composite_fig(obj)
            
           % get the nominal rectangular box regions for this target
           % style type and set both to be the max of the two so we can use
           % a square aspect ratio
           nom_bounds = [obj.Group.Target.approx_rect_W ...
               obj.Group.Target.approx_rect_H];
           nom_bounds = [max(nom_bounds) max(nom_bounds)];
           
           
           % the POA will be placed at the mean POA value for all of the
           % different groups
           sum = [0 0];
           for i = 1:length(obj.group_names)
               sum = sum + obj.data.(obj.group_names{i}).POA;
           end
           
           center_POA = (sum ./ i) ./ (obj.Group.Target.image_dpi);
           POA_x = center_POA(1);
           POA_y = nom_bounds(2) - center_POA(2); % reference from top
           
          

           % previously we calculated the distance that each group centroid
           % was from the POA in both x and y coordinates, plot this out
           
           h = figure('Color','white');
           axes('Color',obj.biege);
           xlim([0 nom_bounds(1)]);
           ylim([0 nom_bounds(2)]); 
           hold on;
           grid on;
           axis('square');
           title_str = ...
               sprintf(['Composite Plot of Group Centroids\n' date]);
           title(title_str);
           xlabel('Target Width, Inches');
           ylabel('Target Height, Inches');
           plot(POA_x,POA_y,'O','Color',obj.blue,...
               'MarkerFaceColor',obj.blue);
           % place POA text slightly above the point
           text(POA_x,POA_y + (0.025 * POA_y),'POA','VerticalAlignment','bottom', ...
                       'HorizontalAlignment','center');
           
           % plot a circle of 1 inch
           r = 0.5;
           x = POA_x;
           y = POA_y;
           ang=0:0.01:2*pi;
           xp=r*cos(ang);
           yp=r*sin(ang);
           plot(x+xp,y+yp,'LineStyle','--','Color',obj.black);
           
           % plot each of the centroids
           for i = 1:length(obj.group_names)
               present = obj.data.(obj.group_names{i}).POI_present;
               if present
                   x = pix2inch...
                       (obj,obj.data.(obj.group_names{i}).POA_to_POI_RECT(1))...
                       + POA_x;
                   y = POA_y - pix2inch...
                       (obj,obj.data.(obj.group_names{i}).POA_to_POI_RECT(2));
                   plot(x,y,'O','Color',obj.orange,'MarkerFaceColor',obj.orange);
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
        function h = create_scanned_subimages(obj)
            % choose what to do based on the plot style
            plot_style = obj.Group.Target.style_num;
            
            switch plot_style
                case 1
                    h = figure('Color','white');
                    for i = 1:length(obj.group_names)
                       image = ...
                           obj.Group.info.(obj.group_names{i}).rgb_image;
                       subplot(3,2,i);
                       subimage(image);
                       title(sprintf('Group %d - %s',i,date));
                    end
                otherwise
                    error('Plot style not recognized');
            end  
        end
        
        
        % -----------------------------------------------------------------
        % Function CREATE_DELTA_FIG
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
        function h = create_delta_fig(obj)
            % delta fig is a quad chart, upper left is a bar graph of delta
            % x values from group to group, upper right is a bar graph of
            % delta y values from group to group, lower left is the
            % magnitude delta from group to group, lower right is text that
            % calls out the OCW
            h = figure('Color','white');
            names = obj.delta_names;
            data_delta_x = zeros(length(names),1);
            data_delta_y = zeros(length(names),1);
            data_mag = zeros(length(names),1);
            bar_labels = cell(size(names));
            for i = 1:length(names)
                % assemble the data
                data_delta_x(i) = obj.data.(names{i}).delta_x;
                data_delta_y(i) = obj.data.(names{i}).delta_y;
                data_mag(i) = obj.data.(names{i}).mag;
                bar_labels{i} = [int2str(i) ' to ' int2str(i+1)];
            end
            
            % upper left plot
            subplot(2,2,1);
            bar(data_delta_x,'FaceColor',obj.orange);
            set(gca,'XTickLabel',bar_labels);
            set(gca,'Color',obj.biege);
            grid on;
            ylabel('Delta X, Inches')
            title(sprintf('Group to Group Delta -- XAxis POI\n%s',date));
            
            % upper right plot
            subplot(2,2,2);
            bar(data_delta_y,'FaceColor',obj.orange);
            set(gca,'XTickLabel',bar_labels);
            set(gca,'Color',obj.biege);
            grid on;
            ylabel('Delta Y, Inches')
            title(sprintf('Group to Group Delta -- YAxis POI\n%s',date));
            
            % lower left
            subplot(2,2,3);
            bar(data_mag,'FaceColor',obj.orange);
            set(gca,'XTickLabel',bar_labels);
            set(gca,'Color',obj.biege);
            grid on;
            ylabel('Delta Total Magnitude, Inches')
            title(sprintf('Group to Group Magnitude Delta POI\n%s',date));
            
            % lower right
            subplot(2,2,4);
            OCW_index = find(data_mag == min(data_mag));
            text_str_1 = ...
                sprintf('After analyzing %d different ',length(names));
            text_str_2 = sprintf('groupings,\nthe Optimum Charge Weight');
            text_str_3 = ...
                sprintf(' (OCW)\nis in the middle of the charge weights\n');
            text_str_4 = sprintf('used for Group %d and Group %d',...
                OCW_index,OCW_index + 1);
            text_str = [text_str_1 text_str_2 text_str_3 text_str_4];
            
            text(0.1,0.60,text_str);
            axis off; 
        end
        
        
        % -----------------------------------------------------------------
        % Function SAVE_TO_PDF
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
        function save_to_pdf(obj)
            % create a cell array of the different handles that we have
            handles = {obj.delta_fig_handle obj.composite_fig_handle ...
                obj.scanned_subimages_handle};
            for i = 1:length(handles)
               set(handles{i},'PaperUnits','inches');
               set(handles{i},'PaperOrientation','Landscape');
               set(handles{i},'PaperPosition',[0 0 11 8.5]);
               set(handles{i},'PaperPositionMode','manual');
               set(handles{i},'Color','white');
               set(handles{i},'InvertHardcopy','off');
               figure(handles{i});
               print(gcf,'-dpdf',['OCW_Workup_Page_' int2str(i) '_' date]);
            end
            
            

        end
        
        
    end
    
end

