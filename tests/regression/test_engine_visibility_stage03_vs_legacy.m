function test_engine_visibility_stage03_vs_legacy()
startup;

ctx = build_engine_test_context();

vis_engine = compute_visibility_matrix(ctx.traj_case, ctx.satbank, ctx.cfg);
vis_legacy = compute_visibility_matrix_stage03(ctx.traj_case, ctx.satbank, ctx.cfg);
geom_engine = compute_geometry_series(vis_engine, ctx.satbank);
geom_legacy = compute_los_geometry_stage03(vis_legacy, ctx.satbank);
sum_engine = summarize_visibility_case(vis_engine, geom_engine);
sum_legacy = summarize_visibility_case_stage03(vis_legacy, geom_legacy);

assert(all(size(vis_engine.visible_mask) == size(vis_legacy.visible_mask)), 'Visibility mask size mismatch.');
assert(isequal(vis_engine.visible_mask, vis_legacy.visible_mask), 'Visibility mask mismatch.');
assert(max(abs(geom_engine.min_crossing_angle_deg - geom_legacy.min_crossing_angle_deg), [], 'omitnan') < 1e-9, ...
    'Geometry series mismatch.');
assert(abs(sum_engine.dual_coverage_ratio - sum_legacy.dual_coverage_ratio) < 1e-12, ...
    'Dual coverage ratio mismatch.');

disp('test_engine_visibility_stage03_vs_legacy passed.');
end
