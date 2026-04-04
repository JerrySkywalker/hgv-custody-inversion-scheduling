function out = run_ch5r_phase1_smoke()
%RUN_CH5R_PHASE1_SMOKE  Minimal R1 smoke test for bubble-state pipeline.

cfg = default_ch5r_params();

ch5case = build_ch5r_case(cfg);
wininfo = eval_window_information(ch5case);
bubble = eval_bubble_state(ch5case, wininfo);

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

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.wininfo = wininfo;
out.bubble = bubble;
out.ok = true;

disp('[ch5r:R1] bubble-state smoke passed.')
end
