function out = run_ch5r_phase0_freeze_single_case_baseline(opts)
%RUN_CH5R_PHASE0_FREEZE_SINGLE_CASE_BASELINE
% Freeze the current single-case Chapter 5 baseline:
% - bootstrap smoke
% - R4 / R5 / R9 / R10
% - write MAT / JSON / Markdown summary
%
% This runner is intentionally non-invasive:
% it does not change any algorithm logic, only records the current baseline.

if nargin < 1 || isempty(opts)
    opts = struct();
end

startup('force', true);
local_add_ch5_paths(pwd);

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'baseline_freeze', ['single_case_' stamp]);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

disp(' ')
disp('=== [ch5r:Phase0-freeze] start ===')

out0 = run_ch5r_phase0_bootstrap_smoke();
out4 = run_ch5r_phase4_tracking_baseline();
out5 = run_ch5r_phase5_bubble_predictive();
out9 = run_ch5r_phase9_r9_closedloop();
out10 = run_ch5r_phase10_li_backend_closedloop(struct( ...
    'save_outputs', false, ...
    'log_enable', true));

baseline = struct();
baseline.created_at = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
baseline.project_root = pwd;

baseline.bootstrap = struct();
baseline.bootstrap.gamma_req = local_first_field(out0, { ...
    {'bootstrap','gamma_req'}, ...
    {'gamma_req'}, ...
    {'bundle','gamma_req'}}, NaN);

baseline.bootstrap.target_case = local_first_field(out0, { ...
    {'bootstrap','target_case','case_id'}, ...
    {'target_case','case_id'}, ...
    {'bundle','target_case','case_id'}}, '');

baseline.bootstrap.theta_star = local_first_field(out0, { ...
    {'bootstrap','theta_star'}, ...
    {'theta_star'}, ...
    {'bundle','theta_star'}}, struct());

baseline.bootstrap.theta_plus = local_first_field(out0, { ...
    {'bootstrap','theta_plus'}, ...
    {'theta_plus'}, ...
    {'bundle','theta_plus'}}, struct());

baseline.bootstrap.stage04_source = local_first_field(out0, { ...
    {'bootstrap','target_case','stage04_cache_file'}, ...
    {'target_case','stage04_cache_file'}, ...
    {'bundle','target_case','stage04_cache_file'}}, '');

baseline.bootstrap.stage05_source = local_first_field(out0, { ...
    {'bootstrap','target_case','stage05_cache_file'}, ...
    {'target_case','stage05_cache_file'}, ...
    {'bundle','target_case','stage05_cache_file'}}, '');

baseline.methods = [ ...
    local_extract_method_summary('R4', out4), ...
    local_extract_method_summary('R5', out5), ...
    local_extract_method_summary('R9', out9), ...
    local_extract_method_summary('R10', out10)];

mat_file = fullfile(out_dir, 'ch5_single_case_baseline.mat');
json_file = fullfile(out_dir, 'ch5_single_case_baseline.json');
md_file = fullfile(out_dir, 'ch5_single_case_baseline.md');

save(mat_file, 'baseline', 'out0', 'out4', 'out5', 'out9', 'out10');

json_text = jsonencode(baseline, PrettyPrint=true);
fid = fopen(json_file, 'w');
cleanup1 = onCleanup(@() fclose(fid));
fprintf(fid, '%s\n', json_text);
clear cleanup1

md_lines = local_build_md_lines(baseline);
fid = fopen(md_file, 'w');
cleanup2 = onCleanup(@() fclose(fid));
for i = 1:numel(md_lines)
    fprintf(fid, '%s\n', md_lines{i});
end
clear cleanup2

disp('=== [ch5r:Phase0-freeze] done ===')
disp(['out dir   : ' out_dir])
disp(['mat file  : ' mat_file])
disp(['json file : ' json_file])
disp(['md file   : ' md_file])

out = struct();
out.ok = true;
out.out_dir = out_dir;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'json_file', json_file, ...
    'md_file', md_file);
out.bootstrap = baseline.bootstrap;
out.methods = baseline.methods;
end

