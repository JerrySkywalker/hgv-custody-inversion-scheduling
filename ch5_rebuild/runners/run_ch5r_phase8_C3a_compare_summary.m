function out = run_ch5r_phase8_C3a_compare_summary()
%RUN_CH5R_PHASE8_C3A_COMPARE_SUMMARY
% Compare latest R5-real output and latest R8-C.3 output, then write:
%   - markdown summary
%   - csv comparison table
%   - mat package

base_out = fullfile(pwd, 'outputs', 'ch5_rebuild');

r5_dir  = fullfile(base_out, 'phaseR5_bubble_predictive_real');
r8c3_dir = fullfile(base_out, 'phaseR8_C3_outerB_bubble_correction_real_kernel');

r5_mat  = local_find_latest_mat(r5_dir,  'phaseR5_bubble_predictive_real_*.mat');
r8c3_mat = local_find_latest_mat(r8c3_dir, 'phaseR8_C3_outerB_bubble_correction_real_kernel_*.mat');

r5 = load(r5_mat);
r8 = load(r8c3_mat);

r5_metrics  = local_extract_r5_metrics(r5);
r8c3_metrics = local_extract_r8c3_metrics(r8);

cmp = table( ...
    ["R5-real"; "R8-C.3"], ...
    [r5_metrics.bubble_steps;    r8c3_metrics.bubble_steps], ...
    [r5_metrics.bubble_time_s;   r8c3_metrics.bubble_time_s], ...
    [r5_metrics.max_bubble_depth; r8c3_metrics.max_bubble_depth], ...
    [r5_metrics.switch_count;    r8c3_metrics.switch_count], ...
    [r5_metrics.resource_score;  r8c3_metrics.resource_score], ...
    [NaN; r8c3_metrics.mean_Xi_B], ...
    [NaN; r8c3_metrics.has_failure_fraction], ...
    [NaN; r8c3_metrics.mean_tau_B_time_s], ...
    [NaN; r8c3_metrics.mean_A_B], ...
    'VariableNames', { ...
        'policy', ...
        'bubble_steps', ...
        'bubble_time_s', ...
        'max_bubble_depth', ...
        'switch_count', ...
        'resource_score', ...
        'mean_Xi_B', ...
        'has_failure_fraction', ...
        'mean_tau_B_time_s', ...
        'mean_A_B'});

delta = struct();
delta.bubble_steps = r8c3_metrics.bubble_steps - r5_metrics.bubble_steps;
delta.bubble_time_s = r8c3_metrics.bubble_time_s - r5_metrics.bubble_time_s;
delta.max_bubble_depth = r8c3_metrics.max_bubble_depth - r5_metrics.max_bubble_depth;
delta.switch_count = r8c3_metrics.switch_count - r5_metrics.switch_count;

out_dir = fullfile(base_out, 'phaseR8_C3a_compare_summary');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_C3a_compare_summary_' stamp '.csv']);
md_file  = fullfile(out_dir, ['phaseR8_C3a_compare_summary_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR8_C3a_compare_summary_' stamp '.mat']);

writetable(cmp, csv_file);
md = local_build_md(r5_mat, r8c3_mat, r5_metrics, r8c3_metrics, delta, csv_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'r5_mat', 'r8c3_mat', 'r5_metrics', 'r8c3_metrics', 'delta', 'cmp');

disp(' ')
disp('=== [ch5r:R8-C.3a] compare summary ===')
disp(cmp)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])

out = struct();
out.compare_table = cmp;
out.delta = delta;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'md_file', md_file, ...
    'mat_file', mat_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function mat_file = local_find_latest_mat(dir_path, pattern)
assert(exist(dir_path, 'dir') == 7, 'Directory not found: %s', dir_path);
d = dir(fullfile(dir_path, pattern));
assert(~isempty(d), 'No matching MAT files found under %s with pattern %s', dir_path, pattern);
[~, idx] = max([d.datenum]);
mat_file = fullfile(d(idx).folder, d(idx).name);
end

function m = local_extract_r5_metrics(S)
assert(isstruct(S), 'Loaded R5 data must be struct.');
assert(isfield(S, 'result'), 'R5 mat missing field: result');
R = S.result;

m = struct();
m.bubble_steps = R.bubble_steps;
m.bubble_time_s = R.bubble_time_s;
m.max_bubble_depth = R.max_bubble_depth;
m.switch_count = R.switch_count;
m.resource_score = R.resource_score;
end

function m = local_extract_r8c3_metrics(S)
assert(isstruct(S), 'Loaded R8-C.3 data must be struct.');
assert(isfield(S, 'result'), 'R8-C.3 mat missing field: result');
assert(isfield(S, 'summary'), 'R8-C.3 mat missing field: summary');

R = S.result;
Q = S.summary;

m = struct();
m.bubble_steps = R.bubble_steps;
m.bubble_time_s = R.bubble_time_s;
m.max_bubble_depth = R.max_bubble_depth;
m.switch_count = R.switch_count;
m.resource_score = R.resource_score;

m.mean_Xi_B = local_get_field_or_nan(Q, 'mean_Xi_B');
m.has_failure_fraction = local_get_field_or_nan(Q, 'has_failure_fraction');
m.mean_tau_B_time_s = local_get_field_or_nan(Q, 'mean_tau_B_time_s');
m.mean_A_B = local_get_field_or_nan(Q, 'mean_A_B');
end

