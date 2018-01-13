%% neglect - Call this function to run the neglect software
function neglect6

% Declare global variables that we need
global SESSION_IS_STOPPED;
global SESSION_IS_RUNNING;
global SESSION_IS_PAUSED;
global SESSION_MANUAL_FEED;

global SECONDS_PER_DAY;

global LEFT_NOSEPOKE_IR;
global CENTER_NOSEPOKE_IR;
global RIGHT_NOSEPOKE_IR;

global TRIAL_STATE_NOT_BEGUN;
global TRIAL_STATE_WAIT_CUE_PRE;
global TRIAL_STATE_WAIT_CUE_POST;
global TRIAL_STATE_CONCLUDE_TRIAL;
global TRIAL_STATE_WAIT_TO_RESET;

global TRIAL_MISS;
global TRIAL_HIT;
global TRIAL_ABORT;
global TRIAL_CORRECT_REJECTION;
global TRIAL_FALSE_ALARM;
global TRIAL_RESULT_UNKNOWN;

global TRIAL_TYPE_NORMAL;
global TRIAL_TYPE_CATCH_TRIAL;

% Define values for all of our global variables
SECONDS_PER_DAY = 86400;

LEFT_NOSEPOKE_IR = 1;
CENTER_NOSEPOKE_IR = 2;
RIGHT_NOSEPOKE_IR = 3;

TRIAL_STATE_NOT_BEGUN = 0;
TRIAL_STATE_WAIT_CUE_PRE = 1;
TRIAL_STATE_WAIT_CUE_POST = 2;
TRIAL_STATE_CONCLUDE_TRIAL = 4;
TRIAL_STATE_WAIT_TO_RESET = 5;

TRIAL_MISS = 0;
TRIAL_HIT = 1;
TRIAL_ABORT = 2;
TRIAL_CORRECT_REJECTION = 3;
TRIAL_FALSE_ALARM = 4;
TRIAL_RESULT_UNKNOWN = 5;

TRIAL_TYPE_NORMAL = 0;
TRIAL_TYPE_CATCH_TRIAL = 1;

SESSION_IS_STOPPED = 0;
SESSION_IS_RUNNING = 1;
SESSION_IS_PAUSED = 2;
SESSION_MANUAL_FEED = 3;

% Connect to the Arduino and display the GUI to the user

%Connect to the Arduino
ardy = ArdyBehavior;

%Create the user interface
handles = Make_GUI;

%Set the master variable which indicates whether or not we are running a
%session right now
set(handles.mainfig, 'userdata', SESSION_IS_STOPPED);

%Initialize several of our handles
handles.ardy = ardy;
handles.run = get(handles.mainfig, 'userdata');

%Turn off the cage light
handles.ardy.cage_lights(0);

%Set paths to save the data
handles.primary_data_path = 'C:\Neglect\';
handles.secondary_data_path = 'Z:\Unilateral Neglect\Rats\';
handles.stage_settings_path = 'https://docs.google.com/spreadsheet/pub?key=0AhzLNWqYl6P4dDNTZ05qU0FQR2ZuOVNTb3IyQ3NBRnc&output=txt';

warning off MATLAB:MKDIR:DirectoryExists;
mkdir(handles.primary_data_path);
    
try
    mkdir(handles.secondary_data_path);
catch e
    disp(['Error: ' e.message]);
    disp('We were not able to locate the secondary datapath.');
end

%Load all the stages and update the GUI to show them to the user
handles.stage = LoadStages(handles.stage_settings_path);
handles.cur_stage = 1;
handles = choose_stage(handles);

handles.ratname = [];
handles.booth = handles.ardy.booth();
set(handles.booth_text_block, 'string', handles.booth);

guidata(handles.mainfig, handles);



%% BehaviorLoop - Runs the behavioral training program
function BehaviorLoop (hObject, h)

global SESSION_IS_RUNNING;
global SESSION_IS_STOPPED;
global SESSION_IS_PAUSED;
global SESSION_MANUAL_FEED;

global SECONDS_PER_DAY;

global LEFT_NOSEPOKE_IR;
global CENTER_NOSEPOKE_IR;
global RIGHT_NOSEPOKE_IR;

global TRIAL_STATE_NOT_BEGUN;
global TRIAL_STATE_WAIT_CUE_PRE;
global TRIAL_STATE_WAIT_CUE_POST;
global TRIAL_STATE_CONCLUDE_TRIAL;
global TRIAL_STATE_WAIT_TO_RESET;

global TRIAL_MISS;
global TRIAL_HIT;
global TRIAL_ABORT;
global TRIAL_CORRECT_REJECTION;
global TRIAL_FALSE_ALARM;
global TRIAL_RESULT_UNKNOWN;

global TRIAL_TYPE_NORMAL;
global TRIAL_TYPE_CATCH_TRIAL;

NOSEPOKE_THRESHOLD = 1016;
SAMPLES_PER_SECOND = 100;
MILLISECONDS_PER_SAMPLE = 10;
SAMPLES_PER_50_MILLISECONDS = 0.1 * SAMPLES_PER_SECOND;
NOSEPOKE_BUFFER_SIZE = SAMPLES_PER_SECOND * 5;

%Write the file header for this new session
fid = write_file_header(h);

%Initialize some variables
h.run = get(h.mainfig, 'userdata');
h.trial_state = TRIAL_STATE_NOT_BEGUN;
h.trial_type = TRIAL_TYPE_NORMAL;
h.trial_count = 0;
h.total_hits = 0;
h.total_manual_feeds = 0;
h.total_hits_and_misses = 0;
h.total_catch_trials = 0;
h.total_false_alarms = 0;
h.left_trial_count = 0;
h.right_trial_count = 0;
h.hit_rate = 0;
h.trial_cue_duration = 0;
h.trial_cue_intensity = 0;
h.trial_distractor_intensity = 0;
h.psychometric_cue_durations = [250 100 50 10 5 2 1];
h.psychometric_cue_intensities = [255 128 64 32 16 8 4 2 1 0];

