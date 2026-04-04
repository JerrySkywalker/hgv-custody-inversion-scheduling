function out = run_ch5r_phase4_compare_bundle()
%RUN_CH5R_PHASE4_COMPARE_BUNDLE  Formal R4c comparison bundle for static vs tracking.

cfg = default_ch5r_params();

out3 = run_ch5r_phase3_static_bubble_demo();
out4 = run_ch5r_phase4_tracking_baseline();

out_dir = cfg.ch5r.output_dirs.phaseR4;
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

s3 = summarize_ch5r_results(out3, 'static_hold');
s4 = summarize_ch5r_results(out4, 'tracking_greedy');

compare_table = struct2table([s3; s4]);

csv_file = fullfile(out_dir, ['phaseR4_compare_table_' stamp '.csv']);
writetable(compare_table, csv_file);

fig_paths = plot_tracking_vs_static_summary(out3, out4, out_dir, stamp);

md_file = fullfile(out_dir, ['phaseR4_compare_bundle_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR4_compare_bundle_' stamp '.mat']);

md = local_build_md(compare_table, out3, out4, csv_file, fig_paths);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out3', 'out4', 'compare_table', 'fig_paths');

disp(' ')
disp('=== [ch5r:R4c] static vs tracking comparison summary ===')
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
lines = {};
lines{end+1} = '# Phase R4c Static-Hold vs Tracking-Greedy Comparison Bundle';
lines{end+1} = '';
lines{end+1} = '## 1. Comparison role';
lines{end+1} = '';
lines{end+1} = 'This bundle summarizes the Chapter 5 Experiment Group A vs B comparison:';
lines{end+1} = '- static_hold';
lines{end+1} = '- tracking_greedy';
lines{end+1} = '';
lines{end+1} = '## 2. Key findings';
lines{end+1} = '';
lines{end+1} = ['- bubble_time_s: static=', num2str(out3.result.bubble_metrics.bubble_time_s, '%.6f'), ...
    ', tracking=', num2str(out4.result.bubble_metrics.bubble_time_s, '%.6f')];
lines{end+1} = ['- max_bubble_depth: static=', num2str(out3.result.bubble_metrics.max_bubble_depth, '%.12g'), ...
    ', tracking=', num2str(out4.result.bubble_metrics.max_bubble_depth, '%.12g')];
lines{end+1} = ['- resource_score: static=', num2str(out3.result.cost_metrics.resource_score, '%.6f'), ...
    ', tracking=', num2str(out4.result.cost_metrics.resource_score, '%.6f')];
lines{end+1} = ['- switch_count: static=', num2str(out3.result.cost_metrics.switch_count), ...
    ', tracking=', num2str(out4.result.cost_metrics.switch_count)];
lines{end+1} = '';
lines{end+1} = '## 3. Interpretation';
lines{end+1} = '';
if out4.result.bubble_metrics.bubble_time_s == out3.result.bubble_metrics.bubble_time_s
    lines{end+1} = ['Tracking-greedy has not shortened bubble duration relative to static_hold, ' ...
        'but may still alter resource usage and bubble depth.'];
else
    lines{end+1} = 'Tracking-greedy changes the bubble duration relative to static_hold.';
end
lines{end+1} = '';
lines{end+1} = '## 4. Artifacts';
lines{end+1} = '';
lines{end+1} = ['- compare table csv: `', csv_file, '`'];
lines{end+1} = ['- lambda timeline plot: `', fig_paths.lambda_timeline_png, '`'];
lines{end+1} = ['- bubble flag plot: `', fig_paths.bubble_flag_png, '`'];
lines{end+1} = ['- summary bar plot: `', fig_paths.summary_bar_png, '`'];
lines{end+1} = '';
lines{end+1} = '## 5. Summary table';
lines{end+1} = '';
lines{end+1} = '| policy | bubble_fraction | bubble_time_s | longest_bubble_time_s | max_bubble_depth | loc_total_time_s | custody_ratio | mean_rmse | min_margin | resource_score | switch_count |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.bubble_fraction(i), '%.6f'), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.max_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.loc_total_time_s(i), '%.6f'), ...
        ' | ', num2str(T.custody_ratio(i), '%.6f'), ...
        ' | ', num2str(T.mean_rmse(i), '%.12g'), ...
        ' | ', num2str(T.min_margin(i), '%.12g'), ...
        ' | ', num2str(T.resource_score(i), '%.6f'), ...
        ' | ', num2str(T.switch_count(i)), ' |'];
end

md = strjoin(lines, newline);
end
