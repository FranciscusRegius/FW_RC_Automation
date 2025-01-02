% Automation Draft
% labchart = adi.readFile("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% Figure out how to load adiconvert 


%% Prepatory
% TODO: make sure Adi is laoded into the workspace
% TODO: make sure Adi is installed for the user 
adi.convert("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% TODO: run AlexConvertFile
% TODO: make sure AlexConvertFile is installed for the user, perhaps
% incorporate his script into mine

%% List of parameters 

% window_size: a numbers in ms - the size of the window, after each stimulation, wherein we look for the peak to peak
% Delay: number in ms, the delay between admitted stimulation and the beginning of the sampling window
% bool_normalize: boolean whether or not to normalize the data, default true for now
bool_normalize = 1; 


%% Load data

%first, load AlexChart processed data 

load("Input/Dr Sayenko Lab.mat"); % TODO: replace this, eventually, with AlexChart 

% 
Data = Labchart.Data          ;
file_meta =Labchart.file_meta     ;
comments =Labchart.comments      ;
record_meta =Labchart.record_meta   ;
channel_meta = Labchart.channel_meta  ;

clearvars Labchart

%% Extract Data

%Filter away repetitive comments
% Create unique keys for all elements in comments
keys = arrayfun(@(x) sprintf('%s_%d_%s', x.str, x.tick_position, x.record), comments, "UniformOutput",false);

%find unique elements based on the keys
[~, uniqueIdx] = unique(keys, 'stable');

% FInally, filter out repetitions 
filteredComments = comments(uniqueIdx);

clearvars keys uniqueIdx


%% Format data
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

%For records 6,12,15 (** Need to generalize)
% TODO: find a way to automatically locate records we care about 
filteredComments = filteredComments(arrayfun(@(x) ismember(x.record,[6,12,15]), filteredComments));


window_size = 100;
R1_delay = 130;
R2_delay = window_size + R1_delay;


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

%Convert to table to csv & export
outr1 = struct2table(newstructr1);
writetable(outr1, "outputr1.csv");

outr2 = struct2table(newstructr1);
writetable(outr2, "outputr2.csv");


%% Plotting

%incorporate plotting in the next draft. 
%DONE: incorporate plotting and the extraction whereof. 
%DONE: Draft plotting 
%TODO: Parameterize, and make this into a function


% Plot each channel separately (for channel in list of channels plot
% plot(amplitude, channel data) --> this way, channel data (in intensity)
% will be plotted with each channel representing a different line




%% Drafting Ground
PlotRC(outr1, 9, 3, 0);