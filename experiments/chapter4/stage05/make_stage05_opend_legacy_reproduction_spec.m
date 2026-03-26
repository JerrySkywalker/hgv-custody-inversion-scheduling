function spec = make_stage05_opend_legacy_reproduction_spec(varargin)
%MAKE_STAGE05_OPEND_LEGACY_REPRODUCTION_SPEC Build Stage05 OpenD legacy-reproduction spec.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_legacy_reproduction'), @(x) ischar(x) || isstring(x));
addParameter(p, 'output_suffix', 'formal', @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'parallel_monitor', struct(), @(x) isstruct(x) || isempty(x));
parse(p, varargin{:});
args = p.Results;

cfg_base = default_params();
cfg_base = stage09_prepare_cfg(cfg_base);
cfg_base = configure_stage_output_paths(cfg_base);

cfg_overlay = struct();
if ~isempty(args.profile)
    cfg_overlay = config_service(args.profile);
    cfg_overlay.profile = args.profile;
else
    cfg_overlay.profile = struct();
end

% Ensure legacy task-family path sees expected engine config fields.
cfg_overlay.engine_cfg = cfg_base;

spec = struct();
spec.cfg_base = cfg_base;
spec.cfg_overlay = cfg_overlay;
spec.evaluator_mode = 'opend';
spec.design_grid_builder = @(cfg, spec_in) local_build_design_grid(args);
spec.task_family_builder = @(cfg, spec_in) task_family_service(cfg);

search_spec = struct();
if ~isempty(args.profile) && isfield(args.profile, 'gamma_eff_scalar')
    search_spec.gamma_eff_scalar = args.profile.gamma_eff_scalar;
end
search_spec.run_tag = char(string(args.output_suffix));
search_spec.save_cache = logical(args.save_cache);
search_spec.use_parallel = logical(args.use_parallel);
search_spec.show_progress = logical(args.show_progress);
search_spec.parallel_monitor = args.parallel_monitor;

search_spec.logger = struct( ...
    'enable_console', true, ...
    'console_level', 'INFO', ...
    'enable_file', false);

spec.search_spec = search_spec;

req1 = struct();
req1.type = 'truth_table';
req1.name = 'truth_table';

req2 = struct();
req2.type = 'best_envelope';
req2.name = 'best_pass_by_Ns';
req2.group_key = 'Ns';
req2.metric_name = 'pass_ratio';
req2.fixed_filters = struct();
req2.aggregate_mode = 'max';

req3 = struct();
req3.type = 'heatmap_slice';
req3.name = 'geometry_heatmap_i60';
req3.metric_name = 'DG_rob';
req3.fixed_filters = struct('i_deg', 60);
req3.row_key = 'P';
req3.col_key = 'T';

spec.output_requests = {req1, req2, req3};

spec.table_export = struct();
spec.table_export.enable = true;
spec.table_export.output_dir = fullfile(char(string(args.artifact_root)), 'tables');

spec.plot_export = struct();
spec.plot_export.enable = true;
spec.plot_export.output_dir = fullfile(char(string(args.artifact_root)), 'figures');
spec.plot_export.plot_visible = char(string(args.plot_visible));
end

function rows = local_build_design_grid(args)
rows = manual_make_stage05_fullgrid( ...
    'i_grid_deg', args.i_grid_deg, ...
    'P_grid', args.P_grid, ...
    'T_grid', args.T_grid, ...
    'h_fixed_km', args.h_fixed_km, ...
    'F_fixed', args.F_fixed);
end
