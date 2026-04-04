function out = run_ch5r_phase8_weak_prior_compare()
%RUN_CH5R_PHASE8_WEAK_PRIOR_COMPARE
% Minimal real R8:
% compare R5-real vs weak-prior-enhanced predictive scheduling.

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;

cfg.ch5r.r5 = struct();
cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 500;
cfg.ch5r.r5.min_hold_steps = 5;
cfg.ch5r.r5.parallel = struct('enable', true);

cfg.ch5r.r8 = struct();
cfg.ch5r.r8.eps_prior = 1e-3;

out5 = run_ch5r_phase5_bubble_predictive();

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;
prior = build_static_weak_prior(cfg, ch5case);

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

disp('=== [R8] Start weak-prior compare scheduling ===')

hold_countdown = 0;
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
            'name', 'weak_prior_empty', ...
            'n_pairs', 0);
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
            'n_pairs', size(ch5case.candidates.pair_bank{k},1));
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
    'VariableNames', { ...
        'policy', ...
        'bubble_time_s', ...
        'longest_bubble_time_s', ...
        'mean_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_proxy'});

writetable(T, csv_file);

md = local_build_md(T, csv_file);
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

function md = local_build_md(T, csv_file)
lines = {};
lines{end+1} = '# Phase R8-real Weak-prior Compare Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Role';
lines{end+1} = '';
lines{end+1} = ['This stage compares the current predictive R5 policy ' ...
                'against a weak-prior-enhanced predictive policy.'];
lines{end+1} = '';
lines{end+1} = '## 2. Summary table';
lines{end+1} = '';
lines{end+1} = ['- csv: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '| policy | bubble_time_s | longest_bubble_time_s | mean_bubble_depth | switch_count | mean_rmse_proxy |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', num2str(T.mean_rmse_proxy(i), '%.12g'), ' |'];
end
md = strjoin(lines, newline);
end
