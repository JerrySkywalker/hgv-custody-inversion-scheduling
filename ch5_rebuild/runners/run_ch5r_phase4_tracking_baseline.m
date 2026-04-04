function out = run_ch5r_phase4_tracking_baseline()
%RUN_CH5R_PHASE4_TRACKING_BASELINE  Minimal R4b tracking-greedy baseline.

cfg = default_ch5r_params();
ch5case = build_ch5r_case(cfg);
policy = policy_tracking_greedy(cfg, ch5case);

N = numel(ch5case.time_s);
selection_trace = cell(N, 1);
for k = 1:N
    selection_trace{k} = select_satellite_set_tracking_greedy(policy, k);
end

% R4b change:
% apply policy-dependent gain to the synthetic information series so that
% tracking_greedy can actually affect bubble metrics.
ch5case_r4 = ch5case;
ch5case_r4.info_series = apply_policy_to_info_series(ch5case, selection_trace);

wininfo = eval_window_information(ch5case_r4);
bubble = eval_bubble_state(ch5case_r4, wininfo);
state_trace = package_state_trace(ch5case_r4, wininfo, bubble);

phase_like = struct();
phase_like.cfg = cfg;
phase_like.case = ch5case_r4;
phase_like.wininfo = wininfo;
phase_like.bubble = bubble;
phase_like.state_trace = state_trace;
phase_like.ok = true;

result = package_ch5r_result(phase_like, policy, selection_trace);

out_dir = cfg.ch5r.output_dirs.phaseR4;
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR4_tracking_baseline_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR4_tracking_baseline_' stamp '.md']);

save(mat_file, 'cfg', 'ch5case', 'ch5case_r4', 'policy', 'selection_trace', 'wininfo', 'bubble', 'state_trace', 'result');

summary_md = local_build_summary_md(ch5case_r4, policy, result);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', summary_md);

disp(' ')
disp('=== [ch5r:R4] tracking-greedy baseline summary ===')
disp(['policy name          : ' policy.name])
disp(['case id              : ' ch5case_r4.target_case.case_id])
disp(['tau_track            : ' num2str(policy.tau_track, '%.12g')])
disp(['bubble fraction      : ' num2str(result.bubble_metrics.bubble_fraction, '%.6f')])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(result.cost_metrics.switch_count)])
disp(['resource score       : ' num2str(result.cost_metrics.resource_score, '%.6f')])
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

assert(strcmp(policy.name, 'tracking_greedy'));
assert(result.cost_metrics.switch_count > 0, 'R4b expects nonzero switch count.');

out = struct();
out.cfg = cfg;
out.case = ch5case_r4;
out.policy = policy;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.paths = struct('mat_file', mat_file, 'md_file', md_file, 'output_dir', out_dir);
out.ok = true;

disp('[ch5r:R4] tracking-greedy baseline passed.')
end

function md = local_build_summary_md(ch5case, policy, result)
bm = result.bubble_metrics;
ct = result.cost_metrics;
rq = result.requirement;

lines = {};
lines{end+1} = '# Phase R4 Tracking-Greedy Baseline Summary';
lines{end+1} = '';
lines{end+1} = ['- policy: `', policy.name, '`'];
lines{end+1} = ['- case id: `', ch5case.target_case.case_id, '`'];
lines{end+1} = ['- tau_track: ', num2str(policy.tau_track, '%.12g')];
lines{end+1} = ['- bubble_fraction: ', num2str(bm.bubble_fraction, '%.6f')];
lines{end+1} = ['- bubble_time_s: ', num2str(bm.bubble_time_s, '%.6f')];
lines{end+1} = ['- longest_bubble_time_s: ', num2str(bm.longest_bubble_time_s, '%.6f')];
lines{end+1} = ['- max_bubble_depth: ', num2str(bm.max_bubble_depth, '%.12g')];
lines{end+1} = ['- min_margin: ', num2str(rq.min_margin, '%.12g')];
lines{end+1} = ['- switch_count: ', num2str(ct.switch_count)];
lines{end+1} = ['- resource_score: ', num2str(ct.resource_score, '%.6f')];
lines{end+1} = '';
lines{end+1} = ['Current note: this R4b run is still proxy-based, but now the ' ...
    'tracking-greedy selection trace feeds back into the information proxy.'];
md = strjoin(lines, newline);
end
