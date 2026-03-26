function products = run_stage05_scan_products(varargin)
p = inputParser;
addParameter(p, 'preset', 'legacy_stage05_strict', @(x) ischar(x) || isstring(x));
addParameter(p, 'profile', [], @(x) isempty(x) || isstruct(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_scan_products'), @(x) ischar(x) || isstring(x));
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'raw_result', struct(), @(x) isstruct(x) || isempty(x));
parse(p, varargin{:});
args = p.Results;

preset = char(string(args.preset));
if ~strcmpi(preset, 'legacy_stage05_strict')
    error('run_stage05_scan_products:UnsupportedPreset', ...
        'Only preset legacy_stage05_strict is supported in this step.');
end

if isempty(args.profile)
    profile = make_profile_stage05_nominal_plot_strict();
else
    profile = args.profile;
end

if ~isempty(args.raw_result) && isstruct(args.raw_result) ...
        && isfield(args.raw_result, 'grid_table')
    raw = args.raw_result;
else
    raw = run_stage05_opend_legacy_reproduction_framework( ...
        'profile', profile, ...
        'i_grid_deg', [30 40 50 60 70 80 90], ...
        'P_grid', [4 6 8 10 12], ...
        'T_grid', [4 6 8 10 12 16], ...
        'h_fixed_km', 1000, ...
        'F_fixed', 1, ...
        'plot_visible', char(string(args.plot_visible)), ...
        'artifact_root', fullfile(char(string(args.artifact_root)), 'raw_legacy_strict'), ...
        'output_suffix', 'products_raw', ...
        'use_parallel', logical(args.use_parallel), ...
        'show_progress', logical(args.show_progress));
end

grid_tbl = raw.grid_table;

products = struct();
products.meta = struct();
products.meta.preset = string(preset);
products.meta.profile_name = string(profile.name);
products.meta.artifact_root = string(args.artifact_root);

products.raw = struct();
products.raw.grid_table = grid_tbl;
products.raw.truth_table = grid_tbl;

products.scan = struct();
products.scan.passratio_profile = local_build_passratio_profile(grid_tbl);
products.scan.bestDG_heatmap = local_build_bestDG_heatmap(grid_tbl);
products.scan.minNs_heatmap = local_build_minNs_heatmap(grid_tbl);
end

function prod = local_build_passratio_profile(grid_tbl)
i_list = unique(grid_tbl.i_deg(:))';
ns_list = unique(grid_tbl.Ns(:))';
value_matrix = nan(numel(i_list), numel(ns_list));

for ii = 1:numel(i_list)
    for jj = 1:numel(ns_list)
        mask = grid_tbl.i_deg == i_list(ii) & grid_tbl.Ns == ns_list(jj);
        if any(mask)
            value_matrix(ii, jj) = max(grid_tbl.pass_ratio(mask));
        end
    end
end

prod = struct();
prod.i_list = i_list;
prod.ns_list = ns_list;
prod.value_matrix = value_matrix;
end

function prod = local_build_bestDG_heatmap(grid_tbl)
i_list = unique(grid_tbl.i_deg(:))';
P_list = unique(grid_tbl.P(:))';

metric_name = 'DG_rob';
if ismember('D_G_min', grid_tbl.Properties.VariableNames)
    metric_name = 'D_G_min';
end

value_matrix = nan(numel(P_list), numel(i_list));
for pp = 1:numel(P_list)
    for ii = 1:numel(i_list)
        mask = grid_tbl.i_deg == i_list(ii) & grid_tbl.P == P_list(pp) & grid_tbl.feasible_flag > 0;
        if any(mask)
            value_matrix(pp, ii) = max(grid_tbl.(metric_name)(mask));
        end
    end
end

prod = struct();
prod.P_list = P_list;
prod.i_list = i_list;
prod.metric_name = string(metric_name);
prod.value_matrix = value_matrix;
end

function prod = local_build_minNs_heatmap(grid_tbl)
i_list = unique(grid_tbl.i_deg(:))';
P_list = unique(grid_tbl.P(:))';
value_matrix = nan(numel(P_list), numel(i_list));

for pp = 1:numel(P_list)
    for ii = 1:numel(i_list)
        mask = grid_tbl.i_deg == i_list(ii) & grid_tbl.P == P_list(pp) & grid_tbl.feasible_flag > 0;
        if any(mask)
            value_matrix(pp, ii) = min(grid_tbl.Ns(mask));
        end
    end
end

prod = struct();
prod.P_list = P_list;
prod.i_list = i_list;
prod.value_matrix = value_matrix;
end
