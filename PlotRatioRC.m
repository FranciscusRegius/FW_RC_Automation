function confirmation = PlotRatioRC(data, data_range, repetition, bool_normalize,bool_global_normalization)
    
    % data: the struct input, should consists of columns str and emg chns
    % data_range: integer, how many rows should be plotted in one plot ; represents a
    %series of amplitudes
    % repetition: integer, how many times should I plot the data_range of
    %amplitudes, since I put the amplitudes across 3 trials in the same
    %struct
    % bool_normalize: whether or not to normalize, data to the largest response of the muscle across stimulation locations -->  i.e., the global maximum across all stimulation locations of RRF would be 1 and the global minimum would be 0, everything else would be scaled accordingly.

     %DEbug, bool_global_normalization: normalize all data together --> the shape of the plot should look the same as unnormalized 
     % when bool_global_normalization is false, default to normalize
     % according to one channel (muscle) across all records, s.t. changes
     % in less stimulated muscles are exaggerrated

     str_normalize = "";
     str_global = "";
     data_width = width(data);
     

     %Global normalization
     if bool_normalize 
         str_normalize = "normalized";
         if bool_global_normalization
             str_global = "globally";
             to_normalize = data{:, 2:data_width};
            
            % Normalize across all columns as a single unit (min-max normalization)
            normalizedData = (to_normalize - min(to_normalize, [], 'all')) / (max(to_normalize, [], 'all') - min(to_normalize, [], 'all'));
            
            % Assign normalized values back to the table
            data{:, 2:data_width} = normalizedData;
            

         else 
            str_global = "permuscle";
            data{:,2:data_width} = normalize(data{:, 2:data_width}, 'range');
        end

        % for col = 2:9
        %     outr3{:, col} = normalize(outr3{:, col}, 'range'); % Min-max normalization for each column
        % end
        writetable(data, "Output/normalized_data.csv"); % TODO, see if you can give a table a title as a property
     end

     %

     for r = 1:repetition
        %First, extract x-axis (str.values)
        figure;
        hold on;


        curr_range = (1:data_range) + data_range * (r-1) ;
        x = data{curr_range,1};
        
        
        tab10 = [
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
        

        for i = 2:data_width % TODO: change this st. it just goes through each column one by one
            channel = data{curr_range,i}; %TODO: change this so that it just loops through each column
            % channel = channel(curr_range);
            plot(x, channel, "DisplayName",data.Properties.VariableNames{i}); % DONE: change dispalyname to be the column name
        end
        % As such, the data structure must treat each channel as a separate object
        
        % Customize plot
        title("R2R1 Ratio Recruitment Curve" + r);
        xlabel('amplitudes');
        ylabel('Ratio, Volts/Volts');
        legend('Location','best'); % or best outside;
        grid on;
        hold off;
        
        saveas(gcf, "Output/r2r1plot" + r + str_normalize + str_global + ".png");
        clf; 
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
