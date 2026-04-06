function out = run_ch5r_phase1_smoke()
%RUN_CH5R_PHASE1_SMOKE
% Real R1 smoke with centered full-only window semantics.

cfg = default_ch5r_params(true);

ch5case = build_ch5r_case(cfg);

static_pair = select_satellite_set_static(cfg, ch5case.truth, ch5case.satbank, ch5case.candidates);

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;

for k = 1:Nt
    pair_list = ch5case.candidates.pair_bank{k};

    if isempty(pair_list)
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'r1_static_pair_empty');
        continue;
    end

    hit = ismember(pair_list, static_pair, 'rows');
    if any(hit)
        pair = static_pair;
        r_tgt = ch5case.truth.r_eci_km(k, :);
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(2)))
        ];
        J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);

        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', pair, ...
            'J_pair', J, ...
            'score', trace(J), ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'r1_static_pair');
    else
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'r1_static_pair_not_visible');
    end
end

wininfo = eval_window_information(ch5case, selection_trace);
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

valid_lambda = bubble.lambda_min(bubble.valid_for_bubble);
if isempty(valid_lambda)
    min_valid_lambda = NaN;
else
    min_valid_lambda = min(valid_lambda);
end

disp(' ')
disp('=== [ch5r:R1] bubble-state smoke summary ===')
disp(['target case          : ' ch5case.target_case.case_id])
disp(['theta_star Ns        : ' num2str(ch5case.theta.Ns)])
disp(['window mode          : ' ch5case.window.mode])
disp(['window length (s)    : ' num2str(ch5case.window.length_s)])
disp(['window length steps  : ' num2str(ch5case.window.length_steps)])
disp(['gamma_req            : ' num2str(ch5case.gamma_req, '%.12g')])
disp(['fixed static pair    : [' num2str(static_pair(1)) ', ' num2str(static_pair(2)) ']'])
disp(['valid steps          : ' num2str(bubble.total_valid_steps)])
disp(['valid time (s)       : ' num2str(bubble.total_valid_time_s)])
disp(['min valid lambda_min : ' num2str(min_valid_lambda, '%.12g')])
disp(['bubble steps         : ' num2str(bubble.total_bubble_steps)])
disp(['bubble time (s)      : ' num2str(bubble.total_bubble_time_s)])
disp(['longest bubble (s)   : ' num2str(bubble.longest_bubble_time_s)])

assert(strcmp(ch5case.target_case.case_id, 'N01'), '[ch5r:R1] target case must be N01.');
assert(strcmp(ch5case.window.mode, 'centered_full_only'), '[ch5r:R1] window mode must be centered_full_only.');

assert(isfield(wininfo, 'valid_for_bubble'));
assert(isfield(wininfo, 'is_full_window'));
assert(isfield(wininfo, 'window_count'));
assert(numel(wininfo.lambda_min) == numel(ch5case.t_s));
assert(numel(wininfo.valid_for_bubble) == numel(ch5case.t_s));

assert(isfield(bubble, 'valid_for_bubble'));
assert(numel(bubble.is_bubble) == numel(ch5case.t_s));
assert(numel(bubble.valid_for_bubble) == numel(ch5case.t_s));

assert(isfield(state_trace, 'valid_for_bubble'));
assert(isfield(state_trace, 'is_full_window'));
assert(numel(state_trace.time_s) == numel(ch5case.t_s));

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.static_pair = static_pair;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.ok = true;

disp('[ch5r:R1] bubble-state smoke passed.')
end
