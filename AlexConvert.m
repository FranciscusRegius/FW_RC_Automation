function newfilepath = AlexConvert(path1, savepath)
    %Alternatively, output the 5 data structs that I need to use

    % ADI Convert creates a file that is just awful. Each channel gets its own
    % variable and each recording gets its own variable, we can do better.
    % We have the technology. This code SHOULD combine all the channels from
    % the same session (when the recording was stopped). The output will be a
    % structure similar to the EEG structure I like so much.
    
    % Written by Alexander G. Steele
    % 15 July 2022
    % Modified by Fengyuan Wang 12/30 2024 to fix 
    
    % You need to run adi.convert first and import the data that it outputs.
    % adi.convert converts Labchart files to MATLAB files (poorly), but we can
    % fix it, we have the technology!

    % This modified version of the code requires a specific path input and
    % should be only called in the Automation.m file. 
    
    %TODO: make sure there are no more TODOs remaining in this file before
    %moving on to the rest of automation draft
        
    %TODO: understand how this file locating works, and understand the
    %filepath manipulation

    % % Locating the files...
    % % The full path is the full path to the folder broken into a cell array
    % fullpath = strsplit(cd, filesep);
    % % Parent is the full path, but in text format
    % parent   = fullfile(fullpath{1:end},filesep);
    % % Get all Labchart files (should be just one!!!!)
    % files    = dir([parent '\*.adicht']);
    
    %% Step 1: Now with adi.convert step!
    
    %TODO: add a try catch for if non-fullpath, look for parent + input +
    %files(1).name. Perhaps also add a confirmation s.t. if a bad path is
    %entereed it prompts and asks if they want the correct file ...
    % But this should not be necssary with drag n' drop
    fprintf('\n===== Step 1: Convert the data! =====\n\n');
    
    % This is an awesome utility, that has a horrible output...
    % TODO: make sure this readas from Input 

    adi.convert(path1); 
    
    fprintf('\n Done...\n\n');
    
    %% Step 1.5: Load the created file (since the api is dumb)
    
    fprintf('\n===== Step 1.5: Load the data! =====\n\n');
    
    matfile_name = strsplit(path1, ".");
    load(matfile_name(1) + ".mat");
    
    fprintf('\n Done...\n\n');
    
    %% Step 2: Figure out what variables we have (again this is so dumb...)
    
    fprintf('\n===== Step 2: Find the data! =====\n\n');
    
    % First we query the workspace to figure out what exists.
    s = whos;
    
    % Next we find all the instances where we actually have some sort of data
    % because there are a lot of other variables that come with this that you
    % need to sort through.
    % Preallocating so MATLAB stops trying to parent me
    datalist = zeros(size(s,1),1);
    
    for i = 1:size(s,1)
    datalist(i) = strncmpi(s(i).name,'data__',6);
    end
    
    % Next we remove all the variables that aren't the dataset we are
    % interested in from the datalist structure
    s(datalist == 0) = [];
    
    % Now we can finally figure out how many times we stopped our recording,
    % which is really just the max rec number.
    recs = file_meta.n_records;
    
    fprintf('\n Done...\n\n');
    
    %% Step 3: Reorganize our data to something more orderly (still dumb!)
    
    
    fprintf('\n===== Step 3: Reorganize the data! =====\n\n');
    
    % Now that we know the number of splits, we inherently know the number of
    % channels (variables/splits = channels). With that we don't even need to
    % determine the value because this will be a robust solution without that
    % information. At least... I think...?? Found a better way! The file_meta
    % data has number of channels listed! Woo!
    
    % Number of channels
    chans = file_meta.n_channels;
    
    % Preallocating for MATLAB
    Data{1,recs} = [];
    
    for i = 1:recs
        % Preallocating so MATLAB stops complaining at me
        ChanMatrix = zeros(chans,size(eval(['data__chan_', num2str(2), '_rec_', num2str(i)]),1));
        for ii = 1:chans
            % Sort our data, I know eval isn't a "good practice" but neither is
            % having a ton of varaibles for data that could be easily
            % oraganized.
            ChanMatrix(ii,:) = double(eval(['data__chan_', num2str(ii), '_rec_', num2str(i)]));
        end
        % Toss it all into a nice little cell matrix
        Data{1,i} = ChanMatrix;
        clearvars ChanMatrix
    end
    
    fprintf('\n Done...\n\n');
    
    % Just because I can...
    clearvars data__* i ii chans recs s recs datalist channel_version comment_version data_version record_version file_version
    
    %% Step 4: Reformatting our data!
    
    % Now we have a cell matrix of our data nicely organized, why the person
    % didn't do this to begin with is beyond me and outside the scope of this
    % code. Now we can create a structure that makes some actual sense.
    
    fprintf('\n===== Step 4: Package the data! =====\n\n');
    
    % See how this works yet?
    Labchart.channel_meta = channel_meta;
    Labchart.record_meta  = record_meta;
    Labchart.comments     = comments;
    Labchart.file_meta    = file_meta;
    Labchart.Data         = Data;

    % Boom! 
    fprintf('\n Done...\n\n');
    
    %% Step 5: Save our data!!
    
    fprintf('\n===== Step 5: Save the data! =====\n\n');
    
    % FINAL STEP - SAVE DATA!!!
    % TODO: change save name s.t. it gets saved in Input folder
    
    [~,child] = fileparts(matfile_name(1));     

    newfilepath = strcat(savepath, filesep, 'Input', filesep, child, '.mat');
    save(newfilepath,'Labchart');
    % save([savedir,savename '.set'],'EEG')
    
    fprintf('\n Done...\n\n');

end