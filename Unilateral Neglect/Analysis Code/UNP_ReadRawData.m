function data = UNP_ReadRawData ( rats, vns, stages, datapath )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TBI_FetchRatData.m
% Author: David Pruitt
% 
% This code is modified from ArdyMotor_Pull_Analysis.
% The purpose of this code is to take as input a list of rats, and output
% a matrix which contains all of the session data for each rat.
%
% Parameters:
%   rats = a list of rat names.  
%               Ex: rats = {'TBI2', 'TBI3', 'TBI9'};
%   vns = a binary array indicating if a rat has received VNS.
%               Ex: vns = [1 0 0];
%   stages = a list of stages that we want to load from each rat's dataset
%               Ex: stages = {'P8','P9'};
%   datapath = a fully qualified path name to where the datasets for each
%               rat are stored
%               Ex: datapath = 'Z:\Navid_Behavior_Data\'; 
%
% Modifications made in this code file from the original
% ArdyMotor_Pull_Analysis:
%   - I changed the code such that it takes the above variables as function
%   parameters, making the code thus more modular
%   - I also changed the code to not "cd" into every folder in order to
%   find data files of rats.  This was causing Matlab's current path to
%   change, which is annoying.  I have changed the code to use fully
%   qualified path names when searching for data files and opening data
%   files.
%   - The resulting dataset is returned from the function as a structure.
%   The structure itself is unchanged from the previous code.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Define an empty variable which will hold the data
data = [];

%Iterate through each rat and each stage in order to find all the
%subfolders that contain the data we will need to load into the analysis
%program
subfolders = {};                                                            
for r = rats                                                                
    for s = stages                                                          
        if exist([datapath r{1} '\' r{1} '-Stage' s{1}],'dir')              %If the stage folder exists for this rat...
            subfolders{end+1} = [datapath r{1} '\' r{1} '-Stage' s{1}];     %Save the name of this subfolder.
        end
    end
end 

%Iterate over all the subfolders, and load in each data file
for i = 1:length(subfolders)                                
    
    %Get the list of files that are contained in the subfolder for this rat
    %and stage.
    files = dir([subfolders{i} '\*.ArdyNeglect']);
    
    for f = 1:length(files)               
        %Prepend the directory name to the file name so we can use it to
        %actually open the file and read from it.  We will call this the 
        %"qualified name".
        files(f).qualified_name = [subfolders{i} '\' files(f).name];
        
        %Debug message for the user to know we are reading specific files
        disp(['Reading: ' files(f).name]);
        
        %Read the data file into a temporary variable
        temp = ArdyNeglectFileRead(files(f).qualified_name);                           
        
        %We now check to see if this data file contains any completed
        %trials.  
        if isfield(temp,'trial') && ~isempty(temp.trial)                    
            
            %Make sure that rat naming conventions conform to what we want.
            %If a rat's name contains a hyphen, let's replace it with an
            %underscore
            temp.rat = temp.rat';
            temp.rat(temp.rat == '-') = '_';                                
            
            %We need to fetch some important information from the
            %datafile's filename - such as the experimental condition.
            %Let's do so now.
            index = strcmpi(temp.rat,rats);                                 %Find the index for the current rat.
            a = strfind(files(f).name,'Stage');                             %Find the word stage in the filename.
            b = find(files(f).name == '_');                                 %Find all of the underscores in the filename.
            b = b(find(b > a,1,'first')) - 1;                               %Find the first underscore after the word "Stage".
            condition = files(f).name(a:b);                                 %Find the experimental condition for the session.
            temp.rat(1:find(temp.rat == '_',1,'last')) = [];                %Take the experimental condition out of the rat's name.     
            
            %If this is the first datafile for a rat, we need to extend our
            %"data" variable to be able to contain this new rat.
            %We can then save the session data in the variable
            if ~isfield(data,'ratname') || ...
                    ~any(strcmpi(temp.rat,{data.ratname}))                  %If this the first file or a new rat...
                r = length(data) + 1;                                       %Make a new index for this rat.
                s = 1;                                                      %Save this session as the first session.
                data(r).ratname = temp.rat;                                 %Save this rat's name in the structure.
                data(r).vns = vns(index);                                   %Save whether this rat got VNS or not.
            else                                                            %Otherwise...
                r = find(strcmpi(temp.rat,{data.ratname}));                 %Find the index for this rat.
                s = length(data(r).session) + 1;                            %Make a new session for this rat.
            end                
            
            %Save all the data for this session and rat
            data(r).session(s) = temp;
        end
    end
end

%Now that we have loaded all the datafiles for each rat, let's iterate
%through all of our rats and make sure the sessions are ordered
%chronologically
for r = 1:length(data)                                                      %Step through each rat.
    timestamps = zeros(1,length(data(r).session));                         	%Pre-allocate an array to hold session timestamps.
    for s = 1:length(data(r).session)                                       %Step through each session for this rat.
        timestamps(s) = data(r).session(s).trial(1).start_time;              %Grab the first trial timestamp for this session.
    end
    [timestamps, i] = sort(timestamps);                                     %Sort the timestamps, returning the sorted indices.
    data(r).session = data(r).session(i);                                   %Use the sorted indices to reorder the sessions chronologically.
end

