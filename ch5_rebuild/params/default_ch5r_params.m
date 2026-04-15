function cfg = default_ch5r_params(do_bootstrap)
%DEFAULT_CH5R_PARAMS  Chapter 5 rebuild default parameters.

if nargin < 1
    do_bootstrap = false;
end

if exist('default_params', 'file') ~= 2
    error('default_params.m is not on path. Please run startup first.');
end

cfg = default_params();

root_dir = fileparts(fileparts(mfilename('fullpath')));
legacy_root = fullfile(root_dir, '..', 'ch5_dualloop');

cfg.ch5r = struct();
cfg.ch5r.phase_name = 'R0';
cfg.ch5r.root_dir = root_dir;
cfg.ch5r.output_root = fullfile(cfg.paths.outputs, 'ch5_rebuild');

cfg.ch5r.output_dirs = struct();
cfg.ch5r.output_dirs.phaseR0 = fullfile(cfg.ch5r.output_root, 'phaseR0');
cfg.ch5r.output_dirs.phaseR3 = fullfile(cfg.ch5r.output_root, 'phaseR3_static_hold');
cfg.ch5r.output_dirs.phaseR4 = fullfile(cfg.ch5r.output_root, 'phaseR4_tracking_baseline');

cfg.ch5r.legacy = struct();
cfg.ch5r.legacy.mode = 'frozen_in_place';
cfg.ch5r.legacy.root = legacy_root;
cfg.ch5r.legacy.exists = exist(legacy_root, 'dir') == 7;

cfg.ch5r.bootstrap = struct();
cfg.ch5r.bootstrap.stage04_patterns = { ...
    'stage04_window_worstcase_*.mat', ...
    'stage04_*worstcase*.mat', ...
    'stage04_*.mat'};
cfg.ch5r.bootstrap.stage05_patterns = { ...
    'stage05_nominal_walker_search_*.mat', ...
    'stage05_*search*.mat', ...
    'stage05_plot_nominal_results_*.mat', ...
    'stage05_*plot*.mat', ...
    'stage05_*.mat'};

cfg.ch5r.bootstrap.default_case_id = 'N01';
cfg.ch5r.bootstrap.force_case_id = 'N01';
cfg.ch5r.bootstrap.strict_single_case = true;

cfg.ch5r.bootstrap.selection_rule = 'min_Ns_then_max_DG_then_max_passratio';
cfg.ch5r.bootstrap.plus_mode = 'next_redundant_solution';

cfg.ch5r.bootstrap.require_stage04_cache = true;
cfg.ch5r.bootstrap.require_stage05_cache = true;
cfg.ch5r.bootstrap.require_stage05_feasible_table = true;
cfg.ch5r.bootstrap.allow_stage05_fallback_to_defaults = false;
cfg.ch5r.bootstrap.forbid_theta_plus_equal_theta_star = true;

cfg.ch5r.bootstrap.require_matching_cache_timestamps = true;
cfg.ch5r.bootstrap.cache_timestamp_tolerance_seconds = 300;
cfg.ch5r.bootstrap.write_outputs = true;

cfg.ch5r.sensor_profile = struct();
cfg.ch5r.sensor_profile.name = 'baseline_from_stage04_defaults';
cfg.ch5r.sensor_profile.sigma_angle_deg = cfg.stage04.sigma_angle_deg;
cfg.ch5r.sensor_profile.sigma_angle_rad = cfg.stage04.sigma_angle_rad;
cfg.ch5r.sensor_profile.max_range_km = cfg.stage03.max_range_km;
cfg.ch5r.sensor_profile.fov_deg = 5;
cfg.ch5r.sensor_profile.off_nadir_deg = 50;

cfg.ch5r.target_case = struct();
cfg.ch5r.target_case.family = 'nominal';
cfg.ch5r.target_case.case_id = cfg.ch5r.bootstrap.force_case_id;
cfg.ch5r.target_case.source = 'cfg.ch5r.bootstrap.force_case_id';

cfg.ch5r.gamma_req = max(cfg.stage04.gamma_floor, cfg.stage04.gamma_req_fixed);

cfg.ch5r.window_length_s = 60;
cfg.ch5r.window_mode = 'centered_full_only';
cfg.ch5r.window_exclude_incomplete_edges = true;

cfg.ch5r.r4 = default_ch5r_r4_params();

cfg.ch5r.bootstrap_result = struct();
cfg.ch5r.bootstrap_result.available = false;

if do_bootstrap
    bundle = bootstrap_ch5r_from_stage04_stage05(cfg);
    cfg = build_ch5r_params_from_bootstrap(cfg, bundle);
end
rt = load_ch5r_runtime_override();
if ~isempty(rt) && isstruct(rt) && isfield(rt, 'enabled') && logical(rt.enabled)
    if isfield(rt, 'case_id') && ~isempty(rt.case_id)
        cfg = apply_ch5r_case_override(cfg, rt.case_id);
    end
    if ~isfield(cfg.ch5r, 'runtime') || ~isstruct(cfg.ch5r.runtime)
        cfg.ch5r.runtime = struct();
    end
    cfg.ch5r.runtime = rt;
end
end

