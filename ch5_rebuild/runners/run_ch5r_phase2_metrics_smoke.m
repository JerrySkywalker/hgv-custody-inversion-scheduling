function out = run_ch5r_phase2_metrics_smoke()
%RUN_CH5R_PHASE2_METRICS_SMOKE
% R2 metric-layer smoke test on top of R1.5 real kernel.
%
% Semantics:
% - use Phase R1 output
% - use valid_for_bubble mask from centered_full_only windows
% - package only real-kernel metrics

out1 = run_ch5r_phase1_smoke();

resource_score = 2;  % fixed static double-satellite pair baseline
result = package_ch5r_result_real( ...
    out1.case, ...
    out1.selection_trace, ...
    out1.wininfo, ...
    out1.bubble, ...
    resource_score);

disp(' ')
disp('=== [ch5r:R2] metrics smoke summary ===')
disp(['valid steps          : ' num2str(result.bubble_metrics.total_valid_steps)])
disp(['valid time (s)       : ' num2str(result.bubble_metrics.total_valid_time_s)])
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['min req margin       : ' num2str(result.requirement.min_margin, '%.12g')])
disp(['req violation steps  : ' num2str(result.requirement.total_violation_steps)])
disp(['custody ratio        : ' num2str(result.custody_metrics.custody_ratio, '%.6f')])
disp(['switch count         : ' num2str(result.cost_metrics.switch_count)])
disp(['resource score       : ' num2str(result.cost_metrics.resource_score)])

assert(isfield(result, 'bubble_metrics'));
assert(isfield(result, 'custody_metrics'));
assert(isfield(result, 'rmse_proxy_metrics'));
assert(isfield(result, 'requirement'));
assert(isfield(result, 'cost_metrics'));

assert(result.bubble_metrics.total_valid_steps > 0, ...
    '[ch5r:R2] total_valid_steps must be > 0.');
assert(result.bubble_metrics.bubble_steps > 0, ...
    '[ch5r:R2] bubble_steps must be > 0.');
assert(result.requirement.total_violation_steps == result.bubble_metrics.bubble_steps, ...
    '[ch5r:R2] requirement violations should match bubble steps under current semantics.');

out = struct();
out.phase1 = out1;
out.result = result;
out.ok = true;

disp('[ch5r:R2] metrics smoke passed.')
end
