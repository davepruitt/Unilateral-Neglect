function popdata = UNP_TransformToPopulationData ( data )

TRIAL_MISS = 0;
TRIAL_HIT = 1;
TRIAL_ABORT = 2;
TRIAL_CORRECT_REJECTION = 3;
TRIAL_FALSE_ALARM = 4;

LEFT_NOSEPOKE_IR = 1;
RIGHT_NOSEPOKE_IR = 3;

popdata = [];                                                               %Create a structure to hold population data.

%Iterate over every rat and every session and shorten the stage name if
%necessary
for r = 1:length(data)
    for s = 1:length(data(r).session)
        data(r).session(s).stage = strtok(data(r).session(s).stage, ':')';
        data(r).session(s).daycode = datenum(datestr(data(r).session(s).daycode, 'ddmmyyyy'), 'ddmmyyyy');
    end
end

%Find all unique conditions
conditions = [];
for r = 1:length(data)                                                      %Iterate over every rat and find the conditions for that rat
    conditions = [conditions unique({data(r).session.stage})];
end
conditions = unique(conditions);                                            %Find all unique conditions among all rats

%Iterate through each unique condition and generate the transformed data
%for that condition
for condition = conditions                                                  %Step through each of the experimental conditions.
    temp = [];                                                              %Make a temporary counting variable.
    for r = 1:length(data)                                                  %Step through each rat.
        a = strcmpi(condition{1},{data(r).session.stage});                  %Find all sessions that meet the experimental condition.
        a = unique([data(r).session(a).daycode]);                           %Grab all the unique daycodes for theses sessions.
        temp = [temp, length(a)];                                           %Count the number of sessions this rat has on this condition.
    end
    
    short_condition = strtok(condition, ':');                               %Shorten the cell-array string to something useful
    
    
    eval(['popdata.' lower(short_condition{1}) ...
        '_hitrate_left = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session mean hit rates for each rat.
    eval(['popdata.' lower(short_condition{1}) ...
        '_hitrate_right = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session mean hit rates for each rat.
    eval(['popdata.' lower(short_condition{1}) ...
        '_hitrate = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session mean hit rates for each rat.
    eval(['popdata.' lower(short_condition{1}) ...
        '_latency = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session fatigue data for each rat.
    eval(['popdata.' lower(short_condition{1}) ...
        '_latency_left = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session fatigue data for each rat.
    eval(['popdata.' lower(short_condition{1}) ...
        '_latency_right = nan(length(data),max(temp),2);']);                      %Pre-allocate an array to hold session fatigue data for each rat.
    
    for r = 1:length(data);                                                 %Step through each rat.
        display(['Processing rat' num2str(r)]);
        a = strcmpi(condition{1},{data(r).session.stage});              %Find all sessions that meet the experimental condition.
        temp = unique([data(r).session(a).daycode]);                      	%Grab all the unique daycodes for theses sessions.
        if strcmpi(short_condition{1},'N5')                                  %If this is the "PRE" condition...
            temp = fliplr(temp);                                            %...flip the session order to reverse chronological order.
        end
        for d = temp                                                        %Step through all daycodes on this condition.
            a = find([data(r).session.daycode] == d);                       %Find all sessions with this daycode.
            
            total_left_trials_for_day = 0;
            total_right_trials_for_day = 0;
            total_catch_trials_for_day = 0;
            total_trials_for_day = 0;
            hit_trials_for_day = 0;
            hit_trials_left_for_day = 0;
            hit_trials_right_for_day = 0;
            correct_rejections_for_day = 0;
            hit_trials_left_latency = [];
            hit_trials_right_latency = [];
            hit_trials_latency = [];
            
            for s = a                                                       %Step through each session for this daycode.
                

                 try
                     data(r).session(s).trial.result;
                 catch e
                     continue;
                 end
               
                %Find the total number of real trials (trials that resulted
                %in a hit or a miss, but not a pause or manual feeding).
                %After that, find the total number of hits, and then divide
                %by the total number of trials to get the hit rate for the
                %session.
                trial_outcomes = [data(r).session(s).trial.result];
                trial_sides = [data(r).session(s).trial.side];
                
                finish = [data(r).session(s).trial.finish_time];
                start = [data(r).session(s).trial.cue_time];
                latencies = (finish - start) * 86400;
                
                if (length(trial_outcomes) == 309)
                    length(trial_outcomes)
                end
                
                total_trials_for_day = total_trials_for_day + length(find(trial_outcomes == TRIAL_HIT | trial_outcomes == TRIAL_MISS));
                total_left_trials_for_day = total_left_trials_for_day + length(find((trial_outcomes == TRIAL_HIT | trial_outcomes == TRIAL_MISS) & trial_sides == LEFT_NOSEPOKE_IR));
                total_right_trials_for_day = total_right_trials_for_day + length(find((trial_outcomes == TRIAL_HIT | trial_outcomes == TRIAL_MISS) & trial_sides == RIGHT_NOSEPOKE_IR));
                total_catch_trials_for_day = total_catch_trials_for_day + length(find(trial_outcomes == TRIAL_FALSE_ALARM | trial_outcomes == TRIAL_CORRECT_REJECTION));
                hit_trials_for_day = hit_trials_for_day + length(find(trial_outcomes == TRIAL_HIT));
                hit_trials_left_for_day = hit_trials_left_for_day + length(find(trial_outcomes == TRIAL_HIT & trial_sides == LEFT_NOSEPOKE_IR));
                hit_trials_right_for_day = hit_trials_right_for_day + length(find(trial_outcomes == TRIAL_HIT & trial_sides == RIGHT_NOSEPOKE_IR));
                correct_rejections_for_day = correct_rejections_for_day + length(find(trial_outcomes == TRIAL_CORRECT_REJECTION));
                hit_trials_left_latency = [hit_trials_left_latency latencies(trial_outcomes == TRIAL_HIT & trial_sides == LEFT_NOSEPOKE_IR)];
                hit_trials_right_latency = [hit_trials_right_latency latencies(trial_outcomes == TRIAL_HIT & trial_sides == RIGHT_NOSEPOKE_IR)];
                hit_trials_latency = [hit_trials_latency latencies(trial_outcomes == TRIAL_HIT)];
                
            %End of session loop   
            end
            
            hit_rate = (hit_trials_for_day / total_trials_for_day) * (correct_rejections_for_day / total_catch_trials_for_day);
            left_hit_rate = (hit_trials_left_for_day / total_left_trials_for_day) * (correct_rejections_for_day / total_catch_trials_for_day);
            right_hit_rate = (hit_trials_right_for_day / total_right_trials_for_day) * (correct_rejections_for_day / total_catch_trials_for_day);
            
            hit_trials_left_latency = hit_trials_left_latency';
            if (isempty(hit_trials_left_latency))
                hit_trials_left_latency = NaN;
            end
            
            hit_trials_right_latency = hit_trials_right_latency';
            if (isempty(hit_trials_right_latency))
                hit_trials_right_latency = NaN;
            end
            
            hit_trials_latency = hit_trials_latency';
            if (isempty(hit_trials_latency))
                hit_trials_latency = NaN;
            end
            
            %Save the mean left latency
            eval(['popdata.' lower(short_condition{1}) '_latency_left(r,' ...
                    num2str(find(d==temp)) ',1) = nanmean(hit_trials_left_latency);']);  
            eval(['popdata.' lower(short_condition{1}) '_latency_left(r,' ...
                num2str(find(d==temp)) ',2) = sem(hit_trials_left_latency);']); 
            
            %Save the mean right latency
            eval(['popdata.' lower(short_condition{1}) '_latency_right(r,' ...
                    num2str(find(d==temp)) ',1) = nanmean(hit_trials_right_latency);']);       
            eval(['popdata.' lower(short_condition{1}) '_latency_right(r,' ...
                num2str(find(d==temp)) ',2) = sem(hit_trials_right_latency);']); 
            
            %Save the mean latency
            eval(['popdata.' lower(short_condition{1}) '_latency(r,' ...
                    num2str(find(d==temp)) ',1) = nanmean(hit_trials_latency);']);       
            eval(['popdata.' lower(short_condition{1}) '_latency(r,' ...
                num2str(find(d==temp)) ',2) = sem(hit_trials_latency);']); 
            
            %Save the hit rate
            eval(['popdata.' lower(short_condition{1}) '_hitrate(r,' ...
                    num2str(find(d==temp)) ',1) = hit_rate;']);       
            eval(['popdata.' lower(short_condition{1}) '_hitrate(r,' ...
                num2str(find(d==temp)) ',2) = 0;']); 
            
            %Save the left hit rate
            eval(['popdata.' lower(short_condition{1}) '_hitrate_left(r,' ...
                    num2str(find(d==temp)) ',1) = left_hit_rate;']);       
            eval(['popdata.' lower(short_condition{1}) '_hitrate_left(r,' ...
                num2str(find(d==temp)) ',2) = 0;']); 
            
            %Save the right hit rate
            eval(['popdata.' lower(short_condition{1}) '_hitrate_right(r,' ...
                    num2str(find(d==temp)) ',1) = right_hit_rate;']);       
            eval(['popdata.' lower(short_condition{1}) '_hitrate_right(r,' ...
                num2str(find(d==temp)) ',2) = 0;']); 
            
        end
    end  
end

