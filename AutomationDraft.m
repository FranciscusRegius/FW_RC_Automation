% Automation Draft
% labchart = adi.readFile("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");

% Figure out how to load adiconvert 

adi.convert("C:\Users\fengy\Desktop\HM\Dr Sayenko Lab\20240826_RTA006_EPA1_RC ONLY.adicht");


% Runs AlexConvertFile


%% Load data

%first, load AlexChart processed data 

load("Dr Sayenko Lab.mat"); % replace this, eventually, with AlexChart 

% 
Data = Labchart.Data          ;
file_meta =Labchart.file_meta     ;
comments =Labchart.comments      ;
record_meta =Labchart.record_meta   ;
channel_meta = Labchart.channel_meta  ;

clearvars Labchart

%% Extract Data

% time ticks in comments (should be 40:120:10, with 3 of each
% Extract into a cell, each numeric comment, with their corresponding
% channel and tick number. The cell should be 3 by 3*(120-40)/10

%Filter away repetitive comments
% Create unique keys for all elements in comments
keys = arrayfun(@(x) sprintf('%s_%d_%s', x.str, x.tick_position, x.record), comments, "UniformOutput",false);

%find unique elements based on the keys
[~, uniqueIdx] = unique(keys, 'stable');

% FInally, filter out repetitions 
filteredComments = comments(uniqueIdx);

clearvars keys uniqueIdx


%% Format data
for i = 1:numel(filteredComments)
    if ~isempty(regexp(filteredComments(i).str, '^-?\d+$', 'once'))
        filteredComments(i).str = str2double(filteredComments(i).str);
    end
end
%Extract amplitude comments 
% AmplitudeComments = filteredComments(arrayfun(@(x) ~isempty(regexp(x.str, '^-?\d+$', 'once')), filteredComments));

% for i = 1:numel(AmplitudeComments)
%     AmplitudeComments(i).str = str2double(AmplitudeComments(i).str);
% end


%% Meat of the File


%For records 6,12,15 (** Need to generalize)

% *** also, **sort** according to records first, then tick position
% currently everything is sorted in workspace 

% For each comment:
for i = 1:numel(filteredComments)
    if ischar(filteredComments(i).str)
        x = filteredComments(i);
%For each stimulation under the amplitude
%   Find in data{record}, the max - min in the area tick+130 to tick+230
        windows = Data{x.record}(3:10, x.tick_position+130:x.tick_position+230);
        maxmin = max(windows, [],2) - min(windows,[],2);
%   Store this information to maxmin field of filteredcomments
        filteredComments(i).maxmin = maxmin;

    %else, the fields are empty --> []

    end 
end
%%

filteredComments = filteredComments(arrayfun(@(x) ismember(x.record,[6,12,15]), filteredComments));

%   Then, while averaging each max-min, merge elements with same record, amplitude,
%   and stimulation

% Output 
lastamp = 1;

for i = 1:numel(filteredComments)
    x = filteredComments(i);
    if ischar(x.str)
        filteredComments(lastamp).sum = filteredComments(lastamp).sum + x.maxmin;
        filteredComments(lastamp).count = filteredComments(lastamp).count + 1;

    elseif isnumeric(x.str)
        lastamp = i;
        filteredComments(lastamp).sum = 0;
        filteredComments(lastamp).count = 0;
       
    end 
end

%Outputting

%filter array to only have amplitude left
output = filteredComments(arrayfun(@(x) isnumeric(x.str), filteredComments));

%Calculate average 
for i = 1:numel(output)
    output(i).average = output(i).sum / output(i).count;
end 

%% Export into excel 


%Clean up output, s.t. it only contains info we need **PARAMETRIZE



%Convert to table to csv & export
out = struct2table(output);
writetable(out, "output.csv");

%incorporate plotting in the next draft. 

%% Drafting Ground

% %find all the peaks of channel2
% channel2 = Data{1,6}(2,:);
% indices = find(channel2 > 1);

%As such, it seems like the window should be about 100 ticks 
isnumeric(filteredComments(1).str)