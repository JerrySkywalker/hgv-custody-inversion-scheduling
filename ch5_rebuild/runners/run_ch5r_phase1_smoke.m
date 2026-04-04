function out = run_ch5r_phase1_smoke()
%RUN_CH5R_PHASE1_SMOKE  Minimal R1 smoke test for bubble-state pipeline.

cfg = default_ch5r_params();

ch5case = build_ch5r_case(cfg);
wininfo = eval_window_information(ch5case);
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

disp(' ')
disp('=== [ch5r:R1] bubble-state smoke summary ===')
disp(['target case        : ' ch5case.target_case.case_id])
disp(['theta_star Ns      : ' num2str(ch5case.theta.Ns)])
disp(['window length (s)  : ' num2str(ch5case.window.length_s)])
disp(['gamma_req          : ' num2str(ch5case.gamma_req, '%.12g')])
disp(['min lambda_min     : ' num2str(min(bubble.lambda_min), '%.12g')])
disp(['bubble steps       : ' num2str(bubble.total_bubble_steps)])
disp(['bubble time (s)    : ' num2str(bubble.total_bubble_time_s)])
disp(['longest bubble (s) : ' num2str(bubble.longest_bubble_time_s)])

assert(isfield(ch5case, 'info_series'));
assert(isfield(wininfo, 'lambda_min'));
assert(isfield(bubble, 'is_bubble'));
assert(numel(wininfo.lambda_min) == numel(ch5case.time_s));
assert(numel(bubble.is_bubble) == numel(ch5case.time_s));

% R1 positive-case requirement:
assert(bubble.total_bubble_steps > 0, 'R1 smoke must include at least one bubble step.');
assert(bubble.longest_bubble_time_s > 0, 'R1 smoke must include a positive bubble duration.');

% Unified state-trace checks:
assert(isfield(state_trace, 'time_s'));
assert(isfield(state_trace, 'lambda_min'));
assert(isfield(state_trace, 'gamma_req'));
assert(isfield(state_trace, 'is_bubble'));
assert(isfield(state_trace, 'bubble_depth'));
assert(numel(state_trace.time_s) == numel(ch5case.time_s));
assert(numel(state_trace.lambda_min) == numel(ch5case.time_s));
assert(numel(state_trace.is_bubble) == numel(ch5case.time_s));

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.ok = true;

disp('[ch5r:R1] bubble-state smoke passed.')
end
