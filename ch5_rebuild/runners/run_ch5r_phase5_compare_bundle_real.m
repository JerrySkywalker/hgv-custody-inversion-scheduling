function out = run_ch5r_phase5_compare_bundle_real()
%RUN_CH5R_PHASE5_COMPARE_BUNDLE_REAL
% Compare R3-real / R4-real / R5-real and draw RMSE proxy curve.

cfg = default_ch5r_params(true);

out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();
out5 = run_ch5r_phase5_bubble_predictive();

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR5_compare_bundle_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

s3 = summarize_ch5r_real_results(out3, 'R3-real_static_pair');
s4 = summarize_ch5r_real_results(out4, 'R4-real_dynamic_pair');
s5 = summarize_ch5r_real_results(out5, 'R5-real_predictive_pair');

compare_table = struct2table([s3; s4; s5]);

csv_file = fullfile(out_dir, ['phaseR5_compare_table_real_' stamp '.csv']);
writetable(compare_table, csv_file);

rmse_fig = plot_ch5r_rmse_proxy_comparison(out3, out4, out5, out_dir, stamp);

md_file = fullfile(out_dir, ['phaseR5_compare_bundle_real_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR5_compare_bundle_real_' stamp '.mat']);

md = local_build_md(compare_table, out3, out4, out5, csv_file, rmse_fig);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out3', 'out4', 'out5', 'compare_table', 'rmse_fig');

disp(' ')
disp('=== [ch5r:R5c-real] R3-real vs R4-real vs R5-real comparison summary ===')
disp(compare_table)
disp(['compare csv         : ' csv_file])
disp(['compare md          : ' md_file])
disp(['compare mat         : ' mat_file])
disp(['rmse fig            : ' rmse_fig])

out = struct();
out.cfg = cfg;
out.out3 = out3;
out.out4 = out4;
out.out5 = out5;
out.compare_table = compare_table;
out.paths = struct('csv_file', csv_file, 'md_file', md_file, 'mat_file', mat_file, 'rmse_fig', rmse_fig, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, out3, out4, out5, csv_file, rmse_fig)
improve_54 = out4.result.bubble_metrics.bubble_time_s - out5.result.bubble_metrics.bubble_time_s;
improve_53 = out3.result.bubble_metrics.bubble_time_s - out5.result.bubble_metrics.bubble_time_s;

lines = {};
lines{end+1} = '# Phase R5c-real Comparison Bundle';
lines{end+1} = '';
lines{end+1} = '## 1. Comparison role';
lines{end+1} = '';
lines{end+1} = 'This bundle compares:';
lines{end+1} = '- R3-real: fixed static double-satellite pair';
lines{end+1} = '- R4-real: dynamic double-satellite scheduling';
lines{end+1} = '- R5-real: future-window-oriented bubble-predictive scheduling';
lines{end+1} = '';
lines{end+1} = '## 2. Key findings';
lines{end+1} = '';
lines{end+1} = ['- R3-real bubble_time_s = ', num2str(out3.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- R4-real bubble_time_s = ', num2str(out4.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- R5-real bubble_time_s = ', num2str(out5.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- R5-real improves over R4-real by ', num2str(improve_54, '%.6f'), ' s'];
lines{end+1} = ['- R5-real improves over R3-real by ', num2str(improve_53, '%.6f'), ' s'];
lines{end+1} = '';
lines{end+1} = '## 3. RMSE proxy note';
lines{end+1} = '';
lines{end+1} = ['RMSE-related fields are Fisher-based RMSE proxies, ' ...
    'not physical filter RMSE. Use them for relative trend comparison only.'];
lines{end+1} = '';
lines{end+1} = '## 4. Artifacts';
lines{end+1} = '';
lines{end+1} = ['- compare table csv: `', csv_file, '`'];
lines{end+1} = ['- RMSE proxy figure: `', rmse_fig, '`'];
lines{end+1} = '';
lines{end+1} = '## 5. Summary table';
lines{end+1} = '';
lines{end+1} = '| policy | bubble_steps | bubble_fraction | bubble_time_s | max_bubble_depth | mean_bubble_depth | custody_ratio | mean_rmse_proxy | min_margin | switch_count | resource_score | observable_steps |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.bubble_steps(i)), ...
        ' | ', num2str(T.bubble_fraction(i), '%.6f'), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.max_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.custody_ratio(i), '%.6f'), ...
        ' | ', num2str(T.mean_rmse_proxy(i), '%.12g'), ...
        ' | ', num2str(T.min_margin(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', num2str(T.resource_score(i), '%.6f'), ...
        ' | ', num2str(T.observable_steps(i)), ' |'];
end

md = strjoin(lines, newline);
end
