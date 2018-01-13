function UNP_HitRate_PreOnly ( data, popdata )

num_rats = 9;

figure;

for r = 1:num_rats
    
    pre_data = popdata.n5_hitrate(r, 1:end, 1);
    pre_data_left = popdata.n5_hitrate_left(r, 1:end, 1);
    pre_data_right = popdata.n5_hitrate_right(r, 1:end, 1);
    
    pre_data = fliplr(pre_data(~isnan(pre_data)));
    pre_data_left = fliplr(pre_data_left(~isnan(pre_data_left)));
    pre_data_right = fliplr(pre_data_right(~isnan(pre_data_right)));
    
    epoch_size = 5;
    total_epochs = ceil(length(pre_data) / epoch_size);
    
    data_epochs = zeros(total_epochs, 1);
    data_left_epochs = zeros(total_epochs, 1);
    data_right_epochs = zeros(total_epochs, 1);
    epoch_index = 1;
    
    pre_data = [pre_data nan(1, epoch_size)];
    pre_data_left = [pre_data_left nan(1, epoch_size)];
    pre_data_right = [pre_data_right nan(1, epoch_size)];
    
    data_epochs_sems = zeros(total_epochs, 1);
    data_left_epochs_sems = zeros(total_epochs, 1);
    data_right_epochs_sems = zeros(total_epochs, 1);
    
    i = 1;
    for epoch_index = 1:total_epochs
        data_epochs(epoch_index) = nanmean(pre_data(i:(i+epoch_size-1)));
        data_epochs_sems(epoch_index) = sem(pre_data(i:(i+epoch_size-1))');
        
        data_left_epochs(epoch_index) = nanmean(pre_data_left(i:(i+epoch_size-1)));
        data_left_epochs_sems(epoch_index) = sem(pre_data_left(i:(i+epoch_size-1))');
        
        data_right_epochs(epoch_index) = nanmean(pre_data_right(i:(i+epoch_size-1)));
        data_right_epochs_sems(epoch_index) = sem(pre_data_right(i:(i+epoch_size-1))');
        
        i = i + epoch_size;
    end
    
    subplot(3, 3, r);
    hold on;
    
    errorbar(1:length(data_left_epochs), data_left_epochs, data_left_epochs_sems, data_left_epochs_sems, 'LineWidth', 4, 'Color', [1 0 0]);
    errorbar(1:length(data_right_epochs), data_right_epochs, data_right_epochs_sems, data_right_epochs_sems, 'LineWidth', 4, 'Color', [0 0 1]);
    legend('Left Side', 'Right Ride');
    xlim([0 length(data_left_epochs)+1]);
    set(gca, 'XTick', 1:length(data_left_epochs)+1);
    set(gca, 'FontSize', 10);
    ylabel('% Successful Trials', 'FontSize', 10);
    title(data(r).ratname, 'FontSize', 10);
    
end


end

