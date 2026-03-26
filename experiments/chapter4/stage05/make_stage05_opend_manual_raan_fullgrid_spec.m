function spec = make_stage05_opend_manual_raan_fullgrid_spec(varargin)
%MAKE_STAGE05_OPEND_MANUAL_RAAN_FULLGRID_SPEC Build Stage05 OpenD manual-RAAN full-grid spec.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'raan_range_deg', [0 20], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'raan_step_deg', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_manual_raan'), @(x) ischar(x) || isstring(x));
addParameter(p, 'output_suffix', 'formal', @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'parallel_monitor', struct(), @(x) isstruct(x) || isempty(x));
addParameter(p, 'min_parallel_rows', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
parse(p, varargin{:});
args = p.Results;

profile = args.profile;
if isempty(profile)
    profile = make_profile_MB_nominal_validation_stage05();
end

cfg_base = default_params();
cfg_base = stage09_prepare_cfg(cfg_base);
cfg_base = configure_stage_output_paths(cfg_base);

cfg_overlay = config_service(profile);

spec = struct();
spec.cfg_base = cfg_base;
spec.cfg_overlay = cfg_overlay;
spec.evaluator_mode = 'opend';
spec.design_grid = manual_make_stage05_fullgrid( ...
    'i_grid_deg', args.i_grid_deg, ...
    'P_grid', args.P_grid, ...
    'T_grid', args.T_grid, ...
    'h_fixed_km', args.h_fixed_km, ...
    'F_fixed', args.F_fixed);

spec.task_family_builder = @(cfg, spec_in) task_family_service(cfg);

spec.region_phase = struct();
spec.region_phase.enable = true;
spec.region_phase.mode = 'manual';
spec.region_phase.parameter = 'raan_deg';
spec.region_phase.range_deg = args.raan_range_deg;
spec.region_phase.step_deg = args.raan_step_deg;
spec.region_phase.output_mode = 'expand_rows';

search_spec = struct();
search_spec.gamma_eff_scalar = profile.gamma_eff_scalar;
search_spec.run_tag = char(string(args.output_suffix));
search_spec.save_cache = logical(args.save_cache);
search_spec.use_parallel = logical(args.use_parallel);
search_spec.show_progress = logical(args.show_progress);
search_spec.parallel_monitor = args.parallel_monitor;
if ~isempty(args.min_parallel_rows)
    search_spec.min_parallel_rows = args.min_parallel_rows;
end
search_spec.logger = struct( ...
    'enable_console', true, ...
    'console_level', 'INFO', ...
    'enable_file', false);

spec.search_spec = search_spec;

req1 = struct();
req1.type = 'truth_table';
req1.name = 'truth_table';

req2 = struct();
req2.type = 'scenario_aggregate';
req2.name = 'agg_by_base_design';
req2.group_keys = {'base_design_id','P','T','Ns'};
req2.metric_names = {'DG_rob','pass_ratio'};
req2.aggregate_modes = {'min','max','mean'};

req3 = struct();
req3.type = 'raan_aware_envelope';
req3.name = 'env_min_DG';
req3.group_key = 'Ns';
req3.metric_name = 'DG_rob';
req3.fixed_filters = struct();
req3.scenario_metric = 'DG_rob';
req3.scenario_mode = 'min';

req4 = struct();
req4.type = 'raan_aware_envelope';
req4.name = 'env_min_pass_ratio';
req4.group_key = 'Ns';
req4.metric_name = 'pass_ratio';
req4.fixed_filters = struct();
req4.scenario_metric = 'pass_ratio';
req4.scenario_mode = 'min';

req5 = struct();
req5.type = 'raan_aware_heatmap_slice';
req5.name = 'hm_min_DG';
req5.metric_name = 'DG_rob';
req5.fixed_filters = struct();
req5.row_key = 'P';
req5.col_key = 'T';
req5.scenario_metric = 'DG_rob';
req5.scenario_mode = 'min';

req6 = struct();
req6.type = 'raan_aware_heatmap_slice';
req6.name = 'hm_min_pass_ratio';
req6.metric_name = 'pass_ratio';
req6.fixed_filters = struct();
req6.row_key = 'P';
req6.col_key = 'T';
req6.scenario_metric = 'pass_ratio';
req6.scenario_mode = 'min';

spec.output_requests = {req1, req2, req3, req4, req5, req6};
end