function v = local_get_field_or_nan(S, f)
if isfield(S, f)
    v = S.(f);
else
    v = NaN;
end
end

function md = local_build_md(r5_mat, r8c3_mat, r5, r8, delta, csv_file)
lines = {};

lines{end+1} = '# Phase R8-C.3a：结果口径整理 + 与 R5 对照汇总';
lines{end+1} = '';
lines{end+1} = '## 1. 数据来源';
lines{end+1} = ['- R5-real latest mat: `', r5_mat, '`'];
lines{end+1} = ['- R8-C.3 latest mat: `', r8c3_mat, '`'];
lines{end+1} = ['- CSV summary: `', csv_file, '`'];
lines{end+1} = '';

lines{end+1} = '## 2. 并排指标';
lines{end+1} = '';
lines{end+1} = '| 指标 | R5-real | R8-C.3 | 差值(R8-C.3 - R5-real) |';
lines{end+1} = '|---|---:|---:|---:|';
lines{end+1} = ['| bubble_steps | ', num2str(r5.bubble_steps), ' | ', num2str(r8.bubble_steps), ' | ', num2str(delta.bubble_steps), ' |'];
lines{end+1} = ['| bubble_time_s | ', num2str(r5.bubble_time_s, '%.12g'), ' | ', num2str(r8.bubble_time_s, '%.12g'), ' | ', num2str(delta.bubble_time_s, '%.12g'), ' |'];
lines{end+1} = ['| max_bubble_depth | ', num2str(r5.max_bubble_depth, '%.12g'), ' | ', num2str(r8.max_bubble_depth, '%.12g'), ' | ', num2str(delta.max_bubble_depth, '%.12g'), ' |'];
lines{end+1} = ['| switch_count | ', num2str(r5.switch_count), ' | ', num2str(r8.switch_count), ' | ', num2str(delta.switch_count), ' |'];
lines{end+1} = ['| resource_score | ', num2str(r5.resource_score), ' | ', num2str(r8.resource_score), ' | 0 |'];
lines{end+1} = ['| mean_Xi_B | - | ', num2str(r8.mean_Xi_B, '%.12g'), ' | - |'];
lines{end+1} = ['| has_failure_fraction | - | ', num2str(r8.has_failure_fraction, '%.12g'), ' | - |'];
lines{end+1} = ['| mean_tau_B_time_s | - | ', num2str(r8.mean_tau_B_time_s, '%.12g'), ' | - |'];
lines{end+1} = ['| mean_A_B | - | ', num2str(r8.mean_A_B, '%.12g'), ' | - |'];
lines{end+1} = '';

lines{end+1} = '## 3. 当前口径固定';
lines{end+1} = '';
lines{end+1} = '- R5-real：使用原有 bubble-predictive 实现与真实 future-window kernel。';
lines{end+1} = '- R8-C.3：使用与 R5-real 相同的真实 future-window kernel，但候选排序改为 Xi_B / tau_B / A_B 词典序。';
lines{end+1} = '- 因此本文件的对比重点是：在同内核、同 case、同时变候选集条件下，排序准则变化带来的 bubble 与 switch 差异。';
lines{end+1} = '';

lines{end+1} = '## 4. 当前结果口径（自动生成）';
lines{end+1} = '';
if delta.bubble_steps < 0
    lines{end+1} = ['- R8-C.3 的 bubble_steps 相比 R5-real 减少了 ', num2str(-delta.bubble_steps), '。'];
elseif delta.bubble_steps > 0
    lines{end+1} = ['- R8-C.3 的 bubble_steps 相比 R5-real 增加了 ', num2str(delta.bubble_steps), '。'];
else
    lines{end+1} = '- R8-C.3 的 bubble_steps 与 R5-real 相同。';
end

if delta.bubble_time_s < 0
    lines{end+1} = ['- R8-C.3 的 bubble_time_s 相比 R5-real 减少了 ', num2str(-delta.bubble_time_s, '%.12g'), ' s。'];
elseif delta.bubble_time_s > 0
    lines{end+1} = ['- R8-C.3 的 bubble_time_s 相比 R5-real 增加了 ', num2str(delta.bubble_time_s, '%.12g'), ' s。'];
else
    lines{end+1} = '- R8-C.3 的 bubble_time_s 与 R5-real 相同。';
end

if delta.switch_count < 0
    lines{end+1} = ['- R8-C.3 的 switch_count 相比 R5-real 减少了 ', num2str(-delta.switch_count), '。'];
elseif delta.switch_count > 0
    lines{end+1} = ['- R8-C.3 的 switch_count 相比 R5-real 增加了 ', num2str(delta.switch_count), '。'];
else
    lines{end+1} = '- R8-C.3 的 switch_count 与 R5-real 相同。';
end

lines{end+1} = '';
lines{end+1} = '## 5. 下一步建议';
lines{end+1} = '';
lines{end+1} = '- 若目标是保留更少 bubble_time，同时抑制切换次数，下一步应在 R8-C.3 基础上继续做“切换平滑再设计”。';
lines{end+1} = '- 若目标是统一第二章/第五章理论口径，下一步应明确 Xi_B 当前是“real-kernel-aligned”口径，而不是早先 requirement-induced 口径。';

md = strjoin(lines, newline);
end
