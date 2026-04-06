function out = run_ch5r_phase5_bubble_predictive()
%RUN_CH5R_PHASE5_BUBBLE_PREDICTIVE
% Real R5:
% - future-window-oriented bubble-predictive scheduling
% - centered full-only window semantics
% - explicit tail mode after the last valid full-window center
% - real result packaging aligned with R3/R4

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;
cfg.ch5r.window_mode = 'centered_full_only';
cfg.ch5r.window_exclude_incomplete_edges = true;

cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 500;
cfg.ch5r.r5.min_hold_steps = 5;

cfg.ch5r.r5.parallel.enable = true;

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

% Last center that still has a full centered window
last_valid_center = Nt - ch5case.window.right_steps;

if cfg.ch5r.r5.log.enable
    disp('=== [R5] Start bubble-predictive scheduling ===')
    disp(['[R5] last_valid_center = ' num2str(last_valid_center)])
end

t_total = tic;
hold_countdown = 0;

for k = 1:Nt
    t_step = tic;
    mode_str = 'select';

    pair_list = ch5case.candidates.pair_bank{k};

    if isempty(pair_list)
        prev_pair = [];
        if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair')
            prev_pair = selection_trace{k-1}.pair;
        end

        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', prev_pair, ...
            'switch_flag', false, ...
            'name', 'bubble_predictive_empty', ...
            'n_pairs', 0);
        mode_str = 'empty';

    elseif k > last_valid_center
        % Tail mode: no future full-window center remains.
        prev_pair = [];
        if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair')
            prev_pair = selection_trace{k-1}.pair;
        end

        sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;

        if ~isempty(prev_pair) && ismember(prev_pair, pair_list, 'rows')
            pair = prev_pair;
            switched = false;
            mode_str = 'tail_hold';
        else
            best_score = -inf;
            pair = pair_list(1,:);
            for idx = 1:size(pair_list,1)
                cand = pair_list(idx,:);
                r_tgt = ch5case.truth.r_eci_km(k, :);
                r_sat_pair = [
                    squeeze(ch5case.satbank.r_eci_km(k, :, cand(1)));
                    squeeze(ch5case.satbank.r_eci_km(k, :, cand(2)))
                ];
                J_try = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
                s_try = trace(J_try);
                if s_try > best_score
                    best_score = s_try;
                    pair = cand;
                end
            end
            switched = ~(~isempty(prev_pair) && isequal(pair, prev_pair));
            mode_str = 'tail_current_trace';
        end

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
            'prev_pair', prev_pair, ...
            'switch_flag', switched, ...
            'name', 'bubble_predictive_tail_mode', ...
            'eval', struct('score_mode','tail_explicit_mode'), ...
            'n_pairs', size(pair_list,1));

        hold_countdown = 0;

    else
        reuse_prev = false;

        if k > 1 && hold_countdown > 0 && ~isempty(selection_trace{k-1}.pair)
            prev_pair = selection_trace{k-1}.pair;
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
                'name', 'bubble_predictive_hold', ...
                'eval', [], ...
                'n_pairs', size(pair_list,1));

            hold_countdown = hold_countdown - 1;
            mode_str = 'hold';

        else
            prefix = selection_trace;
            sel = select_satellite_set_bubble_predictive(cfg, ch5case, prefix, k);

            if k > 1 && ~isempty(selection_trace{k-1}.pair)
                sel.prev_pair = selection_trace{k-1}.pair;
                sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
            else
                sel.prev_pair = [];
                sel.switch_flag = false;
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
            msg = sprintf('[R5][k=%d/%d][%s]', k, Nt, mode_str);

            if isfield(selection_trace{k}, 'n_pairs') && cfg.ch5r.r5.log.show_candidate_count
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
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

resource_score = 2;
result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score);

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR5_bubble_predictive_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR5_bubble_predictive_real_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'wininfo', 'bubble', 'state_trace', 'result');

disp(' ')
disp('=== [ch5r:R5-real] bubble-predictive baseline summary ===')
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

assert(strcmp(ch5case.target_case.case_id, 'N01'), '[ch5r:R5] target case must be N01.');
assert(strcmp(ch5case.window.mode, 'centered_full_only'), '[ch5r:R5] window mode must be centered_full_only.');
assert(result.bubble_metrics.total_valid_steps > 0, '[ch5r:R5] total_valid_steps must be > 0.');
assert(result.cost_metrics.resource_score == 2, '[ch5r:R5] resource_score must be 2.');

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