function s = local_extract_method_summary(tag, outx)
s = struct();
s.tag = tag;
s.case_id = local_get_field(outx, {'case','target_case','case_id'}, '');
s.window_mode = local_get_field(outx, {'case','window','mode'}, '');
s.window_length_s = local_get_field(outx, {'case','window','length_s'}, NaN);

s.valid_steps = local_get_field(outx, {'result','bubble_metrics','total_valid_steps'}, NaN);
s.valid_time_s = local_get_field(outx, {'result','bubble_metrics','total_valid_time_s'}, NaN);
s.bubble_steps = local_get_field(outx, {'result','bubble_metrics','bubble_steps'}, NaN);
s.bubble_time_s = local_get_field(outx, {'result','bubble_metrics','bubble_time_s'}, NaN);
s.bubble_fraction = local_get_field(outx, {'result','bubble_metrics','bubble_fraction'}, NaN);
s.longest_bubble_time_s = local_get_field(outx, {'result','bubble_metrics','longest_bubble_time_s'}, NaN);
s.max_bubble_depth = local_get_field(outx, {'result','bubble_metrics','max_bubble_depth'}, NaN);

s.switch_count = local_get_field(outx, {'result','cost_metrics','switch_count'}, NaN);
s.resource_score = local_get_field(outx, {'result','cost_metrics','resource_score'}, NaN);

s.mean_rmse_pos_km = NaN;
s.final_rmse_pos_km = NaN;
if strcmp(tag, 'R9')
    s.mean_rmse_pos_km = local_get_field(outx, {'result','r9_tracking','mean_rmse_pos_km'}, NaN);
    s.final_rmse_pos_km = local_get_field(outx, {'result','r9_tracking','final_rmse_pos_km'}, NaN);
elseif strcmp(tag, 'R10')
    s.mean_rmse_pos_km = local_get_field(outx, {'result','r10_tracking','mean_rmse_pos_km'}, NaN);
    s.final_rmse_pos_km = local_get_field(outx, {'result','r10_tracking','final_rmse_pos_km'}, NaN);
end

s.mat_file = local_get_field(outx, {'paths','mat_file'}, '');
end

function value = local_get_field(S, path_cells, default_value)
value = default_value;
try
    cur = S;
    for i = 1:numel(path_cells)
        key = path_cells{i};
        if isstruct(cur) && isfield(cur, key)
            cur = cur.(key);
        else
            return;
        end
    end
    value = cur;
catch
    value = default_value;
end
end

function value = local_first_field(S, candidate_paths, default_value)
value = default_value;
for i = 1:numel(candidate_paths)
    cur = local_get_field(S, candidate_paths{i}, default_value);
    if ischar(default_value) || isstring(default_value)
        if ~isempty(cur)
            value = cur;
            return;
        end
    elseif isstruct(default_value)
        if isstruct(cur) && ~isempty(fieldnames(cur))
            value = cur;
            return;
        end
    else
        if ~(isnumeric(cur) && isscalar(cur) && isnan(cur))
            value = cur;
            return;
        end
    end
end
end

function lines = local_build_md_lines(baseline)
lines = {};
lines{end+1} = '# Chapter 5 single-case baseline freeze';
lines{end+1} = '';
lines{end+1} = ['- created_at: `', baseline.created_at, '`'];
lines{end+1} = ['- project_root: `', baseline.project_root, '`'];
lines{end+1} = '';
lines{end+1} = '## Bootstrap';
lines{end+1} = ['- target_case: `', baseline.bootstrap.target_case, '`'];
lines{end+1} = ['- gamma_req: `', num2str(baseline.bootstrap.gamma_req, '%.15g'), '`'];
lines{end+1} = ['- stage04_source: `', baseline.bootstrap.stage04_source, '`'];
lines{end+1} = ['- stage05_source: `', baseline.bootstrap.stage05_source, '`'];
lines{end+1} = '';
lines{end+1} = '### theta_star';
lines{end+1} = local_theta_line(baseline.bootstrap.theta_star);
lines{end+1} = '### theta_plus';
lines{end+1} = local_theta_line(baseline.bootstrap.theta_plus);
lines{end+1} = '';
lines{end+1} = '## Methods';
lines{end+1} = '';

