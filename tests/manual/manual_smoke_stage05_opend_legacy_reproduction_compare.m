function out = manual_smoke_stage05_opend_legacy_reproduction_compare(varargin)
startup;

p = inputParser;
addParameter(p, 'framework_result', [], @(x) isempty(x) || isstruct(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_legacy_reproduction','compare_smoke'), @(x) ischar(x) || isstring(x));
parse(p, varargin{:});
args = p.Results;

if isempty(args.framework_result)
    fw = run_stage05_opend_legacy_reproduction_framework( ...
        'i_grid_deg', [30 40 50 60 70 80 90], ...
        'P_grid', [4 6 8 10 12], ...
        'T_grid', [4 6 8 10 12 16], ...
        'h_fixed_km', 1000, ...
        'F_fixed', 1, ...
        'plot_visible', 'off', ...
        'artifact_root', char(string(args.artifact_root)), ...
        'output_suffix', 'compare_smoke');
else
    fw = args.framework_result;
end

legacy_best = manual_compare_stage05_best_envelope_fullgrid_all_i();
legacy_hm_i60 = manual_compare_stage05_heatmap_fullgrid_i60();

out = struct();
out.framework = fw;
out.legacy_best = legacy_best;
out.legacy_hm_i60 = legacy_hm_i60;

fw_best = fw.outputs.best_pass_by_Ns(:, {'Ns','pass_ratio'});

lg_best_raw = legacy_best.compare_table(:, {'Ns','legacy_best_pass'});
lg_best_raw = renamevars(lg_best_raw, 'legacy_best_pass', 'legacy_pass_ratio');

[Gbest, ns_tbl] = findgroups(lg_best_raw(:, {'Ns'}));
lg_best = ns_tbl;
lg_best.legacy_pass_ratio = splitapply(@max, lg_best_raw.legacy_pass_ratio, Gbest);

best_cmp = outerjoin(fw_best, lg_best, 'Keys', 'Ns', 'MergeKeys', true);
best_cmp.pass_abs_diff = abs(best_cmp.pass_ratio - best_cmp.legacy_pass_ratio);

fw_hm = fw.outputs.geometry_heatmap_i60;
fw_hm_tbl = local_heatmap_to_table(fw_hm, 'framework_DG_rob');

lg_hm_tbl = legacy_hm_i60.margin_compare(:, {'P','T','legacy_geometry_margin'});
lg_hm_tbl = renamevars(lg_hm_tbl, 'legacy_geometry_margin', 'legacy_DG_rob');

heatmap_cmp = outerjoin(fw_hm_tbl, lg_hm_tbl, 'Keys', {'P','T'}, 'MergeKeys', true);
heatmap_cmp.abs_diff = abs(heatmap_cmp.framework_DG_rob - heatmap_cmp.legacy_DG_rob);

out.best_pass_compare = sortrows(best_cmp, 'Ns');
out.heatmap_compare = sortrows(heatmap_cmp, {'P','T'});

disp('[manual] Stage05 OpenD legacy reproduction compare completed.');
disp(out.best_pass_compare);
disp(out.heatmap_compare);
end

function tbl = local_heatmap_to_table(hm, value_name)
[Pgrid, Tgrid] = ndgrid(hm.row_values(:), hm.col_values(:));
tbl = table();
tbl.P = Pgrid(:);
tbl.T = Tgrid(:);
tbl.(value_name) = hm.value_matrix(:);
end