%Update the guidata with these new variables
guidata(hObject, h);

%Update the UI
set(h.total_trials_text_block, 'string', '0');
set(h.hits_text_block, 'string', '0');
set(h.manual_feeds_text_block, 'string', '0');        
set(h.catch_trials_text_block, 'string', '0');
set(h.hits_and_misses_text_block, 'string', '0');
set(h.false_alarms_text_block, 'string', '0');

%Clear the trial plots on the GUI
cla(h.left_trials_axis, 'reset');
cla(h.right_trials_axis, 'reset');

%Set the cue duration on the Arduino board
if (h.cue_duration == -1)
    h.ardy.set_led_dur(h.psychometric_cue_durations(1));
else
    h.ardy.set_led_dur(h.cue_duration);
    h.trial_cue_duration = h.cue_duration;
end

%Set the distractor intensity on the Arduino board
if (h.distractor_intensity == -1)
    h.ardy.set_single_led_intensity(CENTER_NOSEPOKE_IR, h.psychometric_cue_intensities(1));
else
    h.ardy.set_single_led_intensity(CENTER_NOSEPOKE_IR, h.distractor_intensity);
    h.trial_distractor_intensity = h.distractor_intensity;
end

%Set the cue intensity on the Arduino board
if (h.cue_intensity == -1)
    h.ardy.set_single_led_intensity(LEFT_NOSEPOKE_IR, h.psychometric_cue_intensities(1));
    h.ardy.set_single_led_intensity(RIGHT_NOSEPOKE_IR, h.psychometric_cue_intensities(1));
else
    h.ardy.set_single_led_intensity(LEFT_NOSEPOKE_IR, h.cue_intensity);
    h.ardy.set_single_led_intensity(RIGHT_NOSEPOKE_IR, h.cue_intensity);
    h.trial_cue_intensity = h.cue_intensity;
end

%Turn the center LED on. The center LED should remain on for the entire
%duration of the session.  It will vary intensity every trial.  It will
%turn off at the end of the session.
h.ardy.set_single_led_duration(CENTER_NOSEPOKE_IR, -1);
h.ardy.led_on(CENTER_NOSEPOKE_IR);

%Initialize this variable.  It should change later (before each trial) to
%incorporate the random_trial_wait.
actual_pre_trial_wait = h.pre_trial_wait;

%Initialize a variable indicating whether the current trial will use the
%exact same hold time as the previous trial
use_previous_trial_settings = 0;

%Initialize streaming.
%First, set the stream period to 10 milliseconds
%Second, tell the Arduino we want to stream the center nosepoke IR
%Third, initially clear whatever data is on the serial line
%Finally, enable streaming
h.ardy.set_stream_period(MILLISECONDS_PER_SAMPLE);
%h.ardy.set_stream_ir(CENTER_NOSEPOKE_IR);
h.ardy.stream_enable(0);
h.ardy.clear();
h.ardy.stream_enable(1);

nosepoke_history = zeros(1, NOSEPOKE_BUFFER_SIZE) + 1020;
trial_nosepoke_history = [];
trial_pos = 0;

