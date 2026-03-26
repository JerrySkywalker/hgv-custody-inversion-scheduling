function spec = make_stage05_opend_legacy_reproduction_spec(varargin)
%MAKE_STAGE05_OPEND_LEGACY_REPRODUCTION_SPEC Build framework spec to reproduce legacy Stage05 OpenD products.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_legacy_reproduction'), @(x) ischar(x) || isstring(x));
addParameter(p, 'output_suffix', 'legacy_repro', @(x) ischar(x) || isstring(x));
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

rows = local_make_fullgrid_rows(args.h_fixed_km, args.i_grid_deg, args.P_grid, args.T_grid, args.F_fixed);

artifact_root = char(string(args.artifact_root));
figures_dir = fullfile(artifact_root, 'figures');
suffix = char(string(args.output_suffix));
suffix_part = '';
if ~isempty(suffix)
    suffix_part = ['_' suffix];
end

cfg_base = default_params();
cfg_base = stage09_prepare_cfg(cfg_base);
cfg_base = configure_stage_output_paths(cfg_base);
cfg_overlay = config_service(profile);

spec = struct();
spec.cfg_base = cfg_base;
spec.cfg_overlay = cfg_overlay;
spec.design_grid = rows;
spec.task_family_builder = @(cfg, spec_) task_family_service(cfg);
spec.evaluator_mode = 'opend';
spec.artifact_root = artifact_root;

search_spec = struct();
search_spec.gamma_eff_scalar = profile.gamma_eff_scalar;
search_spec.run_tag = ['stage05_opend_legacy_reproduction' suffix_part];
search_spec.save_cache = logical(args.save_cache);
search_spec.use_parallel = logical(args.use_parallel);
search_spec.show_progress = logical(args.show_progress);
search_spec.logger = struct('enable_console', true, 'console_level', 'INFO', 'enable_file', false);
spec.search_spec = search_spec;

req1 = struct(); req1.type = 'truth_table'; req1.name = 'truth_table';

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

pr1 = struct();
pr1.type = 'envelope_curve';
pr1.name = 'best_pass_by_Ns_plot';
pr1.source = 'best_pass_by_Ns';
pr1.x_field = 'Ns';
pr1.y_field = 'pass_ratio';
pr1.plot_spec = struct( ...
    'title', 'Stage05 OpenD legacy reproduction: best pass ratio by Ns', ...
    'x_label', 'Ns', ...
    'y_label', 'best pass ratio', ...
    'visible', char(string(args.plot_visible)));
pr1.save_spec = struct( ...
    'output_dir', figures_dir, ...
    'file_name', ['stage05_opend_legacy_best_pass_by_Ns' suffix_part '.png']);

pr2 = struct();
pr2.type = 'heatmap_matrix';
pr2.name = 'geometry_heatmap_i60_plot';
pr2.source = 'geometry_heatmap_i60';
pr2.plot_spec = struct( ...
    'title', 'Stage05 OpenD legacy reproduction: DG heatmap at i=60', ...
    'x_label', 'T', ...
    'y_label', 'P', ...
    'visible', char(string(args.plot_visible)));
pr2.save_spec = struct( ...
    'output_dir', figures_dir, ...
    'file_name', ['stage05_opend_legacy_geometry_heatmap_i60' suffix_part '.png']);

spec.plot_requests = {pr1, pr2};

spec.table_export = struct();
spec.table_export.artifact_root = artifact_root;
spec.table_export.table_names = {'truth_table','best_pass_by_Ns'};
end

function rows = local_make_fullgrid_rows(h_fixed_km, i_grid_deg, P_grid, T_grid, F_fixed)
rows_cell = {};
idx = 0;
for ii = 1:numel(i_grid_deg)
    for ip = 1:numel(P_grid)
        for it = 1:numel(T_grid)
            idx = idx + 1;
            row = struct();
            row.design_id = sprintf('LEG_i%02d_P%d_T%d', round(i_grid_deg(ii)), P_grid(ip), T_grid(it));
            row.h_km = h_fixed_km;
            row.i_deg = i_grid_deg(ii);
            row.P = P_grid(ip);
            row.T = T_grid(it);
            row.F = F_fixed;
            row.Ns = row.P * row.T;
            rows_cell{idx,1} = row;
        end
    end
end
rows = vertcat(rows_cell{:});
end
