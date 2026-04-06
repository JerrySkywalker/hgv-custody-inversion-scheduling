function out = run_ch5r_phase7_dualloop_compare()
%RUN_CH5R_PHASE7_DUALLOOP_COMPARE
% Minimal real R7:
% compare single-loop R5 vs dual-loop triggered predictive scheduling.

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;
cfg.ch5r.window_mode = 'centered_full_only';
cfg.ch5r.window_exclude_incomplete_edges = true;

cfg.ch5r.r5.horizon_steps = 30;
cfg.ch5r.r5.lambda_sw = 500;
cfg.ch5r.r5.min_hold_steps = 5;
cfg.ch5r.r5.parallel.enable = true;

cfg.ch5r.r7.horizon_steps = 30;
cfg.ch5r.r7.warn_ratio = 1.10;
cfg.ch5r.r7.log.enable = true;
cfg.ch5r.r7.log.log_every = 20;
cfg.ch5r.r7.log.show_step_timing = true;

out5 = run_ch5r_phase5_bubble_predictive(struct( ...
    'window_length_s', 60, ...
    'window_mode', 'centered_full_only', ...
    'window_exclude_incomplete_edges', true, ...
    'horizon_steps', 30, ...
    'lambda_sw', 500, ...
    'min_hold_steps', 5));

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

last_valid_center = Nt - ch5case.window.right_steps;

if cfg.ch5r.r7.log.enable
    disp('=== [R7] Start dual-loop compare scheduling ===')
    disp(['[R7] last_valid_center = ' num2str(last_valid_center)])
end

t_total = tic;
trigger_count = 0;

for k = 1:Nt
    t_step = tic;

    sel = policy_bubble_predictive_with_prior(cfg, ch5case, selection_trace, k);

    if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair') ...
            && ~isempty(selection_trace{k-1}.pair)
        sel.prev_pair = selection_trace{k-1}.pair;
        sel.switch_flag = ~isempty(sel.pair) && ~isequal(sel.pair, selection_trace{k-1}.pair);
    else
        sel.prev_pair = [];
        sel.switch_flag = false;
    end

    if isfield(sel, 'triggered') && sel.triggered
        trigger_count = trigger_count + 1;
    end

    selection_trace{k} = sel;

    if cfg.ch5r.r7.log.enable
        do_log = (k == 1) || (k == Nt) || (mod(k, cfg.ch5r.r7.log.log_every) == 0);
        if do_log
            msg = sprintf('[R7][k=%d/%d] triggered=%d nPairs=%d', ...
                k, Nt, logical(sel.triggered), sel.n_pairs);

            if ~isempty(sel.pair)
                msg = sprintf('%s pair=[%d %d]', msg, sel.pair(1), sel.pair(2));
            else
                msg = sprintf('%s pair=[]', msg);
            end

            if isfield(sel, 'precursor') && isfield(sel.precursor, 'predicted_min_lambda')
                msg = sprintf('%s predMin=%.6g warn=%.6g', ...
                    msg, sel.precursor.predicted_min_lambda, sel.precursor.warn_threshold);
            end

            if cfg.ch5r.r7.log.show_step_timing
                msg = sprintf('%s stepTime=%.3fs elapsed=%.3fs', msg, toc(t_step), toc(t_total));
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

result.dual_loop = struct();
result.dual_loop.trigger_count = trigger_count;
result.dual_loop.trigger_fraction = trigger_count / max(Nt,1);
result.dual_loop.last_valid_center = last_valid_center;

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR7_dualloop_compare_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR7_dualloop_compare_real_' stamp '.mat']);
csv_file = fullfile(out_dir, ['phaseR7_dualloop_compare_real_' stamp '.csv']);
md_file = fullfile(out_dir, ['phaseR7_dualloop_compare_real_' stamp '.md']);

T = table( ...
    ["R5-real_single_loop"; "R7-real_dual_loop"], ...
    [out5.result.bubble_metrics.total_valid_steps; result.bubble_metrics.total_valid_steps], ...
    [out5.result.bubble_metrics.bubble_time_s; result.bubble_metrics.bubble_time_s], ...
    [out5.result.bubble_metrics.longest_bubble_time_s; result.bubble_metrics.longest_bubble_time_s], ...
    [out5.result.bubble_metrics.mean_bubble_depth; result.bubble_metrics.mean_bubble_depth], ...
    [out5.result.cost_metrics.switch_count; result.cost_metrics.switch_count], ...
    [NaN; trigger_count], ...
    'VariableNames', { ...
        'policy', ...
        'valid_steps', ...
        'bubble_time_s', ...
        'longest_bubble_time_s', ...
        'mean_bubble_depth', ...
        'switch_count', ...
        'trigger_count'});

writetable(T, csv_file);

md = local_build_md(T, csv_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out5', 'ch5case', 'selection_trace', 'wininfo', 'bubble', 'state_trace', 'result', 'T');

disp(' ')
disp('=== [ch5r:R7-real] dual-loop compare summary ===')
disp(T)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])

out = struct();
out.cfg = cfg;
out.out5 = out5;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.summary_table = T;
out.paths = struct('csv_file', csv_file, 'md_file', md_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, csv_file)
lines = {};
lines{end+1} = '# Phase R7-real Dual-loop Compare Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Role';
lines{end+1} = '';
lines{end+1} = ['This stage compares the current single-loop predictive R5 policy ' ...
                'against a minimal dual-loop shell with precursor triggering.'];
lines{end+1} = '';
lines{end+1} = '## 2. Summary table';
lines{end+1} = '';
lines{end+1} = ['- csv: `', csv_file, '`'];
lines{end+1} = '';
lines{end+1} = '| policy | valid_steps | bubble_time_s | longest_bubble_time_s | mean_bubble_depth | switch_count | trigger_count |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    trig = T.trigger_count(i);
    trig_text = 'NaN';
    if ~isnan(trig)
        trig_text = num2str(trig);
    end
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.valid_steps(i)), ...
        ' | ', num2str(T.bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.longest_bubble_time_s(i), '%.6f'), ...
        ' | ', num2str(T.mean_bubble_depth(i), '%.12g'), ...
        ' | ', num2str(T.switch_count(i)), ...
        ' | ', trig_text, ' |'];
end
md = strjoin(lines, newline);
end