for i = 1:numel(baseline.methods)
    s = baseline.methods(i);
    lines{end+1} = ['### ', s.tag];
    lines{end+1} = ['- case_id: `', s.case_id, '`'];
    lines{end+1} = ['- window_mode: `', s.window_mode, '`'];
    lines{end+1} = ['- valid_steps: `', num2str(s.valid_steps), '`'];
    lines{end+1} = ['- bubble_steps: `', num2str(s.bubble_steps), '`'];
    lines{end+1} = ['- bubble_time_s: `', num2str(s.bubble_time_s, '%.15g'), '`'];
    lines{end+1} = ['- bubble_fraction: `', num2str(s.bubble_fraction, '%.15g'), '`'];
    lines{end+1} = ['- longest_bubble_time_s: `', num2str(s.longest_bubble_time_s, '%.15g'), '`'];
    lines{end+1} = ['- max_bubble_depth: `', num2str(s.max_bubble_depth, '%.15g'), '`'];
    lines{end+1} = ['- switch_count: `', num2str(s.switch_count), '`'];
    lines{end+1} = ['- resource_score: `', num2str(s.resource_score), '`'];
    if isfinite(s.mean_rmse_pos_km)
        lines{end+1} = ['- mean_rmse_pos_km: `', num2str(s.mean_rmse_pos_km, '%.15g'), '`'];
    end
    if isfinite(s.final_rmse_pos_km)
        lines{end+1} = ['- final_rmse_pos_km: `', num2str(s.final_rmse_pos_km, '%.15g'), '`'];
    end
    lines{end+1} = ['- mat_file: `', s.mat_file, '`'];
    lines{end+1} = '';
end
end

function line = local_theta_line(theta)
if ~isstruct(theta) || isempty(fieldnames(theta))
    line = '- `(empty)`';
    return;
end

line = ['- `h=', num2str(local_get_field(theta, {'h_km'}, NaN)), ...
    ', i=', num2str(local_get_field(theta, {'i_deg'}, NaN)), ...
    ', P=', num2str(local_get_field(theta, {'P'}, NaN)), ...
    ', T=', num2str(local_get_field(theta, {'T'}, NaN)), ...
    ', F=', num2str(local_get_field(theta, {'F'}, NaN)), ...
    ', Ns=', num2str(local_get_field(theta, {'Ns'}, NaN)), ...
    ', DG=', num2str(local_get_field(theta, {'DG'}, NaN), '%.15g'), ...
    ', pass_ratio=', num2str(local_get_field(theta, {'pass_ratio'}, NaN), '%.15g'), '`'];
end

function local_add_ch5_paths(project_root)
addpath(fullfile(project_root, 'ch5_rebuild'));
addpath(fullfile(project_root, 'ch5_rebuild', 'params'));
addpath(fullfile(project_root, 'ch5_rebuild', 'bootstrap'));
addpath(fullfile(project_root, 'ch5_rebuild', 'scenario'));
addpath(fullfile(project_root, 'ch5_rebuild', 'allocator'));
addpath(fullfile(project_root, 'ch5_rebuild', 'outer_loop'));
addpath(fullfile(project_root, 'ch5_rebuild', 'policies'));
addpath(fullfile(project_root, 'ch5_rebuild', 'analysis'));
addpath(fullfile(project_root, 'ch5_rebuild', 'state'));
addpath(fullfile(project_root, 'ch5_rebuild', 'metrics'));
addpath(fullfile(project_root, 'ch5_rebuild', 'sensing'));
addpath(fullfile(project_root, 'ch5_rebuild', 'plots'));
addpath(fullfile(project_root, 'ch5_rebuild', 'runners'));
addpath(fullfile(project_root, 'ch5_rebuild', 'r9_inner'));
addpath(fullfile(project_root, 'ch5_rebuild', 'r9_sched'));
addpath(fullfile(project_root, 'ch5_rebuild', 'r10_li'));
end
