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

%Pltoting

figure;
hold on;

%First, extract x-axis (str.values)
range = 19:27;
x = outr1.str(range);


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

%Then, for each of the rest of the str columns/for each "EMG_chn_" + i + "r1"
    % channel = outr1.("EMG_Chn_" + i + "_r1")
    % plot(x, channel, ....)   

for i = 1:8
    channel = outr1.("EMG_Chn_" + i + "_r1");
    channel = channel(range);
    plot(x, channel, "DisplayName","EMG Chn " + i + " r1");
end
% As such, the data structure must treat each channel as a separate object

% Customize plot
title('Recruitment Curve');
xlabel('amplitudes');
ylabel('Intensity - Volts');
legend('Location','best'); % or best outside;
grid on;
hold off;

saveas(gcf, 'plot3.png');



%% Drafting Ground
PlotRC(outr1, 9, 3, 0);