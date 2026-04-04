function out = run_ch5r_phase5_bubble_predictive()
%RUN_CH5R_PHASE5_BUBBLE_PREDICTIVE
% Minimal real R5: future-window-oriented bubble-predictive scheduling.

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;
cfg.ch5r.r5 = struct();
cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 0.1;

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

for k = 1:Nt
    if isempty(ch5case.candidates.pair_bank{k})
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', [], ...
            'switch_flag', false, ...
            'name', 'bubble_predictive_empty');
        continue;
    end

    prefix = selection_trace;
    sel = select_satellite_set_bubble_predictive(cfg, ch5case, prefix, k);

    if k > 1 && ~isempty(selection_trace{k-1}.pair)
        sel.prev_pair = selection_trace{k-1}.pair;
        sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
    end

    selection_trace{k} = sel;
end

wininfo = eval_window_information(ch5case, selection_trace);

bubble = struct();
bubble.t_s = wininfo.t_s;
bubble.gamma_req = ch5case.gamma_req;
bubble.lambda_min = wininfo.lambda_min;
bubble.is_bubble = wininfo.lambda_min < ch5case.gamma_req;
bubble.bubble_depth = max(0, ch5case.gamma_req - wininfo.lambda_min);

resource_score = 2;
result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score);

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR5_bubble_predictive_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR5_bubble_predictive_real_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'wininfo', 'bubble', 'result');

disp(' ')
disp('=== [ch5r:R5-real] bubble-predictive baseline summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['fixed constellation  : theta_star'])
disp(['Ns                   : ' num2str(ch5case.satbank.Ns)])
disp(['tracking resource    : double-satellite'])
disp(['bubble steps         : ' num2str(result.bubble_steps)])
disp(['bubble time (s)      : ' num2str(result.bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(result.switch_count)])
disp(['resource score       : ' num2str(result.resource_score)])
disp(['mat file             : ' mat_file])

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.result = result;
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end
