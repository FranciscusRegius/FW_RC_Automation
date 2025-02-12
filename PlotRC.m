function confirmation = PlotRC(data, record_names, bool_normalize,bool_permuscle,bool_ratio)
    
    % data: the struct input, should consists of columns str and emg chns
    % repetition: integer, how many times should I plot the data_range of
    %amplitudes, since I put the amplitudes across 3 trials in the same
    %struct

    % bool_normalize: whether or not to normalize, data to the largest response of the muscle across stimulation locations -->  i.e., the global maximum across all stimulation locations of RRF would be 1 and the global minimum would be 0, everything else would be scaled accordingly.

     %DEbug, bool_global_normalization: normalize all data together --> the shape of the plot should look the same as unnormalized 
     % when bool_global_normalization is false, default to normalize
     % according to one channel (muscle) across all records, s.t. changes
     % in less stimulated muscles are exaggerrated

    % DONE: Add a parameter to incorporate plotting ratio 
    % bool_ratio 

    
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
        writetable(data, "Output/normalized_data.csv"); % TODO, see if you can give a table a title as a property
     end

%% Plot naming:
if bool_ratio 
    y_label = "R2R1 Ratio";
else if bool_normalize
    y_label = "Normalized Intensity";
else 
    y_label = "Intensity (Volts)";
end 

%% Different Types of Plotting
    if str_global == "per muscle"
     %%Plotting per muscle 


     for i = 3:data_width %First, define the columns
        figure;
        hold on;
        muscle_name = data.Properties.VariableNames{i};

        for r = 1:length(record_names) %Plot each range of data as a separate line


            curr_range = ismember(data.record_name, record_names(r));

            x = data{curr_range,1};
            channel = data{curr_range,i}; %DONE: change this so that it just loops through each column
            plot(x, channel, "DisplayName", record_names(r)); % DONE: change dispalyname to be the column name
        end
        % Customize plot
        title(str_ratio + muscle_name);
        xlabel('amplitudes');
        ylabel(y_label);
        legend('Location','best'); % or best outside;
        grid on;
        hold off;

        plot_name = "Output/rcplot " + str_ratio + muscle_name + " " + str_normalize + str_global + ".png";
        saveas(gcf, plot_name);
        % fprintf(['plot saved as ' plot_name])
        clf; 

     end

    else %Plotting per record
     for r = 1:length(record_names)
        %First, extract x-axis (str.values)
        figure;
        hold on;

        % Instead: find the indices of the rows where strcmp evaluates to
        % true 
        % data_range = sum(strcmp(data.record_name, record_names(r)));
        % curr_range = (1:data_range) + data_range * (r-1) ;
        curr_range = ismember(data.record_name, record_names(r));
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
        
        for i = 3:data_width % DONE: change this st. it just goes through each column one by one
            channel = data{curr_range,i}; %TODO: change this so that it just loops through each column
            % channel = channel(curr_range);
            plot(x, channel, "DisplayName",data.Properties.VariableNames{i}); % DONE: change dispalyname to be the column name
        end
        % As such, the data structure must treat each channel as a separate object
        
        % Customize plot
        title(str_normalize + str_ratio + record_names(r) );
        xlabel('amplitudes');
        ylabel(y_label);
        legend('Location','best'); % or best outside;
        grid on;
        hold off;
        
        plot_name = "Output/rcplot" + r  + str_ratio + str_normalize+ str_global + "new.png";
        saveas(gcf, plot_name);
        % fprintf(['plot saved as ' plot_name])
        clf; 
     end

    end
    confirmation = 1;
end



%%%%List of parameters
% Data type
% Interval from dataset (alternatively, make better datasets) 
% font size
% color scheme
% axis labels/etc.
% Save as what name 