%Loop until the session is stopped by the user
while (ishandle(hObject) && (h.run ~= SESSION_IS_STOPPED))
    
    %Read the most recent nosepoke IR data from the arduino
    data = h.ardy.read_stream();
    
    %If no data is being received, skip this iteration of the loop.
    if (isempty(data))
        continue;
    end
    
    %Filter out the timestamps.  We only want the actual IR values.
    npstat = data(:, 2);
    
    %Throw the IR data into the nosepoke history (stores the last 5 seconds
    %of nosepoke data
    first_index_to_keep = length(npstat) + 1;
    last_index_to_keep = length(nosepoke_history);
    nosepoke_history = [nosepoke_history(first_index_to_keep:last_index_to_keep) npstat'];
    
    %If we are currently in the midst of a trial, save the latest nosepoke
    %data into the trial nosepoke history
    if (h.trial_state > TRIAL_STATE_NOT_BEGUN && h.trial_state < TRIAL_STATE_CONCLUDE_TRIAL)
        trial_nosepoke_history(trial_pos:(trial_pos+length(npstat)-1)) = npstat;
        trial_pos = trial_pos + length(npstat);
    end
    
    if (h.trial_state == TRIAL_STATE_NOT_BEGUN || h.trial_state == TRIAL_STATE_WAIT_TO_RESET)
        cla(h.current_trial_axis);
        plot(h.current_trial_axis, nosepoke_history);
        set(h.current_trial_axis, 'ylim', [1000 1020]);    
        set(h.current_trial_axis, 'xlim', [1 NOSEPOKE_BUFFER_SIZE]);
    elseif (~isempty(trial_nosepoke_history) && length(trial_nosepoke_history) > SAMPLES_PER_SECOND)
        cla(h.current_trial_axis);
        hold(h.current_trial_axis, 'on');
        plot(h.current_trial_axis, trial_nosepoke_history);
        set(h.current_trial_axis, 'ylim', [1000 1020]);    
        set(h.current_trial_axis, 'xlim', [1 length(trial_nosepoke_history)]);
        hit_start = SAMPLES_PER_SECOND + actual_pre_trial_wait * SAMPLES_PER_SECOND;
        hit_end = SAMPLES_PER_SECOND + (actual_pre_trial_wait + h.response_time_threshold) * SAMPLES_PER_SECOND;
        plot(h.current_trial_axis, [SAMPLES_PER_SECOND SAMPLES_PER_SECOND], [0 1200], 'LineStyle', '--', 'LineWidth', 3, 'Color', [0 0 1]);
        plot(h.current_trial_axis, [hit_start hit_start], [1000 1020], 'LineStyle', '--', 'LineWidth', 3, 'Color', [0 0.7 0]);
        plot(h.current_trial_axis, [hit_end hit_end], [1000 1020], 'LineStyle', '--', 'LineWidth', 3, 'Color', [1 0 0]);
    end
    
    %Here we enter the state machine.
    %States:
    %   1.  Wait for rat to enter nosepoke
    %   2.  LED stimulus delivery
    %   3.  Wait for response
    %   4.  Finish trial and save data
    if (h.trial_state == TRIAL_STATE_NOT_BEGUN)
        
        %Here we check to see if the rat has entered the nosepoke
        %If the rat has entered the nosepoke, then we begin a new trial.
        %If the session is PAUSED, then we don't allow any new trials to
        %begin.
        %rat_has_entered_nosepoke = any(npstat >= NOSEPOKE_THRESHOLD);
        rat_has_entered_nosepoke = length(find(nosepoke_history(end - SAMPLES_PER_50_MILLISECONDS:end) <= NOSEPOKE_THRESHOLD, 5, 'first')) == 5;
             
        if (rat_has_entered_nosepoke && (h.run ~= SESSION_IS_PAUSED))
            %Set up a new trial
            h.trial_start_time = -1;
            h.trial_cue_time = -1;
            h.trial_finish_time = -1;
            h.trial_result = TRIAL_RESULT_UNKNOWN;
            
            %If the flag has not been set to use the previous trial's
            %settings, then pick new settings for this new trial.
            if (~use_previous_trial_settings)
            
                %If the cue duration is set to -1, this means that the current
                %stage is set for discovering a psychometric curve, and the cue
                %duration should be chosen at random among a set of pre-defined
                %cue durations.  Let's pick one here for this new trial.
                if (h.cue_duration == -1)
                    h.trial_cue_duration = h.psychometric_cue_durations(randi([1 length(h.psychometric_cue_durations)]));
                    h.ardy.set_led_dur(h.trial_cue_duration);
                end
                
                %If the cue intensity is set to -1, we are generating a
                %psychometric curve for cue intensity, and so we must
                %choose the cue intensity at random
                if (h.cue_intensity == -1)
                    h.trial_cue_intensity = h.psychometric_cue_intensities(randi([1 length(h.psychometric_cue_intensities)]));
                    h.ardy.set_single_led_intensity(LEFT_NOSEPOKE_IR, h.trial_cue_intensity);
                    h.ardy.set_single_led_intensity(RIGHT_NOSEPOKE_IR, h.trial_cue_intensity);
                end
                
                %Decide whether this will be a normal trial or a catch trial
                probability = int32(rand * 100);
                if (probability < h.catch_trial_percentage)
                    h.trial_type = TRIAL_TYPE_CATCH_TRIAL;
                else
                    h.trial_type = TRIAL_TYPE_NORMAL;
                end
                            
                %Choose the side that on which we will deliver the cue
                h.correct_side = round(rand(1));
                if (h.correct_side == 0)
                    h.correct_side = LEFT_NOSEPOKE_IR;
                else
                    h.correct_side = RIGHT_NOSEPOKE_IR;
                end
                
                %Figure out exactly how long we should wait before delivering the cue
                actual_pre_trial_wait = h.pre_trial_wait + (h.random_trial_wait * rand);
            else
                %Unset the flag now that we know to keep the same settings
                %for this trial.  The flag may be set again later at the
                %end of this trial if the same settings need to be retained
                %again for the next trial.
                use_previous_trial_settings = 0;
            end
            
            %Increment the trial counter
            h.trial_count = h.trial_count + 1;
            if (h.correct_side == LEFT_NOSEPOKE_IR)
                h.left_trial_count = h.left_trial_count + 1;
            else
                h.right_trial_count = h.right_trial_count + 1;
            end
            
            %Start saving nosepoke data for this trial
            trial_nosepoke_history = zeros(ceil(SAMPLES_PER_SECOND * 2 + (actual_pre_trial_wait + h.response_time_threshold) * SAMPLES_PER_SECOND), 1) + 1020;
            
            %Grab the last second of data before the trial began and put it
            %at the start of trial_nosepoke_history
            trial_nosepoke_history(1:SAMPLES_PER_SECOND) = nosepoke_history((NOSEPOKE_BUFFER_SIZE - SAMPLES_PER_SECOND + 1):NOSEPOKE_BUFFER_SIZE);
            trial_pos = SAMPLES_PER_SECOND + 1;
            
            %Start a timer
            h.trial_start_time = now;
            
            %Set the next state
            h.trial_state = TRIAL_STATE_WAIT_CUE_PRE;
        end
        
    elseif (h.trial_state == TRIAL_STATE_WAIT_CUE_PRE)
        
        %Get the center nosepoke status
        %is_rat_in_nosepoke = any(trial_nosepoke_history(trial_pos - SAMPLES_PER_50_MILLISECONDS:trial_pos) >= NOSEPOKE_THRESHOLD);
        is_rat_in_nosepoke = length(find(trial_nosepoke_history(trial_pos - SAMPLES_PER_50_MILLISECONDS:trial_pos) <= NOSEPOKE_THRESHOLD, 5, 'first')) == 5;
        
        %Verify that the rat is still in the nosepoke.  If it isn't, then
        %this is automatically a missed trial
        if (~is_rat_in_nosepoke)
            h.trial_result = TRIAL_ABORT;
            
            %Get the time of the conclusion of this trial
            h.trial_finish_time = now;
            h.trial_cue_time = h.trial_start_time + actual_pre_trial_wait;
            
            %If the rat exited the nosepoke before cue delivery,
            %set the state to be "conclude trial", and don't 
            %deliver the cue.
            h.trial_state = TRIAL_STATE_CONCLUDE_TRIAL;
        else
            %Check how much time has passed
            seconds_elapsed = (now - h.trial_start_time) * SECONDS_PER_DAY;
            if (seconds_elapsed >= actual_pre_trial_wait)  
                %If enough time has passed, then let's go ahead and 
                %deliver the cue.

                %Deliver the cue here
                if (h.trial_type == TRIAL_TYPE_NORMAL)
                    h.ardy.led_on(h.correct_side);
                end
                
                %Start a new timer to time the cue delivery
                h.trial_cue_time = now;
                
                %Set the next trial state
                h.trial_state = TRIAL_STATE_WAIT_CUE_POST;
            end
        end
        
    elseif (h.trial_state == TRIAL_STATE_WAIT_CUE_POST)

        %Check to see if the rat has exited the nosepoke.
        %rat_is_in_nosepoke = any(trial_nosepoke_history(trial_pos - SAMPLES_PER_50_MILLISECONDS:trial_pos) >= NOSEPOKE_THRESHOLD);
        rat_is_in_nosepoke = length(find(trial_nosepoke_history(trial_pos - SAMPLES_PER_50_MILLISECONDS:trial_pos) <= NOSEPOKE_THRESHOLD, 5, 'first')) == 5;
        
        %Check how much time has passed since the cue was delivered.
        seconds_elapsed = (now - h.trial_cue_time) * SECONDS_PER_DAY;
        
        if (seconds_elapsed >= h.response_time_threshold)
            if (h.trial_type == TRIAL_TYPE_CATCH_TRIAL)
                %The rat correctly held when we did not deliver a cue
                h.trial_result = TRIAL_CORRECT_REJECTION;
            else
                %If too much time has passed, this is a missed trial
                h.trial_result = TRIAL_MISS;
            end
            
            h.trial_state = TRIAL_STATE_CONCLUDE_TRIAL;
            
            %Get the time of the conclusion of this trial
            h.trial_finish_time = now;
        elseif (~rat_is_in_nosepoke)
            if (h.trial_type == TRIAL_TYPE_CATCH_TRIAL)
                %The rat exited altough we did not deliver a cue
                h.trial_result = TRIAL_FALSE_ALARM;
            else
                %But if the rat has exited the nosepoke within the threshold
                %time, then this is a successful trial
                h.trial_result = TRIAL_HIT;
            end
            
            h.trial_state = TRIAL_STATE_CONCLUDE_TRIAL;
            
            %Get the time of the conclusion of this trial
            h.trial_finish_time = now;
        end
        
    elseif (h.trial_state == TRIAL_STATE_CONCLUDE_TRIAL)
        
        %Make sure the LED cue is turned off
        h.ardy.led_off(h.correct_side);
        
        %%%%%%%%%%%%%%%
        %Feed the animal if successful, play a bad sound otherwise
        %%%%%%%%%%%%%%%
        if (h.trial_result == TRIAL_HIT)
            %Feed the animal
            h.ardy.feed(1);
            %Play a good sound
            h.ardy.play_good_sound();
            
            %Increment the parameters for the adaptive stage.
            %We only increment the parameters on successful trials!
            h.pre_trial_wait = min([(h.pre_trial_wait + h.pre_trial_wait_slope) h.pre_trial_wait_end]);
            h.random_trial_wait = min([(h.random_trial_wait + h.random_trial_wait_slope) h.random_trial_wait_end]); 
        elseif (h.trial_result == TRIAL_MISS)
            %If the rat did the wrong thing, play a bad sound to indicate
            %this to the rat.
            h.ardy.play_bad_sound();
            
            %In addition to a bad sound, turn off the cage light for the
            %duration of the time out period
            h.ardy.cage_lights(0);
        elseif (h.trial_result == TRIAL_ABORT)
            %If the result of this trial was an abort, set the flag to keep
            %the same exact trial settings for the next trial
            use_previous_trial_settings = 1;
        end
        
        %%%%%%%%%%%%%%%
        %Update variables displayed on the UI based on trial result
        %%%%%%%%%%%%%%%
        if (h.trial_result == TRIAL_HIT)
            %Update the hit count
            h.total_hits = h.total_hits + 1;
            %Update the total hits and misses
            h.total_hits_and_misses = h.total_hits_and_misses + 1;
            %Set the plotting color for a hit
            color = [0 0.7 0];
        elseif (h.trial_result == TRIAL_MISS)
            %Update hits + misses
            h.total_hits_and_misses = h.total_hits_and_misses + 1;    
            %Set the plotting color for a miss
            color = [0.7 0 0];
        elseif (h.trial_result == TRIAL_CORRECT_REJECTION)
            %Update the catch trial count
            h.total_catch_trials = h.total_catch_trials + 1;
            %Set the plotting color for a correct rejection
            color = [0 0 0.7];
        elseif (h.trial_result == TRIAL_FALSE_ALARM)
            %Update the catch trial count
            h.total_catch_trials = h.total_catch_trials + 1;
            %Update the false alarm count
            h.total_false_alarms = h.total_false_alarms + 1;
            %Set the plotting color for a false alarm
            color = [1 1 0];
        elseif (h.trial_result == TRIAL_ABORT)
            %Set the plotting color for an abort
            color = [0 0 0];
        else
            %This statement really shouldn't ever be reached...
            %Because we have already covered all the cases...
            %but just in case...
            color = [0.7 0 0];
        end
                
        %Plot the data
        hold_time = (h.trial_finish_time - h.trial_start_time) * SECONDS_PER_DAY;
        if (h.correct_side == LEFT_NOSEPOKE_IR)
            axes(h.left_trials_axis);
            hold on;
            plot(h.left_trial_count, hold_time, 'Color', color, 'linestyle','none','marker','*');
        else
            axes(h.right_trials_axis);
            hold on;
            plot(h.right_trial_count, hold_time, 'Color', color, 'linestyle','none','marker','*');
        end
        
        %-------------------
        %Save the trial data
        %-------------------
        fwrite(fid, h.trial_count, 'uint32');
        fwrite(fid, h.trial_result, 'uint8');
        fwrite(fid, h.trial_start_time, 'float64');
        fwrite(fid, h.trial_finish_time, 'float64');
        fwrite(fid, h.trial_cue_time, 'float64');
        fwrite(fid, h.trial_cue_duration, 'float64');
        fwrite(fid, h.trial_cue_intensity, 'uint8');
        fwrite(fid, h.trial_distractor_intensity, 'uint8');
        fwrite(fid, h.response_time_threshold, 'float32');
        fwrite(fid, h.correct_side, 'float32');
        
        %-------------------
        %Update the UI
        %-------------------
        set(h.total_trials_text_block, 'string', h.trial_count);
        set(h.catch_trials_text_block, 'string', h.total_catch_trials);
        set(h.hits_and_misses_text_block, 'string', h.total_hits_and_misses);
        set(h.hits_text_block, 'string', h.total_hits);
        set(h.false_alarms_text_block, 'string', h.total_false_alarms);
        
        %Calculate false-alarm corrected hit rate and update the UI
        if ((h.total_hits_and_misses > 0) && (h.total_catch_trials > 0))
            biased_hit_rate = h.total_hits / h.total_hits_and_misses;
            false_alarm_rate = h.total_false_alarms / h.total_catch_trials;
            h.hit_rate = biased_hit_rate * (1 - false_alarm_rate);
            set(h.hit_rate_text_block, 'string', h.hit_rate);
        end
        
        %Reset the nosepoke history
        nosepoke_history = zeros(1, NOSEPOKE_BUFFER_SIZE) + 1020;
        trial_nosepoke_history = [];
        trial_pos = 0;
        
        %Set the trial state to the next state
        h.trial_state = TRIAL_STATE_WAIT_TO_RESET;
        
        %Start a timer for the trial timeout.
        timer_start = now;
        
    elseif (h.trial_state == TRIAL_STATE_WAIT_TO_RESET)
        
        %See how many seconds have elapsed since the trial timeout began.
        seconds_elapsed = (now - timer_start) * SECONDS_PER_DAY;
        
        %If the trial was a hit, then we don't need to worry about actually
        %having a timeout period, so let's just check and see if the
        %nosepoke is free, and then we can start a new trial.  OR if the
        %trial was not a hit, wait for the timeout period to end, and then
        %check the nosepoke to see if it is free.
        %if ((h.trial_result == TRIAL_HIT) || ...
        %        seconds_elapsed >= h.timeout_period)
        if (seconds_elapsed >= h.timeout_period)
            
            %In this state, we simply wait until we know the nosepoke is 
            %empty before we allow another trial to begin.
            %rat_is_in_nosepoke = any(npstat >= NOSEPOKE_THRESHOLD);

            %if (~rat_is_in_nosepoke)
            
            %If the distractor intensity is set to -1, this means that
            %the current stage is set for discovering a psychometric
            %curve, and the distractor intensity should be chosen at
            %random among a set of pre-defined intensities. Let's pick
            %one here.
            if (h.distractor_intensity == -1)
                h.trial_distractor_intensity = h.psychometric_cue_intensities(randi([1 length(h.psychometric_cue_intensities)]));
                h.ardy.set_single_led_intensity(CENTER_NOSEPOKE_IR, h.trial_distractor_intensity);
                h.ardy.led_on(CENTER_NOSEPOKE_IR);
            end

            %Once we are ready to set the trial state so that a new
            %trial is allowed to begin, let's make sure the cage light
            %is set to be on (it will be off in the case that the
            %previous trial was an abort, miss, or false alarm).
            h.ardy.cage_lights(1);

            %Set the state to wait for the rat to enter the center nosepoke 
            %again.
            h.trial_state = TRIAL_STATE_NOT_BEGUN;
            
            %end
            
        end
        
    end
    
    %Flush the event queue and handle any UI events
    drawnow;
    
    %See if the run state has changed
    h.run = get(h.mainfig, 'userdata');
    
    %If the user has requested a manual feed
    if (h.run == SESSION_MANUAL_FEED)
        %Feed a pellet
        h.ardy.feed(1);
        
        %Update the UI to reflect the total manual feeds
        h.total_manual_feeds = h.total_manual_feeds + 1;
        set(h.manual_feeds_text_block, 'string', h.total_manual_feeds);
        
        %Set the run state back to "session is running"
        h.run = SESSION_IS_RUNNING;
        set(h.mainfig, 'userdata', h.run);
    end
    
end

%Turn off the center LED
h.ardy.led_off(CENTER_NOSEPOKE_IR);

%End streaming
h.ardy.stream_enable(0);
h.ardy.clear();

%Close the session data file
fclose(fid);

%Copy the session data file to the secondary data path
try
    filename = [h.primary_data_path h.ratname '\'];
    filename = [filename h.ratname '-' 'Stage' ...
        h.stage(h.cur_stage).number '\']; 
    mkdir(h.secondary_data_path);                                              %Make the back-up data folder if it doesn't already exist.
    mkdir([h.secondary_data_path h.ratname '\']);                        %Make a folder for this rat's data if it doesn't already exist.
    temp = [h.secondary_data_path h.ratname '\' h.ratname '-' ... 
        'Stage' h.stage(h.cur_stage).number '\'];               %Create a folder name containing the rat name and stage number.
    mkdir(temp);                                                            %Make a folder for this stage's data if it doesn't already exist.
    copyfile(filename, temp);                                               %Copy saved datafile onto the Z drive
catch e
    disp(e.message);
    disp('There was an error while trying to save the data to the secondary datapath.');
end

if (ishandle(hObject))
    guidata(hObject, h);
end

%% LoadStages - loads in all the stages from the stage settings path
function stage = LoadStages (url)

urldata = Read_Google_Spreadsheet(url);

fields = {'Stage Number', 'number'; ...
    'Stage Description', 'description'; ...
    'Lower Limit Start', 'minwait'; ...
    'Lower Limit End', 'minend'; ...
    'Lower Limit Slope', 'minslope'; ...
    'Random Start', 'randwait'; ...
    'Random End', 'randend'; ...
    'Random Slope', 'randslope'; ...
    'Hit Window', 'hitwin'; ...
    'Catch Trial Percent', 'catchtrialpercent'; ...
    'Bad Trial Timeout', 'timeout'; ...
    'Cue Intensity (0 to 255)', 'cueintensity'; ...
    'Cue Duration (ms)', 'cueduration'; ...
    'Distractor Intensity (0 to 255)', 'distractorintensity' };

for c = 1:size(fields,1)                                                    %Step through each column heading.
    a = strcmpi(fields{c,1},urldata(1,:));                                  %Find the column index for this column heading.
    for i = 2:size(urldata,1)                                               %Step through each listed stage.
        temp = urldata{i,a};                                                %Grab the entry for this stage.
        temp(temp == 39) = [];                                              %Kick out any apostrophes in the entry.
        if any(temp > 59)                                                   %If there's any text characters in the entry...
            stage(i-1).(fields{c,2}) = temp;                                %Save the field value as a string.
        else                                                                %Otherwise, if there's no text characters in the entry.
            stage(i-1).(fields{c,2}) = eval(temp);                          %Evaluate the entry and save the field value as a number.
        end
    end
end

for i = 1:length(stage)                                                     %Step through the stages.
    stage(i).description = [stage(i).number ': ' stage(i).description];     %Add the stage number to the stage description.
end

%% Make_GUI - creates the user interface
function handles = Make_GUI

%Define figure height and width (in centimeters)
figure_width = 750;
figure_height = 800;

%Create the main figure
handles.mainfig = figure('units', 'pixels');
pos = get(handles.mainfig, 'position');
set(handles.mainfig, ...
    'units', 'pixels', ...
    'Position', [pos(1) (pos(2)+pos(4) - figure_height) figure_width figure_height], ...
    'MenuBar', 'none', ...
    'numbertitle', 'off', ...
    'resize', 'off', ...
    'CloseRequestFcn', @close_figure_callback, ...
    'name', 'Unilateral Neglect Behavior Version 2.0' );


%Create a UI panel for the upper controls grid
p = uipanel(handles.mainfig, ...
    'units','pixels', ...
    'position',[35, 575, 680, 200], ...
    'backgroundcolor', get(handles.mainfig,'color')); 

%Create flow control on the right side of the panel
fc = uiflowcontainer('v0', ...
    p, ...
    'Units','pixels', ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'Position',[520, 10, 150, 180]);

%Create the buttons that go into the flow control
%These are the start/pause/feed buttons
handles.start_stop_button = uicontrol('string','Start', ...
    'callback', @start_stop_button_callback, ...
    'enable', 'on', ...
    'parent',fc);
handles.pause_button = uicontrol('string','Pause', ...
    'callback', @pause_button_callback, ...
    'enable', 'off', ...
    'parent',fc);
handles.feed_button = uicontrol('string','Feed', ...
    'callback', @feed_button_callback, ...
    'enable', 'off', ...
    'parent',fc);

%Create the upper grid
upper_controls_grid = uigridcontainer('v0', ...
    p, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'Units', 'pixels', ...
    'Position', [5, 10, 495, 180], ...
    'GridSize', [6, 4]);

%Rat name
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Rat name:', ...
    'parent', upper_controls_grid);
handles.rat_name_text_box = uicontrol('style', 'edit', ...
    'backgroundcolor', [1 1 1], ...
    'fontsize', 12, ...
    'horizontalalignment', 'left', ...
    'string', '', ...
    'callback', @change_rat_name_callback, ...
    'parent', upper_controls_grid);

%Total trials
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Total trials:', ...
    'parent', upper_controls_grid);    
handles.total_trials_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%Stage drop-down box
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Stage:', ...
    'parent', upper_controls_grid);    
handles.stage_combo_box = uicontrol('style', 'popupmenu', ...
    'fontsize', 12, ...
    'horizontalalignment', 'right', ...
    'string', 'No stages', ...
    'callback', @select_stage_callback, ...
    'parent', upper_controls_grid);

%Hits + Misses
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Hits + Miss:', ...
    'parent', upper_controls_grid);    
handles.hits_and_misses_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%Arduino "connected to" text controls
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Connected to:', ...
    'parent', upper_controls_grid);    
handles.booth_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%Hit trials
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Hits:', ...
    'parent', upper_controls_grid);    
handles.hits_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%Manual feeds
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Manual feeds:', ...
    'parent', upper_controls_grid);    
