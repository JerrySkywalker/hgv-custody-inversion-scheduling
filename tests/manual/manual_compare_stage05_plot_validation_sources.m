function out = manual_compare_stage05_plot_validation_sources(out_plot)
%MANUAL_COMPARE_STAGE05_PLOT_VALIDATION_SOURCES Compare framework plotting sources against legacy Stage05 plotting sources.

if nargin < 1 || isempty(out_plot)
    out_plot = manual_smoke_stage05_plot_validation_suite();
end

legacy_best = manual_compare_stage05_best_envelope_fullgrid_all_i();
legacy_hm_i60 = manual_compare_stage05_heatmap_fullgrid_i60();

out = struct();
out.framework = out_plot;
out.legacy_best = legacy_best;
out.legacy_hm_i60 = legacy_hm_i60;

fw_best = out_plot.reproduction.outputs.best_pass_by_Ns(:, {'Ns','pass_ratio'});

lg_best_raw = legacy_best.compare_table(:, {'Ns','legacy_best_pass'});
lg_best_raw = renamevars(lg_best_raw, 'legacy_best_pass', 'legacy_pass_ratio');

[Gbest, ns_tbl] = findgroups(lg_best_raw(:, {'Ns'}));
lg_best = ns_tbl;
lg_best.legacy_pass_ratio = splitapply(@max, lg_best_raw.legacy_pass_ratio, Gbest);

best_cmp = outerjoin(fw_best, lg_best, 'Keys', 'Ns', 'MergeKeys', true);
best_cmp.pass_abs_diff = abs(best_cmp.pass_ratio - best_cmp.legacy_pass_ratio);

fw_hm = out_plot.reproduction.outputs.geometry_heatmap_i60;
fw_hm_tbl = local_heatmap_to_table(fw_hm, 'framework_DG_rob');

lg_hm_tbl = legacy_hm_i60.margin_compare(:, {'P','T','legacy_geometry_margin'});
lg_hm_tbl = renamevars(lg_hm_tbl, 'legacy_geometry_margin', 'legacy_DG_rob');

heatmap_cmp = outerjoin(fw_hm_tbl, lg_hm_tbl, 'Keys', {'P','T'}, 'MergeKeys', true);
heatmap_cmp.abs_diff = abs(heatmap_cmp.framework_DG_rob - heatmap_cmp.legacy_DG_rob);

out.best_pass_compare = sortrows(best_cmp, 'Ns');
out.heatmap_compare = sortrows(heatmap_cmp, {'P','T'});

disp('[manual] Stage05 plot validation source compare completed.');
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
