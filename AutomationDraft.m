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


%% Load data

%first, load AlexChart processed data 

load("Dr Sayenko Lab.mat"); % TODO: replace this, eventually, with AlexChart 

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


%% Meat of the File

%For records 6,12,15 (** Need to generalize)
% TODO: find a way to automatically locate records we care about 

% *** also, **sort** according to records first, then tick position
% currently everything is sorted in workspace 
% TODO: add code that sort according to records then tick position

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


% TODO: Clean up output, s.t. it only contains info we need 
% TODO: add parameters that indicate which fields are needed

%Convert to table to csv & export
out = struct2table(output);
writetable(out, "output.csv");

%incorporate plotting in the next draft. 
%TODO: incorporate plotting and the extraction whereof. 





%% Drafting Ground
