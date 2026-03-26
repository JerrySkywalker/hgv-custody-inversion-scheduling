function products = run_stage05_scan_products(varargin)
%RUN_STAGE05_SCAN_PRODUCTS Build Stage05 scan products from reusable raw results.
%
% Current scope:
%   - legacy_stage05_strict preset only
%   - reuses existing Stage05 OpenD legacy-reproduction framework result
%   - produces three base scan products:
%       1) passratio_profile
%       2) bestDG_heatmap
%       3) minNs_heatmap

p = inputParser;
addParameter(p, 'preset', 'legacy_stage05_strict', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_scan_products'), @(x) ischar(x) || isstring(x));
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
args = p.Results;

preset = char(string(args.preset));
if ~strcmpi(preset, 'legacy_stage05_strict')
    error('run_stage05_scan_products:UnsupportedPreset', ...
        'Only preset legacy_stage05_strict is supported in this step.');
end

raw = run_stage05_opend_legacy_reproduction_framework( ...
    'profile', make_profile_MB_nominal_validation_stage05(), ...
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

products = struct();
products.meta = struct();
products.meta.preset = string(preset);
products.meta.artifact_root = string(args.artifact_root);

products.raw = struct();
products.raw.truth_table = raw.outputs.truth_table;
products.raw.best_pass_by_Ns = raw.outputs.best_pass_by_Ns;
products.raw.geometry_heatmap_i60 = raw.outputs.geometry_heatmap_i60;
products.raw.grid_table = raw.grid_table;

products.scan = struct();
products.scan.passratio_profile = local_build_passratio_profile(products.raw.truth_table);
products.scan.bestDG_heatmap = local_build_bestDG_heatmap(products.raw.truth_table);
products.scan.minNs_heatmap = local_build_minNs_heatmap(products.raw.truth_table);
end

function prod = local_build_passratio_profile(truth_tbl)
i_list = unique(truth_tbl.i_deg(:))';
ns_list = unique(truth_tbl.Ns(:))';

value_matrix = nan(numel(i_list), numel(ns_list));
for ii = 1:numel(i_list)
    i_deg = i_list(ii);
    for jj = 1:numel(ns_list)
        Ns = ns_list(jj);
        mask = truth_tbl.i_deg == i_deg & truth_tbl.Ns == Ns;
        if any(mask)
            value_matrix(ii, jj) = max(truth_tbl.pass_ratio(mask));
        end
    end
end

prod = struct();
prod.i_list = i_list;
prod.ns_list = ns_list;
prod.value_matrix = value_matrix;
end

function prod = local_build_bestDG_heatmap(truth_tbl)
i_list = unique(truth_tbl.i_deg(:))';
P_list = unique(truth_tbl.P(:))';

value_matrix = nan(numel(P_list), numel(i_list));
for pp = 1:numel(P_list)
    P = P_list(pp);
    for ii = 1:numel(i_list)
        i_deg = i_list(ii);
        mask = truth_tbl.i_deg == i_deg & truth_tbl.P == P & truth_tbl.pass_ratio > 0;
        if any(mask)
            value_matrix(pp, ii) = max(truth_tbl.DG_rob(mask));
        end
    end
end

prod = struct();
prod.P_list = P_list;
prod.i_list = i_list;
prod.value_matrix = value_matrix;
end

function prod = local_build_minNs_heatmap(truth_tbl)
i_list = unique(truth_tbl.i_deg(:))';
P_list = unique(truth_tbl.P(:))';

value_matrix = nan(numel(P_list), numel(i_list));
for pp = 1:numel(P_list)
    P = P_list(pp);
    for ii = 1:numel(i_list)
        i_deg = i_list(ii);
        mask = truth_tbl.i_deg == i_deg & truth_tbl.P == P & truth_tbl.pass_ratio > 0;
        if any(mask)
            value_matrix(pp, ii) = min(truth_tbl.Ns(mask));
        end
    end
end

prod = struct();
prod.P_list = P_list;
prod.i_list = i_list;
prod.value_matrix = value_matrix;
end