handles.manual_feeds_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%Catch trials
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Catch trials:', ...
    'parent', upper_controls_grid);    
handles.catch_trials_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%False-Alarm Corrected Hit Rate
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'Hit Rate:', ...
    'parent', upper_controls_grid);    
handles.hit_rate_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);

%False Alarms
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'False alarms:', ...
    'parent', upper_controls_grid);    
handles.false_alarms_text_block = uicontrol('style', 'text', ...
    'foregroundcolor', [0 0.5 0], ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'right', ...
    'string', 'unknown', ...
    'parent', upper_controls_grid);


%Left-side trials axis
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'left', ...
    'string', 'Left-side trials:', ...
    'position', [50, 530, 300, 20], ...
    'parent', handles.mainfig);    
handles.left_trials_axis = axes('parent', handles.mainfig, ...
    'units', 'pixels', ...
    'position', [50, 270, 300, 250] );

%Right-side trials axis
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'left', ...
    'string', 'Right-side trials:', ...
    'position', [420, 530, 300, 20], ...
    'parent', handles.mainfig);    
handles.right_trials_axis = axes('parent', handles.mainfig, ...
    'units', 'pixels', ...
    'position', [420, 270, 300, 250] );

%Current trial axis
uicontrol('style', 'text', ...
    'fontweight', 'bold', ...
    'fontsize', 12, ...
    'backgroundcolor', get(handles.mainfig,'color'), ...
    'horizontalalignment', 'left', ...
    'string', 'Current trial:', ...
    'position', [50, 230, 300, 20], ...
    'parent', handles.mainfig);    
