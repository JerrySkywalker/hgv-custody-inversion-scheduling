function test_engine_window_stage04_vs_legacy()
startup;

ctx = build_engine_test_context();

window_engine = compute_window_metric(ctx.vis_case, ctx.satbank, ctx.cfg);
window_legacy = scan_worst_window_stage04(ctx.vis_case, ctx.satbank, ctx.cfg);
sum_engine = summarize_worst_window(window_engine);
sum_legacy = summarize_window_case_stage04(window_legacy);

assert(all(size(window_engine.lambda_min) == size(window_legacy.lambda_min)), 'Window scan size mismatch.');
assert(max(abs(window_engine.lambda_min - window_legacy.lambda_min)) < 1e-9, 'lambda_min mismatch.');
assert(abs(sum_engine.lambda_min_worst - sum_legacy.lambda_min_worst) < 1e-9, 'Worst lambda mismatch.');
assert(abs(sum_engine.t0_worst_s - sum_legacy.t0_worst_s) < 1e-9, 'Worst t0 mismatch.');

disp('test_engine_window_stage04_vs_legacy passed.');
end
