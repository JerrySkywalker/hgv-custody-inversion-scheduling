function out = run_ch5r_phase8_C3_outerB_bubble_correction_real_kernel()
%RUN_CH5R_PHASE8_C3_OUTERB_BUBBLE_CORRECTION_REAL_KERNEL
% R8-C.3:
%   align outerB bubble correction with the same real future-window kernel as R5-real.
%
% Main idea:
%   - same ch5case / same time-varying visible pair bank / same J-pair kernel
%   - same local future-window predictor: predict_future_window_information(...)
%   - replace R5 scalar score with lexicographic Xi_B / tau_B / A_B rule

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;

cfg.ch5r.r5 = struct();
cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 500;
cfg.ch5r.r5.min_hold_steps = 5;

cfg.ch5r.r5.parallel = struct();
cfg.ch5r.r5.parallel.enable = true;

cfg.ch5r.r5.log = struct();
cfg.ch5r.r5.log.enable = true;
cfg.ch5r.r5.log.verbose_step = false;
cfg.ch5r.r5.log.log_every = 20;
cfg.ch5r.r5.log.show_step_timing = true;
cfg.ch5r.r5.log.show_candidate_count = true;
cfg.ch5r.r5.log.show_best_score = true;

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

if cfg.ch5r.r5.log.enable
    disp('=== [R8-C.3] Start real-kernel-aligned bubble correction ===')
end

t_total = tic;
hold_countdown = 0;

for k = 1:Nt
    t_step = tic;
    mode_str = 'select';

    if isempty(ch5case.candidates.pair_bank{k})
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', [], ...
            'switch_flag', false, ...
            'name', 'bubble_correction_real_kernel_empty', ...
            'eval', [], ...
            'n_pairs', 0);
        mode_str = 'empty';

    else
        reuse_prev = false;

        if k > 1 && hold_countdown > 0 && ~isempty(selection_trace{k-1}.pair)
            prev_pair = selection_trace{k-1}.pair;
            pair_list = ch5case.candidates.pair_bank{k};
            if ismember(prev_pair, pair_list, 'rows')
                reuse_prev = true;
            end
        end

        if reuse_prev
            pair = selection_trace{k-1}.pair;
            sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;
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
                'score', selection_trace{k-1}.score, ...
                'prev_pair', selection_trace{k-1}.pair, ...
                'switch_flag', false, ...
                'name', 'bubble_correction_real_kernel_hold', ...
                'eval', selection_trace{k-1}.eval, ...
                'n_pairs', size(ch5case.candidates.pair_bank{k},1));

            hold_countdown = hold_countdown - 1;
            mode_str = 'hold';

        else
            prefix = selection_trace;
            sel = select_pair_bubble_correction_real_kernel(cfg, ch5case, prefix, k);

            if k > 1 && ~isempty(selection_trace{k-1}.pair)
                sel.prev_pair = selection_trace{k-1}.pair;
                sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
            end

            selection_trace{k} = sel;

            if selection_trace{k}.switch_flag
                hold_countdown = cfg.ch5r.r5.min_hold_steps - 1;
            else
                hold_countdown = max(hold_countdown - 1, 0);
            end

            mode_str = 'select';
        end
    end

    step_time_s = toc(t_step);

    if cfg.ch5r.r5.log.enable
        do_log = cfg.ch5r.r5.log.verbose_step || k == 1 || k == Nt || mod(k, cfg.ch5r.r5.log.log_every) == 0;
        if do_log
            msg = sprintf('[R8-C.3][k=%d/%d][%s]', k, Nt, mode_str);

            if cfg.ch5r.r5.log.show_candidate_count
                msg = sprintf('%s nPairs=%d', msg, selection_trace{k}.n_pairs);
            end

            if ~isempty(selection_trace{k}.pair)
                msg = sprintf('%s bestPair=[%d %d]', msg, selection_trace{k}.pair(1), selection_trace{k}.pair(2));
            else
                msg = sprintf('%s bestPair=[]', msg);
            end

            if cfg.ch5r.r5.log.show_best_score
                msg = sprintf('%s Xi_B=%.6g', msg, selection_trace{k}.score);
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

% Additional R8-C.3-specific summary from selected evals
Xi_B_series = nan(Nt,1);
tau_B_time_s = nan(Nt,1);
A_B_series = nan(Nt,1);
for k = 1:Nt
    if isstruct(selection_trace{k}) && isfield(selection_trace{k}, 'eval') && ~isempty(selection_trace{k}.eval)
        Xi_B_series(k) = selection_trace{k}.eval.Xi_B;
        tau_B_time_s(k) = selection_trace{k}.eval.tau_B_time_s;
        A_B_series(k) = selection_trace{k}.eval.A_B;
    end
end

summary = struct();
summary.bubble_steps = result.bubble_steps;
summary.bubble_time_s = result.bubble_time_s;
summary.max_bubble_depth = result.max_bubble_depth;
summary.switch_count = result.switch_count;
summary.resource_score = result.resource_score;
summary.mean_Xi_B = mean(Xi_B_series, 'omitnan');
summary.has_failure_fraction = mean(isfinite(tau_B_time_s), 'omitnan');
summary.mean_tau_B_time_s = mean(tau_B_time_s(isfinite(tau_B_time_s)), 'omitnan');
summary.mean_A_B = mean(A_B_series, 'omitnan');

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR8_C3_outerB_bubble_correction_real_kernel');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_C3_outerB_bubble_correction_real_kernel_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'wininfo', 'bubble', 'result', 'summary', ...
    'Xi_B_series', 'tau_B_time_s', 'A_B_series');

disp(' ')
disp('=== [ch5r:R8-C.3] real-kernel-aligned bubble correction summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['fixed constellation  : theta_star'])
disp(['Ns                   : ' num2str(ch5case.satbank.Ns)])
disp(['tracking resource    : double-satellite'])
disp(['bubble steps         : ' num2str(summary.bubble_steps)])
disp(['bubble time (s)      : ' num2str(summary.bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(summary.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(summary.switch_count)])
disp(['mean Xi_B            : ' num2str(summary.mean_Xi_B, '%.12g')])
disp(['mean tau_B time (s)  : ' num2str(summary.mean_tau_B_time_s, '%.12g')])
disp(['mean A_B             : ' num2str(summary.mean_A_B, '%.12g')])
disp(['mat file             : ' mat_file])

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.result = result;
out.summary = summary;
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end
