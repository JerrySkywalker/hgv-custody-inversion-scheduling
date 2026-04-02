function figs = plot_ws5_publication_style(scene_preset, profiles_summary, fig_dir)
%PLOT_WS5_PUBLICATION_STYLE
% WS-5-R5
% Publication-style plots with readable titles and fixed y/color ranges.

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

names = string({profiles_summary.profile_name});
topK = [profiles_summary.topK];
cap = [profiles_summary.library_pair_cap];
ratioA = [profiles_summary.ratio_changed_C_vs_A];
ratioB = [profiles_summary.ratio_changed_C_vs_B];
comp = [profiles_summary.mean_compression_ratio];
kept = [profiles_summary.mean_num_kept_candidates];

figs = struct();

% 1) decision-change ratio bar
f1 = figure('Visible','off');
bar(ratioA);
ylim([0 1]);
set(gca, 'XTick', 1:numel(names), 'XTickLabel', cellstr(names));
ylabel('Decision-change ratio');
title(sprintf('%s: Template filtering vs baseline', scene_preset), 'Interpreter', 'none');
grid on
file1 = fullfile(fig_dir, 'ws5_pub_decision_change_vs_baseline.png');
saveas(f1, file1);
close(f1);
figs.decision_change_vs_baseline = file1;

% 2) decision-change ratio vs reference-only
f2 = figure('Visible','off');
bar(ratioB);
ylim([0 1]);
set(gca, 'XTick', 1:numel(names), 'XTickLabel', cellstr(names));
ylabel('Decision-change ratio');
title(sprintf('%s: Template filtering vs reference-only', scene_preset), 'Interpreter', 'none');
grid on
file2 = fullfile(fig_dir, 'ws5_pub_decision_change_vs_reference.png');
saveas(f2, file2);
close(f2);
figs.decision_change_vs_reference = file2;

% 3) compression ratio bar
f3 = figure('Visible','off');
bar(comp);
ylim([0 1]);
set(gca, 'XTick', 1:numel(names), 'XTickLabel', cellstr(names));
ylabel('Average compression ratio');
title(sprintf('%s: Candidate-set compression', scene_preset), 'Interpreter', 'none');
grid on
file3 = fullfile(fig_dir, 'ws5_pub_compression_ratio.png');
saveas(f3, file3);
close(f3);
figs.compression_ratio = file3;

% 4) kept candidates bar
f4 = figure('Visible','off');
bar(kept);
set(gca, 'XTick', 1:numel(names), 'XTickLabel', cellstr(names));
ylabel('Average kept candidates');
title(sprintf('%s: Average kept candidate count', scene_preset), 'Interpreter', 'none');
grid on
file4 = fullfile(fig_dir, 'ws5_pub_kept_candidates.png');
saveas(f4, file4);
close(f4);
figs.kept_candidates = file4;

% 5) profile table-like scatter
f5 = figure('Visible','off');
scatter(topK, cap, 120, ratioA, 'filled');
xlabel('topK');
ylabel('library pair cap');
title(sprintf('%s: Recommended profile map', scene_preset), 'Interpreter', 'none');
cb = colorbar;
ylabel(cb, 'Decision-change ratio vs baseline');
clim([0 1]);
grid on
file5 = fullfile(fig_dir, 'ws5_pub_profile_map.png');
saveas(f5, file5);
close(f5);
figs.profile_map = file5;
end
