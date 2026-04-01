function fig = plot_prior_match_summary(scene_name, methods, save_path)
%PLOT_PRIOR_MATCH_SUMMARY
% methods fields:
%   name
%   q_worst_window
%   phi_mean
%   outage_ratio
%   longest_outage_steps
%   mean_rmse
%   switch_count

labels = string({methods.name});
qworst = [methods.q_worst_window];
phimean = [methods.phi_mean];
outage = [methods.outage_ratio];
longest = [methods.longest_outage_steps];
rmse = [methods.mean_rmse];
switch_count = [methods.switch_count];

fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100 100 1350 760]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile; bar(qworst); title('q\_worst\_window'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
nexttile; bar(phimean); title('\phi mean'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
nexttile; bar(outage); title('Outage ratio'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
nexttile; bar(longest); title('Longest outage steps'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
nexttile; bar(rmse); title('Mean RMSE'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);
nexttile; bar(switch_count); title('Switch count'); set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

sgtitle(['Chapter 5 Phase 8 Prior Integration - ', scene_name], 'Interpreter', 'none');

if nargin >= 3 && ~isempty(save_path)
    out_dir = fileparts(save_path);
    if ~exist(out_dir, 'dir'); mkdir(out_dir); end
    exportgraphics(fig, save_path, 'Resolution', 220);
end
end
