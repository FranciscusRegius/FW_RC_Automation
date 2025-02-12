% Button pushed function: PlotButton
function PlotButtonPushed(app, event)
% When pushed, the button will plot depending on the phase the app is in


%TODO Add a check to detecct whether or not there is a loaded
%dataset. If not, send a warning & stop the function 

%TODO, debug choosing plot logic 
    %In theory, it should just be the same thing as the for
    %loop, except we replace the for loop variable with 1
    %variable 

%TODO: once codes are migrated, repalce all variable names with
% 'app.' properties  
bool_normalize = app.NormalizeCheckBox.Value; 
bool_permuscle = app.PlotforMuscleSpineCheckBox.Value; 
bool_ratio = app.PlotR2R1RatioCheckBox.Value; 

% data = app.DatasettoplotDropDown.Value; 
data = app.out1maxmin; 

%TODO: let user select which record/channel to display 
curr_channel_index = 3;  % Msucle
curr_record_index = 1; % spine

switch app.Phase
    case 1 % window adjusting
        %should plot the window, and the delay, overlaying a
        %sample piece of data (maybe channel 3 at one of the
        %later amplitudes 

        %Calls the plot RC function, but modified s.t. it takes
        %in 
    
    case 2 %do plot rc

        str_normalize = "";
        str_global = "";   
        if bool_ratio
            str_ratio = "r2r1";
        else
            str_ratio = "";
        end 
        data_width = width(data);

    %%  Determining Normalization
        if bool_normalize 
            str_normalize = "normalized ";
            if ~bool_permuscle
                str_global = "globally";
                to_normalize = data{:, 3:data_width};
            
            % Normalize across all columns as a single unit (min-max normalization)
            normalizedData = (to_normalize - min(to_normalize, [], 'all')) / (max(to_normalize, [], 'all') - min(to_normalize, [], 'all'));
            
            % Assign normalized values back to the table
            data{:, 3:data_width} = normalizedData;

            else 
            str_global = "per muscle";
            data{:,3:data_width} = normalize(data{:, 3:data_width}, 'range');
            end
        % TODO: apply this if the corresponding checkbox is
        % checked 
        % writetable(data, "Output/normalized_data.csv"); % TODO, see if you can give a table a title as a property
        end

    %% Plot naming:
        if bool_ratio 
            y_label = "R2R1 Ratio";
        elseif bool_normalize
            y_label = "Normalized Intensity";
        else 
            y_label = "Intensity (Volts)";
        end 
    
    %% Different Types of Plotting
    if bool_permuscle
        %%Plotting per muscle 

      
        %TODO: fix plotting!
        % Step 1: Change it s.t. only the current selected data
        % (termed DATA) is plotted
        % I think i can do this by removing the outer for loops
        % Step 2: change it to conform with plotting to 


        curr_channel_index = find(ismember(app.channel_names, app.StimToPlotDropDown.Value));

        hold(app.UIAxes, "on");
        muscle_name = data.Properties.VariableNames{curr_channel_index};

        for curr_record_index = 1:length(app.record_names) %Plot each range of data as a separate line

            curr_range = ismember(data.record_name, app.record_names(curr_record_index));

            x = data{curr_range,1};
            channel = data{curr_range,curr_channel_index}; %DONE: change this so that it just loops through each column
            plot(app.UIAxes,x, channel, "DisplayName", app.record_names(curr_record_index)); % DONE: change dispalyname to be the column name
        end
        % Customize plot
        
        app.UIAxes.Title.String  = str_ratio + muscle_name;
        app.UIAxes.XLabel.String = 'amplitudes';
        app.UIAxes.YLabel.String = y_label;
        legend(app.UIAxes,'Location','best'); % or best outside;
        app.UIAxes.XGrid = "on";
        app.UIAxes.YGrid = "on";

        hold(app.UIAxes, "off");

        % TODO: toggle on or off based on user preference 
        % plot_name = "Output/rcplot " + str_ratio + muscle_name + " " + str_normalize + str_global + ".png";
        % saveas(gcf, plot_name);
        % fprintf(['plot saved as ' plot_name])
        clf; 

        

        else %Plotting per record
        %First, extract x-axis (str.values)
        
        curr_record_index = app.StimToPlotDropDown.ValueIndex;
        hold(app.UIAxes, "on");

        % Instead: find the indices of the rows where strcmp evaluates to
        % true 
        % data_range = sum(strcmp(data.record_name, record_names(r)));
        % curr_range = (1:data_range) + data_range * (r-1) ;
        curr_range = ismember(data.record_name, app.record_names(curr_record_index));
        x = data{curr_range,1}; % extract the amplitudes 
        
        
        tab10 = [ % curve palette
            1.0000, 0.4980, 0.0549;  % Orange
            0.1725, 0.6275, 0.1725;  % Green
            0.8392, 0.1529, 0.1569;  % Red
            0.5804, 0.4039, 0.7412;  % Purple
            0.5490, 0.3373, 0.2941;  % Brown
            0.8902, 0.4667, 0.7608;  % Pink
            0.4980, 0.4980, 0.4980;  % Gray
            0.7373, 0.7412, 0.1333;  % Yellow
            0.0902, 0.7451, 0.8118;  % Cyan
            0.1216, 0.4667, 0.7059;  % Blue
        ];
        
        for curr_channel_index = 3:data_width % DONE: change this st. it just goes through each column one by one
            channel = data{curr_range,curr_channel_index}; %TODO: change this so that it just loops through each column
            % channel = channel(curr_range);
            plot(app.UIAxes, x, channel, "DisplayName",data.Properties.VariableNames{curr_channel_index}); % DONE: change dispalyname to be the column name
        end
        % As such, the data structure must treat each channel as a separate object
        
        % Customize plot
        app.UIAxes.Title.String  = str_normalize + str_ratio + app.record_names(curr_record_index);
        app.UIAxes.XLabel.String = 'amplitudes';
        app.UIAxes.YLabel.String = y_label;
        legend(app.UIAxes,'Location','best'); % or best outside;
        app.UIAxes.XGrid = "on";
        app.UIAxes.YGrid = "on";

        hold(app.UIAxes, "off");

        % TODO: save according to user preference
        % plot_name = "Output/rcplot" + curr_record_index  + str_ratio + str_normalize+ str_global + "new.png";
        % saveas(gcf, plot_name);
        % fprintf(['plot saved as ' plot_name])
        
    end

    otherwise 
        disp('error phase is not 1 or 2, call the programmer to debug')
end 

end
