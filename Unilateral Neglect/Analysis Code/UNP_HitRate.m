function UNP_HitRate ( data, popdata )

num_rats = 9;

figure;

for r = 1:num_rats
    
    %Filter the pre-lesion data into epochs that are 5 days long
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
    
    
    %Filter post-lesion data into epochs
    if (any(strcmpi(data(r).ratname, {'UNP2', 'UNP5'})))
        %Some rats trained on N8 post-lesion.
        post = popdata.n8_hitrate(r, 1:end, 1);
        post_left = popdata.n8_hitrate_left(r, 1:end, 1);
        post_right = popdata.n8_hitrate_right(r, 1:end, 1);
    else 
        post = popdata.n6_hitrate(r, 1:end, 1);
        post_left = popdata.n6_hitrate_left(r, 1:end, 1);
        post_right = popdata.n6_hitrate_right(r, 1:end, 1);
    end
    
    total_epochs = ceil(length(post) / epoch_size);
    epoch_size = 5;
    
    data_epochs_post = zeros(total_epochs, 1);
    data_left_epochs_post = zeros(total_epochs, 1);
    data_right_epochs_post = zeros(total_epochs, 1);
    
    post = [post nan(1, epoch_size)];
    post_left = [post_left nan(1, epoch_size)];
    post_right = [post_right nan(1, epoch_size)];
    
    data_epochs_sems_post = zeros(total_epochs, 1);
    data_left_epochs_sems_post = zeros(total_epochs, 1);
    data_right_epochs_sems_post = zeros(total_epochs, 1);
    epoch_index = 1;
    
    i = 1;
    for epoch_index = 1:total_epochs
        data_epochs_post(epoch_index) = nanmean(post(i:(i+epoch_size-1)));
        data_epochs_sems_post(epoch_index) = sem(post(i:(i+epoch_size-1))');
        
        data_left_epochs_post(epoch_index) = nanmean(post_left(i:(i+epoch_size-1)));
        data_left_epochs_sems_post(epoch_index) = sem(post_left(i:(i+epoch_size-1))');
        
        data_right_epochs_post(epoch_index) = nanmean(post_right(i:(i+epoch_size-1)));
        data_right_epochs_sems_post(epoch_index) = sem(post_right(i:(i+epoch_size-1))');
        
        i = i + epoch_size;
    end
    
    
    %Combine pre and post
    lesion_line_x = size(data_epochs, 1) + 0.5;
    plot_data_left = [data_left_epochs; data_left_epochs_post];
    plot_data_left_sems = [data_left_epochs_sems; data_left_epochs_sems_post];
    plot_data_right = [data_right_epochs; data_right_epochs_post];
    plot_data_right_sems = [data_right_epochs_sems; data_right_epochs_sems_post];
    
    subplot(3, 3, r);
    hold on;
    errorbar(1:length(plot_data_left), plot_data_left, plot_data_left_sems, plot_data_left_sems, 'LineWidth', 4, 'Color', [1 0 0]);
    errorbar(1:length(plot_data_right), plot_data_right, plot_data_right_sems, plot_data_right_sems, 'LineWidth', 4, 'Color', [0 0 1]);
    line([lesion_line_x lesion_line_x], ylim, 'LineStyle', '--');
    legend('Left Side', 'Right Ride');
    %xlim([0 6]);
    %set(gca, 'XTick', 1:5);
    %set(gca, 'XTickLabel', {'Pre', 'Week 1', 'Week 2', 'Week 3', 'Week 4'});
    set(gca, 'FontSize', 10);
    ylabel('% Successful Trials', 'FontSize', 10);
    title(data(r).ratname, 'FontSize', 10);
    
end


end

