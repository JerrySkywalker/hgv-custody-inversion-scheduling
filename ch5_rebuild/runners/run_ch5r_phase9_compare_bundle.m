function out = run_ch5r_phase9_compare_bundle()
%RUN_CH5R_PHASE9_COMPARE_BUNDLE
% Compare R4 / R5 / R9 under a unified output bundle.

cfg = default_ch5r_params(true);

out4 = run_ch5r_phase4_tracking_baseline();
out5 = run_ch5r_phase5_bubble_predictive();
out9 = run_ch5r_phase9_r9_closedloop();

T = table( ...
    ["R4-real_dynamic_pair"; "R5-real_predictive_pair"; "R9-real_koopman_pipe_feedback"], ...
    [out4.result.bubble_metrics.total_valid_steps; out5.result.bubble_metrics.total_valid_steps; out9.result.bubble_metrics.total_valid_steps], ...
    [out4.result.bubble_metrics.bubble_steps; out5.result.bubble_metrics.bubble_steps; out9.result.bubble_metrics.bubble_steps], ...
    [out4.result.bubble_metrics.bubble_time_s; out5.result.bubble_metrics.bubble_time_s; out9.result.bubble_metrics.bubble_time_s], ...
    [out4.result.bubble_metrics.longest_bubble_time_s; out5.result.bubble_metrics.longest_bubble_time_s; out9.result.bubble_metrics.longest_bubble_time_s], ...
    [out4.result.bubble_metrics.max_bubble_depth; out5.result.bubble_metrics.max_bubble_depth; out9.result.bubble_metrics.max_bubble_depth], ...
    [out4.result.bubble_metrics.mean_bubble_depth; out5.result.bubble_metrics.mean_bubble_depth; out9.result.bubble_metrics.mean_bubble_depth], ...
    [out4.result.cost_metrics.switch_count; out5.result.cost_metrics.switch_count; out9.result.cost_metrics.switch_count], ...
    [NaN; NaN; out9.result.r9_tracking.mean_rmse_pos_km], ...
    [NaN; NaN; out9.result.r9_tracking.final_rmse_pos_km], ...
    'VariableNames', { ...
        'policy', ...
        'valid_steps', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'longest_bubble_time_s', ...
        'max_bubble_depth', ...
        'mean_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_pos_km', ...
        'final_rmse_pos_km'});

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR9_compare_bundle');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR9_compare_bundle_' stamp '.csv']);
md_file = fullfile(out_dir, ['phaseR9_compare_bundle_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR9_compare_bundle_' stamp '.mat']);

writetable(T, csv_file);

md = local_build_md(T, csv_file, out4, out5, out9);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out4', 'out5', 'out9', 'T');

disp(' ')
disp('=== [ch5r:R9-compare] compare bundle summary ===')
disp(T)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])

out = struct();
out.cfg = cfg;
out.out4 = out4;
out.out5 = out5;
out.out9 = out9;
out.summary_table = T;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'md_file', md_file, ...
    'mat_file', mat_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, csv_file, out4, out5, out9)
lines = {};

lines{end+1} = '# Phase R9 Compare Bundle';
lines{end+1} = '';
lines{end+1} = '## 1. Role';
lines{end+1} = '';
lines{end+1} = ['This bundle compares R4, R5, and R9 under the same valid full-window bubble semantics.'];
lines{end+1} = ['R9 additionally reports tracking RMSE because it includes the Koopman-DMD tracking loop.'];
lines{end+1} = '';
lines{end+1} = '## 2. Interpretation notes';
lines{end+1} = '';
lines{end+1} = ['- R4 and R5 currently do not run the closed-loop tracking estimator, so RMSE fields are reported as NaN.'];
lines{end+1} = ['- Switch count is recorded as a descriptive metric only; it is not the optimization target in current R9.'];
lines{end+1} = '';
lines{end+1} = '## 3. Quick reading';
lines{end+1} = '';
lines{end+1} = ['- R4 bubble steps: ', num2str(out4.result.bubble_metrics.bubble_steps)];
lines{end+1} = ['- R5 bubble steps: ', num2str(out5.result.bubble_metrics.bubble_steps)];
lines{end+1} = ['- R9 bubble steps: ', num2str(out9.result.bubble_metrics.bubble_steps)];
lines{end+1} = ['- R9 mean RMSE position (km): ', num2str(out9.result.r9_tracking.mean_rmse_pos_km, '%.12g')];
lines{end+1} = ['- R9 final RMSE position (km): ', num2str(out9.result.r9_tracking.final_rmse_pos_km, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 4. Artifact';
lines{end+1} = '';
lines{end+1} = ['- csv: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '## 5. Summary table';
lines{end+1} = '';
lines{end+1} = '| policy | valid_steps | bubble_steps | bubble_time_s | longest_bubble_time_s | max_bubble_depth | mean_bubble_depth | switch_count | mean_rmse_pos_km | final_rmse_pos_km |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|';

for i = 1:height(T)
    mean_rmse_text = 'NaN';
    final_rmse_text = 'NaN';
    if ~isnan(T.mean_rmse_pos_km(i))
        mean_rmse_text = num2str(T.mean_rmse_pos_km(i), '%.12g');
    end
    if ~isnan(T.final_rmse_pos_km(i))
        final_rmse_text = num2str(T.final_rmse_pos_km(i), '%.12g');
    end

    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.valid_steps(i)), ...
        ' | ', num2str(T.bubble_steps(i)), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.max_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', mean_rmse_text, ...
        ' | ', final_rmse_text, ' |'];
end

md = strjoin(lines, newline);
end
