function out = run_ch5r_phase2_metrics_smoke()
%RUN_CH5R_PHASE2_METRICS_SMOKE  Minimal R2 metric-layer smoke test.

out1 = run_ch5r_phase1_smoke();
result = package_ch5r_result(out1);

disp(' ')
disp('=== [ch5r:R2] metrics smoke summary ===')
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['min req margin       : ' num2str(result.requirement.min_margin, '%.12g')])
disp(['req violation steps  : ' num2str(result.requirement.total_violation_steps)])

assert(isfield(result, 'state_trace'));
assert(isfield(result, 'bubble_metrics'));
assert(isfield(result, 'requirement'));
assert(result.bubble_metrics.bubble_steps > 0);
assert(result.requirement.total_violation_steps > 0);

out = struct();
out.phase1 = out1;
out.result = result;
out.ok = true;

disp('[ch5r:R2] metrics smoke passed.')
end
