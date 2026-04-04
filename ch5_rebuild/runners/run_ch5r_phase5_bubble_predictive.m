function out = run_ch5r_phase5_bubble_predictive()
%RUN_CH5R_PHASE5_BUBBLE_PREDICTIVE
% Minimal real R5: future-window-oriented bubble-predictive scheduling.

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;
cfg.ch5r.r5 = struct();
cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 0.1;

% Parallel options
cfg.ch5r.r5.parallel = struct();
cfg.ch5r.r5.parallel.enable = true;

% Log options
cfg.ch5r.r5.log = struct();
cfg.ch5r.r5.log.enable = true;
cfg.ch5r.r5.log.verbose_step = false;
cfg.ch5r.r5.log.log_every = 10;
cfg.ch5r.r5.log.show_step_timing = true;
cfg.ch5r.r5.log.show_candidate_count = true;
cfg.ch5r.r5.log.show_best_score = true;

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

if cfg.ch5r.r5.log.enable
    disp('=== [R5] Start bubble-predictive scheduling ===')
end

t_total = tic;

for k = 1:Nt
    t_step = tic;

    if isempty(ch5case.candidates.pair_bank{k})
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', [], ...
            'switch_flag', false, ...
            'name', 'bubble_predictive_empty', ...
            'n_pairs', 0);
    else
        prefix = selection_trace;
        sel = select_satellite_set_bubble_predictive(cfg, ch5case, prefix, k);

        if k > 1 && ~isempty(selection_trace{k-1}.pair)
            sel.prev_pair = selection_trace{k-1}.pair;
            sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
        end

        selection_trace{k} = sel;
    end

    step_time_s = toc(t_step);

    if cfg.ch5r.r5.log.enable
        do_log = cfg.ch5r.r5.log.verbose_step || k == 1 || k == Nt || mod(k, cfg.ch5r.r5.log.log_every) == 0;
        if do_log
            msg = sprintf('[R5][k=%d/%d]', k, Nt);

            if cfg.ch5r.r5.log.show_candidate_count
                msg = sprintf('%s nPairs=%d', msg, selection_trace{k}.n_pairs);
            end

            if ~isempty(selection_trace{k}.pair)
                msg = sprintf('%s bestPair=[%d %d]', msg, selection_trace{k}.pair(1), selection_trace{k}.pair(2));
            else
                msg = sprintf('%s bestPair=[]', msg);
            end

            if cfg.ch5r.r5.log.show_best_score
                msg = sprintf('%s score=%.6g', msg, selection_trace{k}.score);
            end

            if cfg.ch5r.r5.log.show_step_timing
                msg = sprintf('%s stepTime=%.3fs elapsed=%.3fs', msg, step_time_s, toc(t_total));
            end

            disp(msg)
        end
    end
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