handles.current_trial_axis = axes('parent', handles.mainfig, ...
    'units', 'pixels', ...
    'ylim', [0 1200], ...
    'position', [50, 70, 670, 150] );

%% start_stop_button_callback - Called when start button pressed
function start_stop_button_callback (hObject,eventdata)

global SESSION_IS_STOPPED;
global SESSION_IS_RUNNING;

%and get the latest version of the data
handles = guidata(hObject);

is_running = get(handles.mainfig, 'userdata');

%Update the text of the pause button
%This happens regardless of whether we are starting or stopping a session.
set(handles.pause_button, 'string', 'Pause');

if (is_running == SESSION_IS_STOPPED)
    %If the session is stopped, then start a new session
    set(handles.mainfig, 'userdata', SESSION_IS_RUNNING);
    
    %Update the text of the start/stop button
    set(handles.start_stop_button, 'string', 'Stop');
    
    %Enable pause, and feed buttons, so they can be used during the session
    set(handles.pause_button, 'enable', 'on');
    set(handles.feed_button, 'enable', 'on');
    set(handles.rat_name_text_box, 'enable', 'off');
    set(handles.stage_combo_box, 'enable', 'off');
    set(handles.manual_feeds_text_block, 'string', '0');
    set(handles.total_trials_text_block, 'string', '0');
    set(handles.hits_text_block, 'string', '0');
    
    %Update the handles object with the new run status
    guidata(hObject, handles);
    
    %Turn on the cage light
    handles.ardy.cage_lights(1);
    
    %Start the behavior loop
    BehaviorLoop(hObject, handles);
