function out = run_ch5r_phase8_weak_prior_compare()
%RUN_CH5R_PHASE8_WEAK_PRIOR_COMPARE
% Enhanced R8:
% compare R5-real vs weak-prior-enhanced predictive scheduling
% with optional candidate pruning + close-score prior amplification.

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;

cfg.ch5r.r5 = struct();
cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 500;
cfg.ch5r.r5.min_hold_steps = 5;
cfg.ch5r.r5.parallel = struct('enable', true);

cfg.ch5r.r8 = struct();

% --- optional enhanced switches ---
cfg.ch5r.r8.enable_candidate_prune = true;
cfg.ch5r.r8.prune_keep_ratio = 0.50;
cfg.ch5r.r8.prune_min_keep = 6;

cfg.ch5r.r8.enable_close_score_prior = true;
cfg.ch5r.r8.close_gap = 50;
cfg.ch5r.r8.eps_prior_base = 1e-3;
cfg.ch5r.r8.eps_prior_close = 5;

cfg.ch5r.r8.log = struct();
cfg.ch5r.r8.log.enable = true;
cfg.ch5r.r8.log.log_every = 20;
cfg.ch5r.r8.log.show_step_timing = true;

out5 = run_ch5r_phase5_bubble_predictive();

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;
prior = build_static_weak_prior(cfg, ch5case);

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

disp('=== [R8] Start weak-prior compare scheduling ===')

hold_countdown = 0;
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
            'name', 'weak_prior_empty', ...
            'n_pairs_full', 0, ...
            'n_pairs_used', 0);
        continue;
    end

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
            'name', 'weak_prior_hold', ...
            'n_pairs_full', size(ch5case.candidates.pair_bank{k},1), ...
            'n_pairs_used', size(ch5case.candidates.pair_bank{k},1));
        hold_countdown = hold_countdown - 1;

    else
        sel = select_satellite_set_bubble_predictive_with_prior(cfg, ch5case, selection_trace, k, prior);
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
    end

    if cfg.ch5r.r8.log.enable
        do_log = (k == 1) || (k == Nt) || (mod(k, cfg.ch5r.r8.log.log_every) == 0);
        if do_log
            msg = sprintf('[R8][k=%d/%d] full=%d used=%d', ...
                k, Nt, selection_trace{k}.n_pairs_full, selection_trace{k}.n_pairs_used);

            if ~isempty(selection_trace{k}.pair)
                msg = sprintf('%s pair=[%d %d]', msg, selection_trace{k}.pair(1), selection_trace{k}.pair(2));
            else
                msg = sprintf('%s pair=[]', msg);
            end

            if isfield(selection_trace{k}, 'eval') && isfield(selection_trace{k}.eval, 'gain_meta')
                msg = sprintf('%s epsUsed=%.6g gap=%.6g', ...
                    msg, selection_trace{k}.eval.gain_meta.eps_used, selection_trace{k}.eval.gain_meta.top_gap);
            end

            if cfg.ch5r.r8.log.show_step_timing
                msg = sprintf('%s stepTime=%.3fs elapsed=%.3fs', msg, toc(t_step), toc(t_total));
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

n_full = [];
n_used = [];
for k = 1:Nt
    if isfield(selection_trace{k}, 'n_pairs_full')
        n_full(end+1,1) = selection_trace{k}.n_pairs_full; %#ok<AGROW>
        n_used(end+1,1) = selection_trace{k}.n_pairs_used; %#ok<AGROW>
    end
end

result.r8 = struct();
result.r8.mean_full_pairs = mean(n_full, 'omitnan');
result.r8.mean_used_pairs = mean(n_used, 'omitnan');
result.r8.mean_prune_ratio = mean(n_used ./ max(n_full,1), 'omitnan');

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR8_weak_prior_compare_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_weak_prior_compare_real_' stamp '.csv']);
md_file = fullfile(out_dir, ['phaseR8_weak_prior_compare_real_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR8_weak_prior_compare_real_' stamp '.mat']);

