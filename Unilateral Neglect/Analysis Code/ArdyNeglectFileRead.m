function data = ArdyNeglectFileRead ( file )
% ArdyNeglectFileRead.m
% Reads behavior data for the unilateral neglect project from *.ArdyNeglect
% files.

%Initialize data to be an empty matrix
data = [];

%Open the data file, and rewind to the beginning of the file
fid = fopen(file, 'r');
fseek(fid, 0, -1);

%Read in the first byte, which is our version identifier
temp = fread(fid, 1, 'int8');
if temp == -1 || temp == -3 || temp == -4
    %If this is version 1 of the neglect data
    
    %Read the file header
    if (temp <= -3)
        data.daycode = fread(fid, 1, 'double');
    else
        data.daycode = fread(fid, 1, 'uint16');
    end
    
    data.booth = fread(fid, 1, 'uint8');
    
    N = fread(fid, 1, 'uint8');
    data.rat = fread(fid, N, '*char');
    
    N = fread(fid, 1, 'uint8');
    data.stage = fread(fid, N', '*char');
    
    %Read each trial from the file
    while ~feof(fid)
        %Read the trial number.  If one doesn't exist, skip execution of
        %the loop
        trial = fread(fid, 1, 'uint32');
        if (isempty(trial))
            continue;
        end
        
        %Read the trial data
        result = fread(fid, 1, 'uint8');
        start_time = fread(fid, 1, 'float64');
        finish_time = fread(fid, 1, 'float64');
        cue_time = fread(fid, 1, 'float64');
        
        if (temp <= -3)
            cue_duration = fread(fid, 1, 'float64');
        else
            cue_duration = 1000;
        end
        
        if (temp <= -4)
            cue_intensity = fread(fid, 1, 'uint8');
            distractor_intensity = fread(fid, 1, 'uint8');
        else
            cue_intensity = 1;
            distractor_intensity = 0;
        end
        
        hit_window = fread(fid, 1, 'float32');
        side = fread(fid, 1, 'float32');
        
        %Save everything in the data structure
        try
            data.trial(trial).result = result;
        catch e
            e
        end
        data.trial(trial).start_time = start_time;
        data.trial(trial).finish_time = finish_time;
        data.trial(trial).cue_time = cue_time;
        data.trial(trial).cue_duration = cue_duration;
        data.trial(trial).cue_intensity = cue_intensity;
        data.trial(trial).distractor_intensity = distractor_intensity;
        data.trial(trial).hit_window = hit_window;
        data.trial(trial).side = side;
    end
end
    

fclose(fid);

end

