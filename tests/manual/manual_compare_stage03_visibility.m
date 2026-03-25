function out = manual_compare_stage03_visibility()
cfg = default_params();

legacy_casebank = build_casebank_stage01(cfg);
case_item = legacy_casebank.nominal(1);
legacy_traj = propagate_hgv_case_stage02(case_item, cfg);

traj_case = struct('case', case_item, 'traj', legacy_traj);

legacy_walker = build_single_layer_walker_stage03(cfg);
legacy_satbank = propagate_constellation_stage03(legacy_walker, legacy_traj.t_s);

design_row = struct( ...
    'h_km', cfg.stage03.h_km, ...
    'i_deg', cfg.stage03.i_deg, ...
    'P', cfg.stage03.P, ...
    'T', cfg.stage03.T, ...
    'F', cfg.stage03.F);
engine_walker = build_single_layer_walker(design_row, cfg);
engine_satbank = propagate_constellation(engine_walker, legacy_traj.t_s, cfg);

legacy_vis = compute_visibility_matrix_stage03(traj_case, legacy_satbank, cfg);
engine_vis = compute_visibility_matrix(traj_case, engine_satbank, cfg);

out = struct();
out.legacy_num_visible_size = size(legacy_vis.num_visible);
out.engine_num_visible_size = size(engine_vis.num_visible);
out.num_visible_size_match = isequal(out.legacy_num_visible_size, out.engine_num_visible_size);

out.legacy_dual_cov_mean = mean(legacy_vis.dual_coverage_mask, 'all', 'omitnan');
out.engine_dual_cov_mean = mean(engine_vis.dual_coverage_mask, 'all', 'omitnan');
out.dual_cov_abs_diff = abs(out.legacy_dual_cov_mean - out.engine_dual_cov_mean);
end
