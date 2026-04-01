function fig = plot_ck_ablation_summary(scene_name, methods, save_path)
%PLOT_CK_ABLATION_SUMMARY  Plot grouped summary for CK ablation.
%
% methods: struct array with fields
%   name
%   q_worst_window
%   phi_mean
%   outage_ratio
%   longest_outage_steps
%   mean_rmse

labels = string({methods.name});
qworst = [methods.q_worst_window];
phimean = [methods.phi_mean];
outage = [methods.outage_ratio];
longest = [methods.longest_outage_steps];
rmse = [methods.mean_rmse];

fig = figure('Color', 'w', 'Visible', 'off', 'Position', [100 100 1200 700]);

tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
bar(qworst);
title('q\_worst\_window');
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

nexttile;
bar(phimean);
title('\phi mean');
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

nexttile;
bar(outage);
title('Outage ratio');
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

nexttile;
bar(longest);
title('Longest outage steps');
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

nexttile;
bar(rmse);
title('Mean RMSE');
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels);

nexttile;
axis off
text(0, 0.9, ['Scene: ', scene_name], 'FontSize', 12, 'Interpreter', 'none');
text(0, 0.7, 'Phase 7B ablation', 'FontSize', 12, 'Interpreter', 'none');
text(0, 0.5, 'Lower is better: outage, longest outage, RMSE', 'FontSize', 10, 'Interpreter', 'none');
text(0, 0.35, 'Higher is better: q\_worst\_window, \phi mean', 'FontSize', 10, 'Interpreter', 'none');

sgtitle(['Chapter 5 Phase 7B Ablation - ', scene_name], 'Interpreter', 'none');

if nargin >= 3 && ~isempty(save_path)
    out_dir = fileparts(save_path);
    if ~exist(out_dir, 'dir'); mkdir(out_dir); end
    exportgraphics(fig, save_path, 'Resolution', 200);
end
end
