function out = run_ch5r_phase4_tracking_baseline()
%RUN_CH5R_PHASE4_TRACKING_BASELINE
% Real R4 rewrite:
% - one fixed real constellation
% - real HGV truth from Stage02
% - double-satellite scheduling inside the same constellation

cfg = default_ch5r_params(false);
cfg.ch5r.r4 = struct();
cfg.ch5r.r4.lambda_sw = 0.1;
cfg.ch5r.window_length_s = 60;

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

    sel = select_satellite_set_tracking_greedy(cfg, ch5case.truth, ch5case.satbank, ch5case.candidates, k, prev_pair);
    selection_trace{k} = sel;
    prev_pair = sel.pair;
end

wininfo = eval_window_information(ch5case, selection_trace);

bubble = struct();
bubble.t_s = wininfo.t_s;
bubble.gamma_req = ch5case.gamma_req;
bubble.lambda_min = wininfo.lambda_min;
bubble.is_bubble = wininfo.lambda_min < ch5case.gamma_req;
bubble.bubble_depth = max(0, ch5case.gamma_req - wininfo.lambda_min);

switch_count = 0;
for k = 2:Nt
    if ~isempty(selection_trace{k}.pair) && ~isempty(selection_trace{k-1}.pair)
        if ~isequal(selection_trace{k}.pair, selection_trace{k-1}.pair)
            switch_count = switch_count + 1;
        end
    end
end

resource_score = 2; % fixed double-satellite tracking
bubble_steps = nnz(bubble.is_bubble);
bubble_time_s = bubble_steps * ch5case.dt;
max_bubble_depth = max(bubble.bubble_depth);

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR4_tracking_baseline_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR4_tracking_baseline_real_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'wininfo', 'bubble');

disp(' ')
disp('=== [ch5r:R4-real] tracking-greedy baseline summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['fixed constellation  : theta_star'])
disp(['Ns                   : ' num2str(ch5case.satbank.Ns)])
disp(['tracking resource    : double-satellite'])
disp(['bubble steps         : ' num2str(bubble_steps)])
disp(['bubble time (s)      : ' num2str(bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(switch_count)])
disp(['resource score       : ' num2str(resource_score)])
disp(['mat file             : ' mat_file])

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.result = struct( ...
    'bubble_steps', bubble_steps, ...
    'bubble_time_s', bubble_time_s, ...
    'max_bubble_depth', max_bubble_depth, ...
    'switch_count', switch_count, ...
    'resource_score', resource_score);
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end
