function out = run_ch5r_phase4_tracking_baseline()
%RUN_CH5R_PHASE4_TRACKING_BASELINE
% Real R4 baseline:
% - one fixed real constellation (theta_star from R0)
% - real HGV truth from Stage02
% - double-satellite scheduling inside the same constellation
% - centered full-only window semantics inherited from R1.5/R2/R3
% - metrics packaged through the real result line

cfg = default_ch5r_params(true);
cfg.ch5r.r4.lambda_sw = 0.1;
cfg.ch5r.window_length_s = 60;
cfg.ch5r.window_mode = 'centered_full_only';
cfg.ch5r.window_exclude_incomplete_edges = true;

ch5case = build_ch5r_case(cfg);

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);
prev_pair = [];

for k = 1:Nt
    if isempty(ch5case.candidates.pair_bank{k})
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', prev_pair, ...
            'switch_flag', false, ...
            'name', 'tracking_greedy_real_pair_empty');
        continue;
    end

    sel = select_satellite_set_tracking_greedy( ...
        cfg, ch5case.truth, ch5case.satbank, ch5case.candidates, k, prev_pair);

    selection_trace{k} = sel;
    prev_pair = sel.pair;
end

wininfo = eval_window_information(ch5case, selection_trace);
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

resource_score = 2;
result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score);

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR4_tracking_baseline_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR4_tracking_baseline_real_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'wininfo', 'bubble', 'state_trace', 'result');

disp(' ')
disp('=== [ch5r:R4-real] tracking-greedy baseline summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['fixed constellation  : theta_star'])
disp(['Ns                   : ' num2str(ch5case.theta.Ns)])
disp(['window mode          : ' ch5case.window.mode])
disp(['window length (s)    : ' num2str(ch5case.window.length_s)])
disp(['tracking resource    : double-satellite'])
disp(['valid steps          : ' num2str(result.bubble_metrics.total_valid_steps)])
disp(['valid time (s)       : ' num2str(result.bubble_metrics.total_valid_time_s)])
disp(['bubble steps         : ' num2str(result.bubble_steps)])
disp(['bubble time (s)      : ' num2str(result.bubble_time_s, '%.6f')])
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(result.switch_count)])
disp(['resource score       : ' num2str(result.resource_score)])
disp(['mat file             : ' mat_file])

assert(strcmp(ch5case.target_case.case_id, 'N01'), '[ch5r:R4] target case must be N01.');
assert(strcmp(ch5case.window.mode, 'centered_full_only'), '[ch5r:R4] window mode must be centered_full_only.');
assert(result.bubble_metrics.total_valid_steps > 0, '[ch5r:R4] total_valid_steps must be > 0.');
assert(result.cost_metrics.resource_score == 2, '[ch5r:R4] dynamic double-satellite baseline resource_score must be 2.');

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end