else 
    %Otherwise, if a session is currently running or paused, stop the
    %session.
    set(handles.mainfig, 'userdata', SESSION_IS_STOPPED);
    
    %Update the text of the start/stop button
    set(handles.start_stop_button, 'string', 'Start');
    
    %Disable start/stop, pause, and feed buttons (until a new stage is
    %selected by the user)
    set(handles.rat_name_text_box, 'enable', 'on');
    set(handles.stage_combo_box, 'enable', 'on');
    set(handles.start_stop_button, 'enable', 'off');
    set(handles.pause_button, 'enable', 'off');
    set(handles.feed_button, 'enable', 'off');
    
    %Turn off the cage light
    handles.ardy.cage_lights(0);
    
    %Update the handles object with the new run status
    guidata(hObject, handles);
end

%% pause_button_callback - Called when pause button pressed
function pause_button_callback (hObject,eventdata)

global SESSION_IS_RUNNING;
global SESSION_IS_PAUSED;
    
%get the latest version of the data
handles = guidata(hObject);

is_running = get(handles.mainfig, 'userdata');

if (is_running == SESSION_IS_PAUSED)
    %If we have a currently paused session, start running it again
    set(handles.mainfig, 'userdata', SESSION_IS_RUNNING);
    
    %Update the text of the start/stop button
    set(handles.pause_button, 'string', 'Pause');
    set(handles.feed_button, 'enable', 'on');
