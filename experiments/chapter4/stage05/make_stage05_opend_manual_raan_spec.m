function spec = make_stage05_opend_manual_raan_spec(varargin)
%MAKE_STAGE05_OPEND_MANUAL_RAAN_SPEC Build a Stage05/OpenD manual-RAAN experiment spec.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'base_rows', [], @(x) isstruct(x) || istable(x) || isempty(x));
addParameter(p, 'raan_range_deg', [0 20], @(x) isnumeric(x) && numel(x)==2);
addParameter(p, 'raan_step_deg', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'output_dir', fullfile('outputs','framework','plots'), @(x) ischar(x) || isstring(x));
addParameter(p, 'output_suffix', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
args = p.Results;

if isempty(args.profile)
    profile = make_profile_MB_nominal_validation_stage05();
else
    profile = args.profile;
end

cfg_base = default_params();
cfg_base = stage09_prepare_cfg(cfg_base);
cfg_base = configure_stage_output_paths(cfg_base);

cfg_overlay = config_service(profile);

if isempty(args.base_rows)
    base_rows = manual_make_stage05_representative_grid();
else
    base_rows = args.base_rows;
end

suffix = char(string(args.output_suffix));
suffix_part = '';
if ~isempty(suffix)
    suffix_part = ['_' suffix];
end

spec = struct();
spec.cfg_base = cfg_base;
spec.cfg_overlay = cfg_overlay;
spec.design_grid = base_rows;
spec.task_family_builder = @(cfg, spec_) task_family_service(cfg);
spec.evaluator_mode = 'opend';

spec.region_phase = struct();
spec.region_phase.enable = true;
spec.region_phase.mode = 'manual';
spec.region_phase.parameter = 'raan_deg';
spec.region_phase.range_deg = args.raan_range_deg;
spec.region_phase.step_deg = args.raan_step_deg;
spec.region_phase.output_mode = 'expand_rows';

search_spec = struct();
search_spec.gamma_eff_scalar = profile.gamma_eff_scalar;
search_spec.run_tag = ['stage05_opend_manual_raan' suffix_part];
search_spec.save_cache = logical(args.save_cache);
search_spec.use_parallel = logical(args.use_parallel);
search_spec.show_progress = logical(args.show_progress);
search_spec.logger = struct( ...
    'enable_console', true, ...
    'console_level', 'INFO', ...
    'enable_file', false);
spec.search_spec = search_spec;

req1 = struct(); req1.type = 'truth_table'; req1.name = 'truth_table';

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
req4.name = 'env_mean_DG';
req4.group_key = 'Ns';
req4.metric_name = 'DG_rob';
req4.fixed_filters = struct();
req4.scenario_metric = 'DG_rob';
req4.scenario_mode = 'mean';

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
req6.name = 'hm_mean_DG';
req6.metric_name = 'DG_rob';
req6.fixed_filters = struct();
req6.row_key = 'P';
req6.col_key = 'T';
req6.scenario_metric = 'DG_rob';
req6.scenario_mode = 'mean';

req7 = struct();
req7.type = 'raan_aware_envelope';
req7.name = 'env_min_pass_ratio';
req7.group_key = 'Ns';
req7.metric_name = 'pass_ratio';
req7.fixed_filters = struct();
req7.scenario_metric = 'pass_ratio';
req7.scenario_mode = 'min';

req8 = struct();
req8.type = 'raan_aware_envelope';
req8.name = 'env_mean_pass_ratio';
req8.group_key = 'Ns';
req8.metric_name = 'pass_ratio';
req8.fixed_filters = struct();
req8.scenario_metric = 'pass_ratio';
req8.scenario_mode = 'mean';

req9 = struct();
req9.type = 'raan_aware_heatmap_slice';
req9.name = 'hm_min_pass_ratio';
req9.metric_name = 'pass_ratio';
req9.fixed_filters = struct();
req9.row_key = 'P';
req9.col_key = 'T';
req9.scenario_metric = 'pass_ratio';
req9.scenario_mode = 'min';

req10 = struct();
req10.type = 'raan_aware_heatmap_slice';
req10.name = 'hm_mean_pass_ratio';
req10.metric_name = 'pass_ratio';
req10.fixed_filters = struct();
req10.row_key = 'P';
req10.col_key = 'T';
req10.scenario_metric = 'pass_ratio';
req10.scenario_mode = 'mean';

spec.output_requests = {req1, req2, req3, req4, req5, req6, req7, req8, req9, req10};

pr1 = struct();
pr1.type = 'envelope_curve'; pr1.name = 'env_min_DG_plot'; pr1.source = 'env_min_DG';
pr1.x_field = 'Ns'; pr1.y_field = 'DG_rob';
pr1.plot_spec = struct('title','Stage05 OpenD manual-RAAN min DG envelope','x_label','Ns','y_label','min DG over RAAN','visible',char(string(args.plot_visible)));
pr1.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_env_min_DG' suffix_part '.png']);

pr2 = struct();
pr2.type = 'envelope_curve'; pr2.name = 'env_mean_DG_plot'; pr2.source = 'env_mean_DG';
pr2.x_field = 'Ns'; pr2.y_field = 'DG_rob';
pr2.plot_spec = struct('title','Stage05 OpenD manual-RAAN mean DG envelope','x_label','Ns','y_label','mean DG over RAAN','visible',char(string(args.plot_visible)));
pr2.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_env_mean_DG' suffix_part '.png']);

pr3 = struct();
pr3.type = 'heatmap_matrix'; pr3.name = 'hm_min_DG_plot'; pr3.source = 'hm_min_DG';
pr3.plot_spec = struct('title','Stage05 OpenD manual-RAAN min DG heatmap','x_label','T','y_label','P','visible',char(string(args.plot_visible)));
pr3.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_hm_min_DG' suffix_part '.png']);

pr4 = struct();
pr4.type = 'heatmap_matrix'; pr4.name = 'hm_mean_DG_plot'; pr4.source = 'hm_mean_DG';
pr4.plot_spec = struct('title','Stage05 OpenD manual-RAAN mean DG heatmap','x_label','T','y_label','P','visible',char(string(args.plot_visible)));
pr4.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_hm_mean_DG' suffix_part '.png']);

pr5 = struct();
pr5.type = 'envelope_curve'; pr5.name = 'env_min_pass_ratio_plot'; pr5.source = 'env_min_pass_ratio';
pr5.x_field = 'Ns'; pr5.y_field = 'pass_ratio';
pr5.plot_spec = struct('title','Stage05 OpenD manual-RAAN min pass-ratio envelope','x_label','Ns','y_label','min pass ratio over RAAN','visible',char(string(args.plot_visible)));
pr5.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_env_min_pass_ratio' suffix_part '.png']);

pr6 = struct();
pr6.type = 'envelope_curve'; pr6.name = 'env_mean_pass_ratio_plot'; pr6.source = 'env_mean_pass_ratio';
pr6.x_field = 'Ns'; pr6.y_field = 'pass_ratio';
pr6.plot_spec = struct('title','Stage05 OpenD manual-RAAN mean pass-ratio envelope','x_label','Ns','y_label','mean pass ratio over RAAN','visible',char(string(args.plot_visible)));
pr6.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_env_mean_pass_ratio' suffix_part '.png']);

pr7 = struct();
pr7.type = 'heatmap_matrix'; pr7.name = 'hm_min_pass_ratio_plot'; pr7.source = 'hm_min_pass_ratio';
pr7.plot_spec = struct('title','Stage05 OpenD manual-RAAN min pass-ratio heatmap','x_label','T','y_label','P','visible',char(string(args.plot_visible)));
pr7.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_hm_min_pass_ratio' suffix_part '.png']);

pr8 = struct();
pr8.type = 'heatmap_matrix'; pr8.name = 'hm_mean_pass_ratio_plot'; pr8.source = 'hm_mean_pass_ratio';
pr8.plot_spec = struct('title','Stage05 OpenD manual-RAAN mean pass-ratio heatmap','x_label','T','y_label','P','visible',char(string(args.plot_visible)));
pr8.save_spec = struct('output_dir',char(string(args.output_dir)),'file_name',['stage05_opend_manual_raan_hm_mean_pass_ratio' suffix_part '.png']);

spec.plot_requests = {pr1, pr2, pr3, pr4, pr5, pr6, pr7, pr8};
end
