function [ psycho_curve, hit_matrix, sem_psycho_curve ] = UNP_GenerateDistractorPsychometricCurve ( session_list, method )

% Generates a psychometric curve from one session of data based on varying the distractor intensity

%If the user doesn't specify an averaging method, then set it to 0.
%method = 0 indicates that all trials for all days are lumped together
%method = 1 indicates that a mean is calculated across days, giving error bars as well
if (nargin < 2)
    method = 0;
end

TRIAL_MISS = 0;
TRIAL_HIT = 1;
TRIAL_ABORT = 2;
TRIAL_CORRECT_REJECTION = 3;
TRIAL_FALSE_ALARM = 4;

LEFT_NOSEPOKE_IR = 1;
RIGHT_NOSEPOKE_IR = 3;

possible_distractor_intensities = [0 1 2 4 8 16 32 64 128 255];

if (method == 0)
    hit_matrix = zeros(length(possible_distractor_intensities), 2);
else
    hit_matrix = zeros(length(possible_distractor_intensities), 2, length(session_list));
end

%Iterate over each session in the list
for s=1:length(session_list)
    %Grab all trials that were either hits or misses
    non_aborted_trials = session_list(s).trial([session_list(s).trial.result] == TRIAL_MISS | [session_list(s).trial.result] == TRIAL_HIT);

    if (method == 0)
        s_index = 1;
    else
        s_index = s;
    end
    
    for i = 1:length(non_aborted_trials)
        row_index = find(possible_distractor_intensities == non_aborted_trials(i).distractor_intensity, 1, 'first');

        %Increase the total count of trials at this distractor intensity
        hit_matrix(row_index, 1, s_index) = hit_matrix(row_index, 1, s_index) + 1;

        %If it's a hit, increase the total count of trials that were hits at
        %this distractor intensity
        if (non_aborted_trials(i).result == TRIAL_HIT)
            hit_matrix(row_index, 2, s_index) = hit_matrix(row_index, 2, s_index) + 1;
        end
    end

end

if (method == 0)
    %Create an array of hit percentages at each distractor intensity
    psycho_curve = hit_matrix(:, 2) ./ hit_matrix(:, 1);
    sem_psycho_curve = zeros(size(psycho_curve, 1));
else
    temp_psycho_curve = zeros(size(hit_matrix, 1), size(hit_matrix, 3));
    for s=1:length(session_list)
        temp_psycho_curve(:, s) = hit_matrix(:, 2, s) ./ hit_matrix(:, 1, s);
    end
    
    psycho_curve = nanmean(temp_psycho_curve, 2);
    sem_psycho_curve = sem(temp_psycho_curve')';
end



end