elseif (is_running == SESSION_IS_RUNNING)
    %If we are currently running a session, pause it
    set(handles.mainfig, 'userdata', SESSION_IS_PAUSED);
    
    %Update the text of the start/stop button
    set(handles.pause_button, 'string', 'Unpause');
    set(handles.feed_button, 'enable', 'off');
end

%Update the gui data structure
guidata(hObject, handles);


%% feed_button_callback - Called when feed button pressed
function feed_button_callback (hObject,eventdata)

global SESSION_MANUAL_FEED;
global SESSION_IS_RUNNING;

%Grab the handles object
handles = guidata(hObject);

is_running = get(handles.mainfig, 'userdata');

%This operation is only allowed if a session is currently running
if (is_running == SESSION_IS_RUNNING)

    %Update the run variable to indicate a manual feed is needed
    set(handles.mainfig, 'userdata', SESSION_MANUAL_FEED);

end

%Update the handles object
guidata(hObject, handles);


%% close_figure_callback - Called when user closes program
function close_figure_callback (hObject,eventdata)

global SESSION_IS_STOPPED;
handles = guidata(hObject);

is_running = get(handles.mainfig, 'userdata');

if (is_running ~= SESSION_IS_STOPPED)
    
    %Update the data to tell the program that the session is stopped.
    set(handles.mainfig, 'userdata', SESSION_IS_STOPPED);
    
    %Pause for a little bit to let the BehaviorLoop finish
    pause(0.1);