T = table( ...
    ["R5-real_predictive_pair"; "R8-real_weak_prior_pair"], ...
    [out5.result.bubble_metrics.bubble_time_s; result.bubble_metrics.bubble_time_s], ...
    [out5.result.bubble_metrics.longest_bubble_time_s; result.bubble_metrics.longest_bubble_time_s], ...
    [out5.result.bubble_metrics.mean_bubble_depth; result.bubble_metrics.mean_bubble_depth], ...
    [out5.result.cost_metrics.switch_count; result.cost_metrics.switch_count], ...
    [out5.result.rmse_proxy_metrics.mean_rmse_proxy; result.rmse_proxy_metrics.mean_rmse_proxy], ...
    [NaN; result.r8.mean_full_pairs], ...
    [NaN; result.r8.mean_used_pairs], ...
    [NaN; result.r8.mean_prune_ratio], ...
    'VariableNames', { ...
        'policy', ...
        'bubble_time_s', ...
        'longest_bubble_time_s', ...
        'mean_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_proxy', ...
        'mean_full_pairs', ...
        'mean_used_pairs', ...
        'mean_prune_ratio'});

writetable(T, csv_file);

md = local_build_md(T, csv_file, cfg);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out5', 'ch5case', 'prior', 'selection_trace', 'wininfo', 'bubble', 'result', 'T');

disp(' ')
disp('=== [ch5r:R8-real] weak-prior compare summary ===')
disp(T)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])

out = struct();
out.cfg = cfg;
out.out5 = out5;
out.case = ch5case;
out.prior = prior;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.result = result;
out.summary_table = T;
out.paths = struct('csv_file', csv_file, 'md_file', md_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, csv_file, cfg)
lines = {};
lines{end+1} = '# Phase R8-real Weak-prior Compare Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Role';
lines{end+1} = '';
lines{end+1} = ['This stage compares the current predictive R5 policy ' ...
                'against a weak-prior-enhanced predictive policy with optional candidate pruning ' ...
                'and close-score prior amplification.'];
lines{end+1} = '';
lines{end+1} = '## 2. Config';
lines{end+1} = '';
lines{end+1} = ['- enable_candidate_prune = ', num2str(cfg.ch5r.r8.enable_candidate_prune)];
lines{end+1} = ['- prune_keep_ratio = ', num2str(cfg.ch5r.r8.prune_keep_ratio)];
lines{end+1} = ['- prune_min_keep = ', num2str(cfg.ch5r.r8.prune_min_keep)];
lines{end+1} = ['- enable_close_score_prior = ', num2str(cfg.ch5r.r8.enable_close_score_prior)];
lines{end+1} = ['- close_gap = ', num2str(cfg.ch5r.r8.close_gap)];
lines{end+1} = ['- eps_prior_base = ', num2str(cfg.ch5r.r8.eps_prior_base)];
lines{end+1} = ['- eps_prior_close = ', num2str(cfg.ch5r.r8.eps_prior_close)];
lines{end+1} = '';
lines{end+1} = '## 3. Summary table';
lines{end+1} = '';
lines{end+1} = ['- csv: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '| policy | bubble_time_s | longest_bubble_time_s | mean_bubble_depth | switch_count | mean_rmse_proxy | mean_full_pairs | mean_used_pairs | mean_prune_ratio |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    mf = T.mean_full_pairs(i);
    mu = T.mean_used_pairs(i);
    mr = T.mean_prune_ratio(i);

    mf_text = 'NaN'; mu_text = 'NaN'; mr_text = 'NaN';
    if ~isnan(mf), mf_text = num2str(mf, '%.6f'); end
    if ~isnan(mu), mu_text = num2str(mu, '%.6f'); end
    if ~isnan(mr), mr_text = num2str(mr, '%.6f'); end

    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', num2str(T.mean_rmse_proxy(i), '%.12g'), ...
        ' | ', mf_text, ...
        ' | ', mu_text, ...
        ' | ', mr_text, ' |'];
end
md = strjoin(lines, newline);
end
