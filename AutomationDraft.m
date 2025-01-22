% function AutomationDraft(file_name)
% Automation Draft
% labchart = adi.readFile("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% Figure out how to load adiconvert 


%% List of parameters 

% window_size: a numbers in ms - the size of the window, after each stimulation, wherein we look for the peak to peak
%   % TODO: add an option to manually adjust window_size 
% Delay: number in ms, the delay between admitted stimulation and the beginning of the sampling window
% bool_normalize: boolean whether or not to normalize the data, default true for now
bool_normalize = 1; 
% if nargin < 1
    file_name = '20241007 RTA003 EPA 2 RC Only francis'; % Add a function that 
% end
path = [cd, '\Input\', file_name];
% channels_to_use: allows choice of whcih channels to process; default to
% all channels other than 1&2
channels_to_use = 3:10;
window_size = 100;
R1_delay = 130;
R2_delay = window_size + R1_delay;


fprintf(['\n ===== Opening file ' file_name ' with Alex Chart =====\n\n'] );

% path = 'C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\FW_RC_Automation\20240826_RTA006_EPA1_RC ONLY.adicht'  ; %DEBUGGING:
% TODO: Add a check to make sure takes you to a .adicht or .mat file 


%% Preprocessing
% TODO: make sure Adi is laoded into the workspace
% TODO: make sure Adi is installed for the user 
%%adi.convert("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

%%TODO: Find whatever adi's path is and add path to matlab path 
% adi_path = [cd filesep ''];
addpath adinstruments_sdk_matlab-master %Code

% DONE: run AlexConvertFile
newfilepath = AlexChart(path); % This should load everything into workspace 
% TODO: make sure AlexConvertFile is installed for the user, perhaps
% incorporate his script into mine DONE: this is now a helper function in the
% github

%% Load data

%first, load AlexChart processed data 

load(newfilepath); % DONE: replace this, eventually, with AlexChart 


%% Extract Labchart Fields
% DONE: Saving and loading -- Decicde whether to have the data directly output by AlexChart function or save & load 
Data = Labchart.Data          ;
file_meta =Labchart.file_meta     ;
comments =Labchart.comments      ;
record_meta =Labchart.record_meta   ;
channel_meta = Labchart.channel_meta  ;

fprintf('\n ===== New file loading completed =====\n\n' );

clearvars Labchart


%% Stimulation Location Determination
% DONE
% 1. identify the peaks in channel 2
    % This is done by normalizing channel 2 to be 0 to 1, every spot
    % greater than .8 is going to be a stimulation
    % associate the amplitude comment to the nearest 2 stimulations 
    % Alternatively, assuming that channel 2 format is standard, we can
    % forgo normalizing and just find spots greater than 1
% 3. notate each stimulation in the comments section  

% determine the records we care about, to reduce running time 
relevant_records = unique([comments.record]);

% Go through each relevant record and determine all the stimulations by
% looking at channel 2
% Then add each of the stimulations to comments
for idx = 1:length(relevant_records)
    i = relevant_records(idx);

    % extract channel 2 in the given record
    chnl2 = Data{1,i}(2,:); % ith column of the Data cell, everything in row 2

    % find the indices of stimulations as a list (i.e. tick position) 
    indices = find(chnl2 > 2); 
    if width(indices) == 0
        continue
    end

    %Remove repetitive stimulations
    diffs = diff(indices);
    boundaries = [1 , find(diffs>3) + 1];
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


clearvars filtered_indices indices diffs boundaries i idx j 

%% Record autodetermination
% TODO
% Determine which records to use automatically, based on record size 


%% Filter away repetitive comments
% Create unique keys for all elements in comments
fprintf('\n ===== Filtering Comments =====\n\n' );

keys = arrayfun(@(x) sprintf('%s_%d_%s', x.str, x.tick_position, x.record), comments, "UniformOutput",false);

%find unique elements based on the keys
[~, uniqueIdx] = unique(keys, 'stable');

% FInally, filter out repetitions 
filteredComments = comments(uniqueIdx);

clearvars keys uniqueIdx


%% Format data

fprintf('\n ===== Formatting Data =====\n\n' );

% Convert all amplitudes into double from string
for i = 1:numel(filteredComments)
    %First, filter out everything in the "str" field that is not a double
    if ~isempty(regexp(filteredComments(i).str, '^-?\d+$', 'once'))
        filteredComments(i).str = str2double(filteredComments(i).str);
    end
end

%Sort data first accroding to record, then according to tick_position
record = [filteredComments.record];
tick_pos = [filteredComments.tick_position];

[~,sortIdx] = sortrows([record(:), ...
                tick_pos(:)], ...
                [1,2]);
filteredComments = filteredComments(sortIdx);

clearvars sortIdx tick_pos record


%% Peak to peak calculation

fprintf('\n ===== Extracting Useful Records =====\n\n' );

%For records 6,12,15 (** Need to generalize)
%TODO: Figure out how to determine this for other datasets
% PLAN: identify the most prominent records (statistically) and set those
% as records
records = [6,12,15];
% record_names =  ;
% TODO: add a pritn statement to show which records are chosen 

% TODO: find a way to automatically locate records we care about 
filteredComments = filteredComments(arrayfun(@(x) ismember(x.record,[6,12,15]), filteredComments));


fprintf('\n ===== Finding Peak to Peak =====\n\n' );

% For each comment:
for i = 1:numel(filteredComments)
    if ischar(filteredComments(i).str)
        x = filteredComments(i);
%For each stimulation under the amplitude
%   Find in data{record}, the max - min in the area tick+130 to tick+230
        % DONE: parameterize 3:10, which stands for the channels
        windowsr1 = Data{x.record}(3:10, x.tick_position+R1_delay:x.tick_position+R2_delay);
        maxminr1 = max(windowsr1, [],2) - min(windowsr1,[],2);

        windowsr2 = Data{x.record}(3:10, x.tick_position+R2_delay:x.tick_position+R2_delay+window_size);
        maxminr2 = max(windowsr2, [],2) - min(windowsr2,[],2);
%   Store this information to maxminr1 field of filteredcomments
        filteredComments(i).maxminr1 = maxminr1;
        filteredComments(i).maxminr2 = maxminr2;
    %else, the fields are empty --> []

    end 
end

fprintf('\n ===== Raw Peak to Peak Data Calculated =====\n\n' );


clearvars R1_delay R2_delay windowsr2 windowsr1 maxminr2 maxminr1 x i window_size

%% Maxmin calculation


%   Then, while averaging each max-min, merge elements with same record, amplitude,
%   and stimulation

% Output 

fprintf('\n ===== Calculating Peak to Peak related data =====\n\n' );

lastamp = 1;



for i = 1:numel(filteredComments)
    x = filteredComments(i);
    if ischar(x.str)
        filteredComments(lastamp).sumr1 = filteredComments(lastamp).sumr1 + x.maxminr1;
        filteredComments(lastamp).sumr2 = filteredComments(lastamp).sumr2 + x.maxminr2;
        filteredComments(lastamp).count = filteredComments(lastamp).count + 1;
        filteredComments(lastamp).record_name = x.str;

    elseif isnumeric(x.str)
        lastamp = i;
        filteredComments(lastamp).sumr1 = 0;
        filteredComments(lastamp).sumr2 = 0;
        filteredComments(lastamp).count = 0;
        filteredComments(lastamp).record_name = '';
       
    end 
end

%Outputting

%filter array to only have amplitude left
%TODO, change the name output here 
output = filteredComments(arrayfun(@(x) isnumeric(x.str), filteredComments));

%Sanity check
% if len(output.averager1) == len(channels_to_use)

% else fprintf('\n ERROR! Mismatch between channels \n\n')

% end
fprintf('\n ===== Relevant Data Calculated =====\n\n' );

clearvars lastamp

%% Data cleaning

fprintf('\n ===== Preparing Output =====\n\n' );


% DONE: Clean up output, s.t. it only contains info we need 

%Calculate average & store into new struct 
channel_names = string({channel_meta(3:10).name});


% Assume each amp value has the "record_name" field 
record_names = string(unique({output.record_name}));




%% Old Data Cleaning
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
outratio{:, 3:10} = outr2{:, 3:10} ./ outr1{:, 3:10}; % Element-wise division

outrationame = 'Output/outputr2r1ratio.csv';
writetable(outratio, outrationame);
fprintf(['\n ===== R2R1 ratio output to ' outrationame ' ===== \n\n'] );

%% Plotting

%incorporate plotting in the next draft. 
PlotRC(outr1, record_names,1,0,0);
%TODO: render the data range variable obsolete

% Plot each channel separately (for channel in list of channels plot
% plot(amplitude, channel data) --> this way, channel data (in intensity)
% will be plotted with each channel representing a different line

%% Plot R2R1
PlotRC(outratio, record_names,1,1,1);
% DONE: Incorporate ratio plot into normal RC plot, instead just plotting
% the outratio file 


%% Drafting Ground
% end