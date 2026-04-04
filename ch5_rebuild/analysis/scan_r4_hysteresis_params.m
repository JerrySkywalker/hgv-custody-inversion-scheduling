function T = scan_r4_hysteresis_params()
%SCAN_R4_HYSTERESIS_PARAMS  Quick scan over tau_low/tau_high ratios for R4 diagnostics.

cfg0 = default_ch5r_params();

low_grid = cfg0.ch5r.r4.scan.tau_low_ratio_grid;
high_grid = cfg0.ch5r.r4.scan.tau_high_ratio_grid;

rows = [];

for i = 1:numel(low_grid)
    for j = 1:numel(high_grid)
        low = low_grid(i);
        high = high_grid(j);

        if high <= low
            continue;
        end

        cfg = cfg0;
        cfg.ch5r.r4.tau_low_ratio = low;
        cfg.ch5r.r4.tau_high_ratio = high;

        ch5case = build_ch5r_case(cfg);
        policy = policy_tracking_greedy(cfg, ch5case);

        N = numel(ch5case.time_s);
        selection_trace = cell(N, 1);
        for k = 1:N
            selection_trace{k} = select_satellite_set_tracking_greedy(policy, k);
        end

        [info_series_adj, ~] = apply_policy_to_info_series(ch5case, selection_trace, cfg);
        ch5case2 = ch5case;
        ch5case2.info_series = info_series_adj;

        wininfo = eval_window_information(ch5case2);
        bubble = eval_bubble_state(ch5case2, wininfo);
        state_trace = package_state_trace(ch5case2, wininfo, bubble);

        phase_like = struct();
        phase_like.cfg = cfg;
        phase_like.case = ch5case2;
        phase_like.wininfo = wininfo;
        phase_like.bubble = bubble;
        phase_like.state_trace = state_trace;
        phase_like.ok = true;

        result = package_ch5r_result(phase_like, policy, selection_trace);

        row = table();
        row.tau_low_ratio = low;
        row.tau_high_ratio = high;
        row.switch_count = result.cost_metrics.switch_count;
        row.resource_score = result.cost_metrics.resource_score;
        row.bubble_time_s = result.bubble_metrics.bubble_time_s;
        row.longest_bubble_time_s = result.bubble_metrics.longest_bubble_time_s;
        row.max_bubble_depth = result.bubble_metrics.max_bubble_depth;
        row.min_margin = result.requirement.min_margin;

        rows = [rows; row]; %#ok<AGROW>
    end
end

T = rows;
end
