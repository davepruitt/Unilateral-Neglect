function UNP_Latency ( data, popdata )

for r = 2
    
    pre = nanmean(popdata.n5_latency(r, 1:5, 1));
    pre_left = nanmean(popdata.n5_latency_left(r, 1:5, 1));
    pre_right = nanmean(popdata.n5_latency_right(r, 1:5, 1));
    
    if (r == 2)
        post = popdata.n8_latency(r, 1:end, 1);
        post_left = popdata.n8_latency_left(r, 1:end, 1);
        post_right = popdata.n8_latency_right(r, 1:end, 1);
    else
        post = popdata.n6_latency(r, 1:end, 1);
        post_left = popdata.n6_latency_left(r, 1:end, 1);
        post_right = popdata.n6_latency_right(r, 1:end, 1);
    end
    
    plot_data = [pre nanmean(post(1:2)) nanmean(post(3:7)) nanmean(post(8:12))];
    plot_data_left = [pre_left nanmean(post_left(1:2)) nanmean(post_left(3:7)) nanmean(post_left(8:12))];
    plot_data_left_sems = [sem(popdata.n5_latency_left(r, 1:5, 1)') sem(post_left(1:2)') sem(post_left(3:7)') sem(post_left(8:12)')];
    plot_data_right = [pre_right nanmean(post_right(1:2)) nanmean(post_right(3:7)) nanmean(post_right(8:12))];
    plot_data_right_sems = [sem(popdata.n5_latency_right(r, 1:5, 1)') sem(post_right(1:2)') sem(post_right(3:7)') sem(post_right(8:12)')];
    
    figure;
    hold on;
    %plot(plot_data, 'LineWidth', 4, 'Color', [1 0 0]);
    errorbar(1:length(plot_data_left), plot_data_left, plot_data_left_sems, plot_data_left_sems, 'LineWidth', 4, 'Color', [1 0 0]);
    errorbar(1:length(plot_data_right), plot_data_right, plot_data_right_sems, plot_data_right_sems, 'LineWidth', 4, 'Color', [0 0 1]);
    %plot(plot_data_left, 'LineWidth', 4, 'Color', [0 0.7 0]);
    %plot(plot_data_right, 'LineWidth', 4, 'Color', [0 0 1]);
    line([1.5 1.5], ylim, 'LineStyle', '--');
    %legend('Both Sides', 'Left Side', 'Right Ride');
    legend('Left Side', 'Right Ride');
    xlim([0 5]);
    set(gca, 'XTick', 1:4);
    set(gca, 'XTickLabel', {'Pre', 'Post', 'Week 1', 'Week 2'});
    ylabel('Latency (s)');
    
end


end

