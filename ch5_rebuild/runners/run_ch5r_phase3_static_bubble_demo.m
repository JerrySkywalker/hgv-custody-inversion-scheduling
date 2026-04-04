function out = run_ch5r_phase3_static_bubble_demo()
%RUN_CH5R_PHASE3_STATIC_BUBBLE_DEMO
% Formal R3 baseline demo using static-hold policy.

cfg = default_ch5r_params();
ch5case = build_ch5r_case(cfg);
policy = policy_static_hold(cfg, ch5case);

N = numel(ch5case.time_s);
selection_trace = cell(N, 1);
for k = 1:N
    selection_trace{k} = select_satellite_set_static(policy, k);
end

wininfo = eval_window_information(ch5case);
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

phase1_like = struct();
phase1_like.cfg = cfg;
phase1_like.case = ch5case;
phase1_like.wininfo = wininfo;
phase1_like.bubble = bubble;
phase1_like.state_trace = state_trace;
phase1_like.ok = true;

result = package_ch5r_result(phase1_like, policy, selection_trace);

out_dir = cfg.ch5r.output_dirs.phaseR3;
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR3_static_hold_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR3_static_hold_' stamp '.md']);

fig_timeline = plot_bubble_timeline(state_trace, out_dir, stamp);
fig_failure = plot_static_failure_case(result, out_dir, stamp);

summary_md = local_build_summary_md(cfg, ch5case, policy, result, fig_timeline, fig_failure);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', summary_md);

save(mat_file, 'cfg', 'ch5case', 'policy', 'selection_trace', 'wininfo', 'bubble', 'state_trace', 'result', 'fig_timeline', 'fig_failure');

disp(' ')
disp('=== [ch5r:R3] static-hold baseline summary ===')
disp(['policy name          : ' policy.name])
disp(['case id              : ' ch5case.target_case.case_id])
disp(['theta_star Ns        : ' num2str(ch5case.theta.Ns)])
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['min req margin       : ' num2str(result.requirement.min_margin, '%.12g')])
disp(['req violation steps  : ' num2str(result.requirement.total_violation_steps)])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

assert(strcmp(policy.name, 'static_hold'));
assert(result.bubble_metrics.bubble_steps > 0);
assert(result.requirement.total_violation_steps > 0);

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.policy = policy;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'timeline_png', fig_timeline, ...
    'failure_png', fig_failure, ...
    'output_dir', out_dir);
out.ok = true;

disp('[ch5r:R3] static-hold baseline passed.')
end

function md = local_build_summary_md(cfg, ch5case, policy, result, fig_timeline, fig_failure)
bm = result.bubble_metrics;
cm = result.custody_metrics;
rm = result.rmse_metrics;
rq = result.requirement;
if isfield(result, 'cost_metrics')
    ct = result.cost_metrics;
else
    ct = struct();
end

lines = {};
lines{end+1} = '# Phase R3 Static-Hold Baseline Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Experiment role';
lines{end+1} = '';
lines{end+1} = ['This run establishes the first formal Chapter 5 baseline policy: ' ...
    '`static_hold`.'];
lines{end+1} = '';
lines{end+1} = '## 2. Baseline policy';
lines{end+1} = '';
lines{end+1} = ['- policy: `', policy.name, '`'];
lines{end+1} = ['- case id: `', ch5case.target_case.case_id, '`'];
lines{end+1} = ['- theta_star: h=', num2str(ch5case.theta.h_km), ...
    ' km, i=', num2str(ch5case.theta.i_deg), ...
    ' deg, P=', num2str(ch5case.theta.P), ...
    ', T=', num2str(ch5case.theta.T), ...
    ', F=', num2str(ch5case.theta.F), ...
    ', Ns=', num2str(ch5case.theta.Ns)];
lines{end+1} = ['- gamma_req: ', num2str(ch5case.gamma_req, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 3. Bubble metrics';
lines{end+1} = '';
lines{end+1} = ['- bubble_steps: ', num2str(bm.bubble_steps)];
lines{end+1} = ['- bubble_fraction: ', num2str(bm.bubble_fraction, '%.6f')];
lines{end+1} = ['- bubble_time_s: ', num2str(bm.bubble_time_s, '%.6f')];
lines{end+1} = ['- longest_bubble_time_s: ', num2str(bm.longest_bubble_time_s, '%.6f')];
lines{end+1} = ['- max_bubble_depth: ', num2str(bm.max_bubble_depth, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 4. Custody metrics';
lines{end+1} = '';
lines{end+1} = ['- loc_total_steps: ', num2str(cm.loc_total_steps)];
lines{end+1} = ['- loc_total_time_s: ', num2str(cm.loc_total_time_s, '%.6f')];
lines{end+1} = ['- longest_loc_time_s: ', num2str(cm.longest_loc_time_s, '%.6f')];
lines{end+1} = ['- custody_ratio: ', num2str(cm.custody_ratio, '%.6f')];
lines{end+1} = '';
lines{end+1} = '## 5. RMSE proxy';
lines{end+1} = '';
lines{end+1} = ['- mean_rmse: ', num2str(rm.mean_rmse, '%.12g')];
lines{end+1} = ['- max_rmse: ', num2str(rm.max_rmse, '%.12g')];
lines{end+1} = '';
lines{end+1} = '## 6. Requirement proxy';
lines{end+1} = '';
lines{end+1} = ['- min_margin: ', num2str(rq.min_margin, '%.12g')];
lines{end+1} = ['- mean_margin: ', num2str(rq.mean_margin, '%.12g')];
lines{end+1} = ['- total_violation_steps: ', num2str(rq.total_violation_steps)];
lines{end+1} = '';
lines{end+1} = '## 7. Cost metrics';
lines{end+1} = '';
if ~isempty(fieldnames(ct))
    lines{end+1} = ['- switch_count: ', num2str(ct.switch_count)];
    lines{end+1} = ['- resource_score: ', num2str(ct.resource_score, '%.6f')];
else
    lines{end+1} = '- switch_count: N/A';
    lines{end+1} = '- resource_score: N/A';
end
lines{end+1} = '';
lines{end+1} = '## 8. Figures';
lines{end+1} = '';
lines{end+1} = ['- bubble timeline: `', fig_timeline, '`'];
lines{end+1} = ['- static failure case: `', fig_failure, '`'];
lines{end+1} = '';
lines{end+1} = '## 9. Interpretation';
lines{end+1} = '';
lines{end+1} = ['The current R3 baseline still uses the minimal synthetic information case. ' ...
    'Its primary role is to formalize static-hold as the first reusable policy-level baseline ' ...
    'and produce a standard result bundle for later comparison against tracking-greedy.'];
lines{end+1} = '';
md = strjoin(lines, newline);
end
