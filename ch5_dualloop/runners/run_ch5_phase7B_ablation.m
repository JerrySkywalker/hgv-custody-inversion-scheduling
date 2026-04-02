function out = run_ch5_phase7B_ablation(cfg, verbose)
%RUN_CH5_PHASE7B_ABLATION
% NX-1 first round
% Formal ablation runner for:
%   - C-baseline
%   - CK-full
%   - CK-noGeom
%   - CK-noStateMachine
%
% Notes:
%   This runner assumes run_ch5_phase7A_dualloop_ck(cfg, verbose)
%   is the stable baseline entry.
%
%   The ablation flags are written into cfg.ch5 using multiple
%   alias names on purpose, so later core-side consumption can be
%   added with minimal changes.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('ref128');
end
if nargin < 2
    verbose = true;
end

if ischar(cfg) || isstring(cfg)
    cfg = default_ch5_params(char(cfg));
end

cfg = local_apply_common_defaults(cfg);
scene_preset = cfg.ch5.scene_preset;

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7b_ablation');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
log_dir = fullfile(out_root, 'logs');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

% ------------------------------------------------
% A) Run baseline once and reuse C / CK-full from it
% ------------------------------------------------
cfg_full = cfg;
cfg_full = local_apply_ablation_mode(cfg_full, 'full');

out_full = run_ch5_phase7A_dualloop_ck(cfg_full, true);
S_full = load(out_full.mat_file);

% ------------------------------------------------
% B) CK-noGeom
% ------------------------------------------------
cfg_ng = cfg;
cfg_ng = local_apply_ablation_mode(cfg_ng, 'no_geometry');

out_ng = run_ch5_phase7A_dualloop_ck(cfg_ng, true);
S_ng = load(out_ng.mat_file);

% ------------------------------------------------
% C) CK-noStateMachine
% ------------------------------------------------
cfg_ns = cfg;
cfg_ns = local_apply_ablation_mode(cfg_ns, 'no_state_machine');

out_ns = run_ch5_phase7A_dualloop_ck(cfg_ns, true);
S_ns = load(out_ns.mat_file);

methods = struct([]);

methods(1) = local_extract_metrics(S_full, 'C-baseline', 'trackingC',  'trackingStatsC',  'custodyC');
methods(2) = local_extract_metrics(S_full, 'CK-full',    'trackingCK', 'trackingStatsCK', 'custodyCK');
methods(3) = local_extract_metrics(S_ng,   'CK-noGeom',  'trackingCK', 'trackingStatsCK', 'custodyCK');
methods(4) = local_extract_metrics(S_ns,   'CK-noStateMachine', 'trackingCK', 'trackingStatsCK', 'custodyCK');

fig_path = fullfile(fig_dir, ['phase7b_ablation_', scene_preset, '.png']);
plot_ck_ablation_summary(methods, scene_preset, fig_path);

txt_path = fullfile(tbl_dir, ['phase7b_ablation_', scene_preset, '.txt']);
local_write_summary(txt_path, scene_preset, methods);

log_path = fullfile(log_dir, ['phase7b_ablation_log_', scene_preset, '.txt']);
local_write_log(log_path, scene_preset, methods, cfg_full, cfg_ng, cfg_ns);

mat_path = fullfile(mat_dir, ['phase7b_ablation_', scene_preset, '.mat']);
save(mat_path, 'scene_preset', 'methods', 'cfg_full', 'cfg_ng', 'cfg_ns', ...
    'out_full', 'out_ng', 'out_ns');

if verbose
    disp('=== Chapter 5 Phase 7B Ablation Summary ===')
    disp(['scene_preset = ', scene_preset])
    disp(struct2table(methods))
    disp(['[phase7b] fig  : ', fig_path])
    disp(['[phase7b] text : ', txt_path])
    disp(['[phase7b] log  : ', log_path])
    disp(['[phase7b] mat  : ', mat_path])
end

out = struct();
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function cfg = local_apply_common_defaults(cfg)
if ~isfield(cfg, 'ch5') || isempty(cfg.ch5)
    cfg.ch5 = struct();
end

% Keep baseline behavior stable if the field is missing.
if ~isfield(cfg.ch5, 'ck_safe_dual_weight') || isempty(cfg.ch5.ck_safe_dual_weight)
    cfg.ch5.ck_safe_dual_weight = 0.0;
end

if ~isfield(cfg.ch5, 'ck_safe_fallback_to_C') || isempty(cfg.ch5.ck_safe_fallback_to_C)
    cfg.ch5.ck_safe_fallback_to_C = false;
end