end

%Turn off the cage light
handles.ardy.cage_lights(0);

closereq;

%% change_rat_name_callback - Called when the user changes the rat name
function change_rat_name_callback (hObject, eventdata)

handles = guidata(hObject);                                                 %Grab the handles structure from the GUI.
temp = get(hObject,'string');                                               %Grab the string from the rat name editbox.
for c = '/\?%*:|"<>. '                                                      %Step through all reserved characters.
    temp(temp == c) = [];                                                   %Kick out any reserved characters from the rat name.
end
if ~strcmpi(temp,handles.ratname)                                           %If the rat's name was changed.
    handles.ratname = upper(temp);                                          %Save the new rat name in the handles structure.
    guidata(handles.mainfig,handles);                                       %Pin the handles structure to the main figure.
end
set(handles.rat_name_text_box,'string',handles.ratname);                              %Reset the rat name in the rat name editbox.
guidata(handles.mainfig,handles);                                           %Pin the handles structure to the main figure.


%% select_stage_callback - Called when the user selects a stage
function select_stage_callback (hObject, eventdata)

handles = guidata(hObject);
i = get(hObject, 'value');

%Enable the start/stop button now that a new stage has been chosen
set(handles.start_stop_button, 'enable', 'on');

%If the selected stage is different from the current stage.
if i ~= handles.cur_stage && i <= length(handles.stage)                     
    %Set the current stage to the selected stage.
    handles.cur_stage = i;                                                  
    
    %Load the parameters for the chosen stage
    handles = choose_stage (handles);
    
    %Pin the handles structure to the main figure.
    guidata(handles.mainfig,handles);                                       
end

%% choose_stage - Sets the parameters for the chosen stage
function handles = choose_stage (handles)

%Load the parameters for this stage
handles.pre_trial_wait = handles.stage(handles.cur_stage).minwait;
handles.pre_trial_wait_end = handles.stage(handles.cur_stage).minend;
handles.pre_trial_wait_slope = handles.stage(handles.cur_stage).minslope;

handles.random_trial_wait = handles.stage(handles.cur_stage).randwait;
handles.random_trial_wait_end = handles.stage(handles.cur_stage).randend;
handles.random_trial_wait_slope = handles.stage(handles.cur_stage).randslope;

handles.response_time_threshold = handles.stage(handles.cur_stage).hitwin;
handles.catch_trial_percentage = handles.stage(handles.cur_stage).catchtrialpercent;
handles.timeout_period = handles.stage(handles.cur_stage).timeout;
handles.cue_intensity = handles.stage(handles.cur_stage).cueintensity;
handles.cue_duration = handles.stage(handles.cur_stage).cueduration;
handles.distractor_intensity = handles.stage(handles.cur_stage).distractorintensity;

%Save the parameter values
guidata(handles.mainfig, handles);

%Change the drop down box to show the new selected stage
stage_descriptions = {handles.stage.description};
set(handles.stage_combo_box, 'string', stage_descriptions, 'value', handles.cur_stage);

%% write_file_header - Begins writing the file for the current session
function fid = write_file_header (handles)

%If the main data folder doesn't already exist on the C:\ drive...
if ~exist(handles.primary_data_path,'dir')                                           
    mkdir(handles.primary_data_path);                                      
end

%Make the folder name for this rat.
filename = [handles.primary_data_path handles.ratname '\'];                          
if ~exist(filename,'dir')                                                   
    mkdir(filename);                                                        
end

%Make a folder name for the current stage in this rat's folder.
filename = [filename handles.ratname '-' 'Stage' ...
    handles.stage(handles.cur_stage).number '\'];                           
if ~exist(filename,'dir')                                                   
    mkdir(filename);                                                        
end

%Grab a timestamp accurate to the second.
temp = datestr(now,30);

handles.vns = 0; %HACK!
%If we're not stimulating...      
if handles.vns == 0                                                         
    stim = 'NoVNS';                                                         
else                                                                        
    stim = 'VNS';                                                           
end

temp = [handles.ratname...                                                  %(Rat name)
    '_' temp...                                                             %(Timestamp)
    '_Stage' handles.stage(handles.cur_stage).number...                     %(Stage title)
    '_' stim...                                                             %(VNS on or off)
    '.ArdyNeglect' ];                                                       %Create the filename, including the full pathandles.

%Add the path to the filename.
filename = [filename temp];                                                 

%Open the data file as a binary file for writing.
fid = fopen(filename,'w');                       

fwrite(fid,-4,'int8');                                                      %Write the data file version number.
fwrite(fid,now,'double');                                                   %Write the serial date number.
fwrite(fid,handles.booth,'uint8');                                          %Write the booth number.
fwrite(fid,length(handles.ratname),'uint8');                                %Write the number of characters in the rat's name.
fwrite(fid,handles.ratname,'uchar');                                        %Write the characters of the rat's name.
fwrite(fid,length(handles.stage(handles.cur_stage).description),'uint8');   %Write the number of characters in the stage description.
fwrite(fid,handles.stage(handles.cur_stage).description,'uchar');           %Write the characters of the stage description.


