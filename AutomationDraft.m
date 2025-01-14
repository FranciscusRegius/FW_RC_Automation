% Automation Draft
% labchart = adi.readFile("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% Figure out how to load adiconvert 


%% List of parameters 

% window_size: a numbers in ms - the size of the window, after each stimulation, wherein we look for the peak to peak
% Delay: number in ms, the delay between admitted stimulation and the beginning of the sampling window
% bool_normalize: boolean whether or not to normalize the data, default true for now
bool_normalize = 1; 
file_name = '20240826_RTA006_EPA1_RC ONLY';
path = [cd, '\Input\', file_name];

fprintf(['\n ===== Opening file ' file_name ' with Alex Chart =====\n\n'] );

% path = 'C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\FW_RC_Automation\20240826_RTA006_EPA1_RC ONLY.adicht'  ; %DEBUGGING:
% TODO: Add a check to make sure takes you to a .adicht or .mat file 


%% Preprocessing
% TODO: make sure Adi is laoded into the workspace
% TODO: make sure Adi is installed for the user 
%%adi.convert("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

%%TODO: Find whatever adi's path is and add path to matlab path 
% addpath adi_path %Code

% DONE: run AlexConvertFile
newfilepath = AlexChart(path); % This should load everything into workspace 
% TODO: make sure AlexConvertFile is installed for the user, perhaps
% incorporate his script into mine DONE: this is now a helper function in the
% github

%% Load data

%first, load AlexChart processed data 

load(newfilepath); % DONE: replace this, eventually, with AlexChart 

% TODO: Decicde whether to have the data directly output by AlexChart function or save & load 
Data = Labchart.Data          ;
file_meta =Labchart.file_meta     ;
comments =Labchart.comments      ;
record_meta =Labchart.record_meta   ;
channel_meta = Labchart.channel_meta  ;

clearvars Labchart

%% Extract Data

%Filter away repetitive comments
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

% Convert all amplitudes into double from string, idk why i dont do int
for i = 1:numel(filteredComments)
    if ~isempty(regexp(filteredComments(i).str, '^-?\d+$', 'once'))
        filteredComments(i).str = str2double(filteredComments(i).str);
    end
end

%Sort data first accroding to record, thena ccording to tick_position
record = [filteredComments.record];
tick_pos = [filteredComments.tick_position];

[~,sortIdx] = sortrows([record(:), ...
                tick_pos(:)], ...
                [1,2]);
filteredComments = filteredComments(sortIdx);

clearvars sortIdx tick_pos record

%% Meat of the File

fprintf('\n ===== Extracting Useful Records =====\n\n' );

%For records 6,12,15 (** Need to generalize)
% TODO: find a way to automatically locate records we care about 
filteredComments = filteredComments(arrayfun(@(x) ismember(x.record,[6,12,15]), filteredComments));


window_size = 100;
R1_delay = 130;
R2_delay = window_size + R1_delay;

fprintf('\n ===== Finding Peak to Peak =====\n\n' );

% For each comment:
for i = 1:numel(filteredComments)
    if ischar(filteredComments(i).str)
        x = filteredComments(i);
%For each stimulation under the amplitude
%   Find in data{record}, the max - min in the area tick+130 to tick+230
        % TODO: parameterize 3:10, which stands for the channels
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

clearvars R1_delay R2_delay windowsr2 windowsr1 maxminr2 maxminr1 x i window_size

%%


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

    elseif isnumeric(x.str)
        lastamp = i;
        filteredComments(lastamp).sumr1 = 0;
        filteredComments(lastamp).sumr2 = 0;
        filteredComments(lastamp).count = 0;
       
    end 
end

%Outputting

%filter array to only have amplitude left
%TODO, change the name output here 
output = filteredComments(arrayfun(@(x) isnumeric(x.str), filteredComments));
clearvars lastamp

%% Data cleaning

fprintf('\n ===== Calculation complete, preparing output =====\n\n' );


% DONE: Clean up output, s.t. it only contains info we need 

%Calculate average  & store into new struct 
newstructr1 = struct( 'str', {output.str});
newstructr2 = struct( 'str', {output.str});


for i = 1:numel(output)
    output(i).averager1 = output(i).sumr1 / output(i).count;
    output(i).averager2 = output(i).sumr2 / output(i).count;

    for j = 1:numel(output(i).averager1)
        %store into new struct 
        % TODO: add parameters that indicate which fields are needed

        % TODO: add checks to include other information

        newstructr1(i).("EMG_Chn_" + int2str(j) + "_r1") = output(i).averager1(j);
        newstructr2(i).("EMG_Chn_" + int2str(j) + "_r2") = output(i).averager2(j);
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
outratio{:, 2:9} = outr2{:, 2:9} ./ outr1{:, 2:9}; % Element-wise division

outrationame = 'Output/outputr2r1ratio.csv';
writetable(outratio, outrationame);
fprintf(['\n ===== R2R1 ratio output to ' outrationame ' ===== \n\n'] );

%% Plotting

%incorporate plotting in the next draft. 
PlotRC(outr1, 9, 3, 1,0);

% Plot each channel separately (for channel in list of channels plot
% plot(amplitude, channel data) --> this way, channel data (in intensity)
% will be plotted with each channel representing a different line
% TODO: make this more intuitive... see other file. 

%% Plot R2R1
PlotRatioRC(outratio,9,3,0,0);


%% Drafting Ground