if ~isfield(cfg.ch5, 'ablation_mode') || isempty(cfg.ch5.ablation_mode)
    cfg.ch5.ablation_mode = 'full';
end
end

function cfg = local_apply_ablation_mode(cfg, mode_name)
cfg = local_apply_common_defaults(cfg);
cfg.ch5.ablation_mode = mode_name;

% Reset all toggles first
cfg.ch5.ablation_disable_geometry = false;
cfg.ch5.ablation_disable_state_machine = false;

cfg.ch5.disable_geometry_term = false;
cfg.ch5.disable_ck_geometry = false;
cfg.ch5.ck_disable_geometry = false;

cfg.ch5.disable_state_machine = false;
cfg.ch5.disable_mode_switching = false;
cfg.ch5.ck_disable_state_machine = false;
cfg.ch5.ck_disable_warn_trigger = false;
cfg.ch5.ck_disable_guard_switching = false;

switch lower(mode_name)
    case 'full'
        % nothing more
    case 'no_geometry'
        cfg.ch5.ablation_disable_geometry = true;
        cfg.ch5.disable_geometry_term = true;
        cfg.ch5.disable_ck_geometry = true;
        cfg.ch5.ck_disable_geometry = true;

    case 'no_state_machine'
        cfg.ch5.ablation_disable_state_machine = true;
        cfg.ch5.disable_state_machine = true;
        cfg.ch5.disable_mode_switching = true;
        cfg.ch5.ck_disable_state_machine = true;
        cfg.ch5.ck_disable_warn_trigger = true;
        cfg.ch5.ck_disable_guard_switching = true;

    otherwise
        error('Unsupported ablation mode: %s', mode_name);
end
end

function rec = local_extract_metrics(S, method_name, tracking_field, tracking_stats_field, custody_field)
rec = struct();
rec.name = method_name;

custody = S.(custody_field);
stats = S.(tracking_stats_field);

if isfield(custody, 'q_worst_window')
    rec.q_worst_window = custody.q_worst_window;
else
    rec.q_worst_window = custody.q_worst;
end

rec.phi_mean = custody.phi_mean;
rec.outage_ratio = custody.outage_ratio;
rec.longest_outage_steps = custody.longest_outage_steps;

if isfield(stats, 'mean_rmse')
    rec.mean_rmse = stats.mean_rmse;
else
    rec.mean_rmse = NaN;
end

if isfield(stats, 'max_rmse')
    rec.max_rmse = stats.max_rmse;
else
    rec.max_rmse = NaN;
end

rec.switch_count = local_count_switches(S, tracking_field);
end

function n = local_count_switches(S, field_name)
n = NaN;
if isfield(S, field_name)
    T = S.(field_name);
    if isstruct(T) && isfield(T, 'selected_sets')
        ss = T.selected_sets;
        c = 0;
        for i = 2:numel(ss)
            c = c + ~isequal(ss{i-1}, ss{i});
        end
        n = c;
    end
end
end

function local_write_summary(pathStr, scene_preset, methods)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Chapter 5 Phase 7B Ablation Summary ===\n');
fprintf(fid, 'scene_preset = %s\n\n', scene_preset);

for i = 1:numel(methods)
    m = methods(i);
    fprintf(fid, '--- %s ---\n', m.name);
    fprintf(fid, 'q_worst_window = %.6f\n', m.q_worst_window);
    fprintf(fid, 'phi_mean = %.6f\n', m.phi_mean);
    fprintf(fid, 'outage_ratio = %.6f\n', m.outage_ratio);
    fprintf(fid, 'longest_outage_steps = %d\n', m.longest_outage_steps);
    fprintf(fid, 'mean_rmse = %.6f\n', m.mean_rmse);
    fprintf(fid, 'max_rmse = %.6f\n', m.max_rmse);
    fprintf(fid, 'switch_count = %.6f\n\n', m.switch_count);
end
end

function local_write_log(pathStr, scene_preset, methods, cfg_full, cfg_ng, cfg_ns)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open log file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '[INFO] phase7b ablation\n');
fprintf(fid, '[INFO] scene_preset = %s\n', scene_preset);
fprintf(fid, '[INFO] full ablation_mode = %s\n', cfg_full.ch5.ablation_mode);
fprintf(fid, '[INFO] no-geometry ablation_mode = %s\n', cfg_ng.ch5.ablation_mode);
fprintf(fid, '[INFO] no-state-machine ablation_mode = %s\n', cfg_ns.ch5.ablation_mode);

for i = 1:numel(methods)
    fprintf(fid, '[INFO] %s q_worst_window = %.6f\n', methods(i).name, methods(i).q_worst_window);
end
end
