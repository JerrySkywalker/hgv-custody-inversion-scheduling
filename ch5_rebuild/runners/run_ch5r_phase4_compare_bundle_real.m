function out = run_ch5r_phase4_compare_bundle_real()
%RUN_CH5R_PHASE4_COMPARE_BUNDLE_REAL
% Formal real comparison bundle for R3-real vs R4-real.

cfg = default_ch5r_params(true);

out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR4_compare_bundle_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

s3 = summarize_ch5r_real_results(out3, 'R3-real_static_pair');
s4 = summarize_ch5r_real_results(out4, 'R4-real_dynamic_pair');

compare_table = struct2table([s3; s4]);

csv_file = fullfile(out_dir, ['phaseR4_compare_table_real_' stamp '.csv']);
writetable(compare_table, csv_file);

fig_paths = plot_tracking_vs_static_summary_real(out3, out4, out_dir, stamp);

md_file = fullfile(out_dir, ['phaseR4_compare_bundle_real_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR4_compare_bundle_real_' stamp '.mat']);

md = local_build_md(compare_table, out3, out4, csv_file, fig_paths);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out3', 'out4', 'compare_table', 'fig_paths');

disp(' ')
disp('=== [ch5r:R4c-real] R3-real vs R4-real comparison summary ===')
disp(compare_table)
disp(['compare csv         : ' csv_file])
disp(['compare md          : ' md_file])
disp(['compare mat         : ' mat_file])

out = struct();
out.cfg = cfg;
out.out3 = out3;
out.out4 = out4;
out.compare_table = compare_table;
out.fig_paths = fig_paths;
out.paths = struct('csv_file', csv_file, 'md_file', md_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, out3, out4, csv_file, fig_paths)
improve_bubble_time = out3.result.bubble_metrics.bubble_time_s - out4.result.bubble_metrics.bubble_time_s;
improve_pct = 100 * improve_bubble_time / max(out3.result.bubble_metrics.bubble_time_s, eps);

lines = {};
lines{end+1} = '# Phase R4c-real Comparison Bundle';
lines{end+1} = '';
lines{end+1} = '## 1. Comparison role';
lines{end+1} = '';
lines{end+1} = 'This bundle compares:';
lines{end+1} = '- R3-real: fixed static double-satellite pair';
lines{end+1} = '- R4-real: dynamic double-satellite scheduling';
lines{end+1} = '';
lines{end+1} = '## 2. Key findings';
lines{end+1} = '';
lines{end+1} = ['- R3-real bubble_time_s = ', num2str(out3.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- R4-real bubble_time_s = ', num2str(out4.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- bubble_time reduction = ', num2str(improve_bubble_time, '%.6f'), ...
    ' s (', num2str(improve_pct, '%.3f'), '%)'];
lines{end+1} = ['- R3-real max_bubble_depth = ', num2str(out3.result.bubble_metrics.max_bubble_depth, '%.12g')];
lines{end+1} = ['- R4-real max_bubble_depth = ', num2str(out4.result.bubble_metrics.max_bubble_depth, '%.12g')];
lines{end+1} = ['- R4-real switch_count = ', num2str(out4.result.cost_metrics.switch_count)];
lines{end+1} = '';
lines{end+1} = '## 3. Interpretation';
lines{end+1} = '';
lines{end+1} = ['Current note: RMSE-related fields below are Fisher-based RMSE proxies, ' ...
    'not physical filter RMSE.'];
lines{end+1} = '';
if out4.result.bubble_metrics.bubble_time_s < out3.result.bubble_metrics.bubble_time_s
    lines{end+1} = ['Dynamic double-satellite scheduling reduces bubble duration ' ...
        'relative to the fixed static pair baseline under the same two-satellite resource constraint.'];
else
    lines{end+1} = ['Dynamic double-satellite scheduling does not reduce bubble duration ' ...
        'relative to the fixed static pair baseline.'];
end
lines{end+1} = '';
lines{end+1} = '## 4. Artifacts';
lines{end+1} = '';
lines{end+1} = ['- compare table csv: `', csv_file, '`'];
lines{end+1} = ['- lambda timeline plot: `', fig_paths.lambda_timeline_png, '`'];
lines{end+1} = ['- bubble flag plot: `', fig_paths.bubble_flag_png, '`'];
lines{end+1} = ['- pair trace plot: `', fig_paths.pair_trace_png, '`'];
lines{end+1} = ['- summary bar plot: `', fig_paths.summary_bar_png, '`'];
lines{end+1} = '';
lines{end+1} = '## 5. Summary table';
lines{end+1} = '';
lines{end+1} = '| policy | bubble_steps | bubble_fraction | bubble_time_s | longest_bubble_time_s | max_bubble_depth | mean_bubble_depth | loc_total_time_s | custody_ratio | mean_rmse_proxy | min_margin | switch_count | resource_score | observable_steps |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.bubble_steps(i)), ...
        ' | ', num2str(T.bubble_fraction(i), '%.6f'), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.max_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.loc_total_time_s(i), '%.6f'), ...
        ' | ', num2str(T.custody_ratio(i), '%.6f'), ...
        ' | ', num2str(T.mean_rmse_proxy(i), '%.12g'), ...
        ' | ', num2str(T.min_margin(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', num2str(T.resource_score(i), '%.6f'), ...
        ' | ', num2str(T.observable_steps(i)), ' |'];
end

md = strjoin(lines, newline);
end
