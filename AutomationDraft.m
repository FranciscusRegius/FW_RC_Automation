function AutomationDraft(file_name)
% Automation Draft
% labchart = adi.readFile("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% Figure out how to load adiconvert 


%%%% This file will be declared obsolete & a reference with the creation of the UI %%%%


%% List of parameters 


% stim_interval: a numbers in ticks - the distance between stim 1 and 2, helps to calculate sampling window
% delay: number in ticks, the delay between admitted stimulation and the beginning of the sampling window
% bool_normalize: boolean whether or not to normalize the data, default true for now
bool_normalize = 1; 
% if nargin < 1

    %TODO: add a parser s.t. the input is just a path but you can extract
    %the file name
    % TODO: Add a check to make sure takes you to a .adicht or .mat file 


    file_name = '20240820 RTA003 EPA1_RC ONLY TSS'; % Add a function that 

% end
path = [cd, '\Input\', file_name];
% channels_to_use: allows choice of whcih channels to process; default to
% all channels other than 1&2
channels_to_use = 3:10;
stim_interval = 100; % Represent distance between R1 & R2 delay
R1_delay = 130;
R2_delay = stim_interval + R1_delay;
front_filter = 30 ;%how many ticks to reduce sampling window by to avoid artifact
back_filter = 15;%how many ticks to reduce sampling window by to avoid artifact
sampling_window = stim_interval - front_filter - back_filter;
% The sampling window should start at delay + ff, and last for ws-ff-bf ticks

%Sanity check, the combined front & back fitlers should not be greater than
%window size 
if sampling_window <= 0
    warning('Sampling window does not exist! No data will be collected');
end


fprintf(['\n ===== Opening file ' file_name ' with Alex Chart =====\n\n'] );

% path = 'C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\FW_RC_Automation\20240826_RTA006_EPA1_RC ONLY.adicht'  ; %DEBUGGING:


% %% Preprocessing (Skip this step when no need, takes a lot of time)
% 
% %Load adi into path
% addpath adinstruments_sdk_matlab-master
% 
% file_name = AlexChart(path); % This should load everything into workspace 
% 
% 
% %%% Load data
% 
% %first, load AlexChart processed data 
% 
% load(file_name); 

%% Extract Labchart Fields
% DONE: Saving and loading -- Decicde whether to have the data directly output by AlexChart function or save & load 
Data = Labchart.Data ;
file_meta =Labchart.file_meta ;
comments =Labchart.comments ;
record_meta =Labchart.record_meta ;
channel_meta = Labchart.channel_meta ;

fprintf('\n ===== New file loading completed =====\n\n' );

% clearvars Labchart




%% Filter away repetitive comments
% Create unique keys for all elements in comments
fprintf('\n ===== Filtering Comments =====\n\n' );

keys = arrayfun(@(x) sprintf('%s_%d_%s', x.tick_position, x.record), comments, "UniformOutput",false);

%find unique elements based on the keys
[~, uniqueIdx] = unique(keys, 'stable');

% FInally, filter out repetitions 
comments = comments(uniqueIdx);

clearvars keys uniqueIdx


%% Format data

fprintf('\n ===== Formatting Data =====\n\n' );

% Convert all amplitudes into double from string
for i = 1:numel(comments)
    %First, filter out everything in the "str" field that is not a double
    if ~isempty(regexp(comments(i).str, '^-?\d+$', 'once'))
        comments(i).str = str2double(comments(i).str);
    else 
        comments(i).tick_position = 0;
    end
end

%Sort data first accroding to record, then according to tick_position
record = [comments.record];
tick_pos = [comments.tick_position];

[~,sortIdx] = sortrows([record(:), ...
                tick_pos(:)], ...
                [1,2]);
comments = comments(sortIdx);

clearvars sortIdx tick_pos record


%% Stimulation Location Determination
% DONE
% 1. identify the peaks in channel 2
    % This is done by normalizing channel 2 to be 0 to 1, every spot
    % greater than .8 is going to be a stimulation
    % associate the amplitude comment to the nearest 2 stimulations 
    % Alternatively, assuming that channel 2 format is standard, we can
    % forgo normalizing and just find spots greater than 1
% 3. notate each stimulation in the comments section  
% NExt step, is to make sure the new format can determine R1 & r2

% determine the records we care about, to reduce running time 
records = unique([comments.record]);
irrelevant_records = [];

% Go through each relevant record and determine all the stimulations by
% looking at channel 2
% Then add each of the stimulations to comments
for idx = 1:length(records)
    i = records(idx);

    % extract channel 2 in the given record
    chnl2 = Data{1,i}(2,:); % ith column of the Data cell, everything in row 2
    % find the indices of stimulations as a list (i.e. tick position) 
    indices = find(chnl2 > 2); 

    if width(indices) == 0
        irrelevant_records(end+1) = i;
        continue
    end

    %Remove repetitive stimulations
    diffs = diff(indices);
    boundaries = [1 , find(diffs>stim_interval+3) + 1];
    filtered_indices = indices(boundaries);
    
    % for loop add them as str = 'stim', tick_position = index, record = i
    len = length(comments);
    for j = 1:length(filtered_indices)
        %index = filtered_indices(j)
        len = len + 1;
        comments(len).str = 'stim';
        comments(len).tick_position = filtered_indices(j);
        comments(len).record = i;
    end
end

records = setdiff(records,irrelevant_records);

 % Once again, sort data first accroding to record, then according to tick_position
    record = [comments.record];
    tick_pos = [comments.tick_position];
    
    [~,sortIdx] = sortrows([record(:), ...
                    tick_pos(:)], ...
                    [1,2]);
    comments = comments(sortIdx);

clearvars filtered_indices indices diffs boundaries i idx j irrelevant_records

fprintf("\n ===== Relevant records identified as " + int2str(records)+ " =====\n\n");


%% Peak to peak calculation

%DONE: Figure out how to determine this for other datasets

% TODO: remove this line, as it has been rendered obsolete by new way of
% doing things, assuming data is sufficiently clean and I don't have to do
% more cleaning here 
% comments = comments(arrayfun(@(x) ismember(x.record,records), comments));


fprintf('\n ===== Finding Peak to Peak =====\n\n' );

% For each comment:
for i = 1:numel(comments)
    if ischar(comments(i).str)
        x = comments(i);
%For each stimulation under the amplitude
%   Find in data{record}, the max - min in the area tick+130 to tick+230
%   Find in data{record}, the max - min in the area tick+R1_delay+front_filter to tick+R1_delay+front_filter+sampling_window 

        % DONE: parameterize 3:10, which stands for the channels
        window_startr1 = x.tick_position+R1_delay+front_filter;
        window_endr1 = window_startr1 + sampling_window;

        windowsr1 = Data{x.record}(channels_to_use, window_startr1:window_endr1);
        maxminr1 = max(windowsr1, [],2) - min(windowsr1,[],2);

        window_startr2 = x.tick_position+R2_delay+front_filter;
        window_endr2 = window_startr2 + sampling_window;

        windowsr2 = Data{x.record}(channels_to_use, window_startr2:window_endr2);
        maxminr2 = max(windowsr2, [],2) - min(windowsr2,[],2);
%   Store this information to maxminr1 field of comments
        comments(i).maxminr1 = maxminr1;
        comments(i).maxminr2 = maxminr2;
    %else, the fields are empty --> []

    end 
end

fprintf('\n ===== Raw Peak to Peak Data Calculated =====\n\n' );


clearvars R1_delay R2_delay windowsr2 windowsr1 maxminr2 maxminr1 x i window_size

%% Maxmin calculation

%TODO: make sure that the positional comments are integrated into the name
%of the stimulations


%   Then, while averaging each max-min, merge elements with same record, amplitude,
%   and stimulation

% Output 

fprintf('\n ===== Calculating Peak to Peak related data =====\n\n' );

lastamp = 1;
last_loc = '';


rows_to_remove = [];

for i = 1:numel(comments)
    x = comments(i);
    if ischar(x.str)
        if strcmp(x.str, 'stim')
            comments(lastamp).sumr1 = comments(lastamp).sumr1 + x.maxminr1;
            comments(lastamp).sumr2 = comments(lastamp).sumr2 + x.maxminr2;
            comments(lastamp).count = comments(lastamp).count + 1;
            comments(lastamp).record_name = last_loc;
        else 
            last_loc = x.str;
            rows_to_remove(end+1) = i;
        end

    elseif isnumeric(x.str)
        lastamp = i;
        comments(lastamp).sumr1 = 0;
        comments(lastamp).sumr2 = 0;
        comments(lastamp).count = 0;
        comments(lastamp).record_name = '';
       
    end 
end

%Remove irrelevant rows from filtered comments

comments(rows_to_remove) = [];

%Outputting

%filter array to only have amplitude left
%TODO, change the name output here 
output = comments(arrayfun(@(x) isnumeric(x.str), comments));

%Sanity check
% if len(output.averager1) == len(channels_to_use)

% else fprintf('\n ERROR! Mismatch between channels \n\n')

% end
fprintf('\n ===== Relevant Data Calculated =====\n\n' );

clearvars lastamp

%% Data cleaning

fprintf('\n ===== Preparing Output =====\n\n' );


%Calculate average & store into new struct 
channel_names = string({channel_meta(channels_to_use).name});


% Assume each amp value has the "record_name" field 
record_names = unique({output.record_name}); %For some reason this gives you results in a very random order

% Final Calculation
newstructr1 = struct( 'amps', {output.str});
newstructr2 = struct( 'amps', {output.str});


for i = 1:numel(output)
    output(i).averager1 = output(i).sumr1 / output(i).count;
    output(i).averager2 = output(i).sumr2 / output(i).count;
    newstructr1(i).("record_name") = output(i).record_name;
    newstructr2(i).("record_name") = output(i).record_name;

    for j = 1:numel(output(i).averager1)
        %store into new struct 
        % TODO: add parameters that indicate which fields are needed

        % TODO: add checks to include other information

        newstructr1(i).(channel_names(j)) = output(i).averager1(j);
        newstructr2(i).(channel_names(j)) = output(i).averager2(j);
    end
end 

clearvars x i maxminr1 j 

%% Exporting to Excel 

exportnames = ['Output/outputr1.csv, ' ' Output/outputr2.csv'];

fprintf(['\n ===== exporting as ' exportnames ' =====\n\n'] );


%Convert to table to csv & export
outr1 = struct2table(newstructr1);
writetable(outr1, "Output/outputr1.csv");

outr2 = struct2table(newstructr2);
writetable(outr2, "Output/outputr2.csv");

fprintf('\n Done! \n\n')

%% R2/R1 ratio
fprintf('\n ===== detected R2/R1 ratio boolean, calculating... ===== \n\n' );

outratio = outr2; % Initialize the new table with outr1's structure
outratio{:, channels_to_use} = outr2{:, channels_to_use} ./ outr1{:, channels_to_use}; % Element-wise division

outrationame = 'Output/outputr2r1ratio.csv';
writetable(outratio, outrationame);
fprintf(['\n ===== R2R1 ratio output to ' outrationame ' ===== \n\n'] );

%% Plotting

%incorporate plotting in the next draft. 
fprintf(['\n ===== Plotting ===== \n\n'] );

PlotRC(outr1, record_names,0,0,0);


%% Plot R2R1
% fprintf(['\n ===== Plotting Ratio ===== \n\n'] );
% PlotRC(outratio, record_names,1,1,1);

end
%% Drafting Ground
rows = 3:10; % Example array of specific rows you want
newCell = cellfun(@(x) x(rows, :), data, 'UniformOutput', false);
plot(newCell{2}(3, :)); % 3rd row of the 2nd cell
xlabel('Column Index');
ylabel('Value');
title('Plot of 3rd Row from 2nd Cell');

