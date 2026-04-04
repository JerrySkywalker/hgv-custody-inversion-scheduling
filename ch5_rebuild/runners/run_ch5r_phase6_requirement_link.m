function out = run_ch5r_phase6_requirement_link()
%RUN_CH5R_PHASE6_REQUIREMENT_LINK
% Minimal real R6:
% compare requirement-risk proxy consequences for R4-real and R5-real.

cfg = default_ch5r_params(true);

out4 = run_ch5r_phase4_tracking_baseline();
out5 = run_ch5r_phase5_bubble_predictive();

req4 = analyze_bubble_to_requirement_chain(out4);
req5 = analyze_bubble_to_requirement_chain(out5);

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR6_requirement_link_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

fig4a = plot_bubble_to_requirement_chain_real(out4, req4, out_dir, [stamp '_R4']);
fig4b = plot_requirement_margin_vs_bubble_real(out4, req4, out_dir, [stamp '_R4']);
fig5a = plot_bubble_to_requirement_chain_real(out5, req5, out_dir, [stamp '_R5']);
fig5b = plot_requirement_margin_vs_bubble_real(out5, req5, out_dir, [stamp '_R5']);

T = table( ...
    ["R4-real_dynamic_pair"; "R5-real_predictive_pair"], ...
    [req4.total_violation_steps; req5.total_violation_steps], ...
    [req4.total_violation_time_s; req5.total_violation_time_s], ...
    [req4.violation_fraction; req5.violation_fraction], ...
    [req4.min_margin_proxy; req5.min_margin_proxy], ...
    [req4.mean_margin_proxy; req5.mean_margin_proxy], ...
    [req4.coincidence_ratio; req5.coincidence_ratio], ...
    'VariableNames', { ...
        'policy', ...
        'req_violation_steps', ...
        'req_violation_time_s', ...
        'req_violation_fraction', ...
        'min_margin_proxy', ...
        'mean_margin_proxy', ...
        'bubble_req_coincidence_ratio'});

csv_file = fullfile(out_dir, ['phaseR6_requirement_link_' stamp '.csv']);
writetable(T, csv_file);

md_file = fullfile(out_dir, ['phaseR6_requirement_link_' stamp '.md']);
mat_file = fullfile(out_dir, ['phaseR6_requirement_link_' stamp '.mat']);

md = local_build_md(T, req4, req5, csv_file, fig4a, fig4b, fig5a, fig5b);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

save(mat_file, 'cfg', 'out4', 'out5', 'req4', 'req5', 'T');

disp(' ')
disp('=== [ch5r:R6-real] requirement-link summary ===')
disp(T)
disp(['csv file            : ' csv_file])
disp(['md file             : ' md_file])
disp(['mat file            : ' mat_file])

out = struct();
out.cfg = cfg;
out.out4 = out4;
out.out5 = out5;
out.req4 = req4;
out.req5 = req5;
out.summary_table = T;
out.paths = struct( ...
    'csv_file', csv_file, ...
    'md_file', md_file, ...
    'mat_file', mat_file, ...
    'fig_r4_chain', fig4a, ...
    'fig_r4_margin', fig4b, ...
    'fig_r5_chain', fig5a, ...
    'fig_r5_margin', fig5b, ...
    'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(T, req4, req5, csv_file, fig4a, fig4b, fig5a, fig5b)
lines = {};
lines{end+1} = '# Phase R6-real Requirement-Link Summary';
lines{end+1} = '';
lines{end+1} = '## 1. Purpose';
lines{end+1} = '';
lines{end+1} = ['This stage builds the minimal real-line bridge from bubble occurrence ' ...
                'to requirement-risk violation.'];
lines{end+1} = '';
lines{end+1} = '## 2. Interpretation note';
lines{end+1} = '';
lines{end+1} = ['Current requirement-link analysis is proxy-based. It does NOT yet use ' ...
                'full covariance projection P_r = C_r P C_r^T from a closed-loop filter.'];
lines{end+1} = '';
lines{end+1} = '## 3. Key findings';
lines{end+1} = '';
lines{end+1} = ['- R4 req violation time = ', num2str(req4.total_violation_time_s, '%.6f'), ' s'];
lines{end+1} = ['- R5 req violation time = ', num2str(req5.total_violation_time_s, '%.6f'), ' s'];
lines{end+1} = ['- R4 coincidence ratio  = ', num2str(req4.coincidence_ratio, '%.6f')];
lines{end+1} = ['- R5 coincidence ratio  = ', num2str(req5.coincidence_ratio, '%.6f')];
lines{end+1} = '';
lines{end+1} = '## 4. Artifacts';
lines{end+1} = '';
lines{end+1} = ['- csv: `', csv_file, '`'];
lines{end+1} = ['- R4 chain figure: `', fig4a, '`'];
lines{end+1} = ['- R4 margin figure: `', fig4b, '`'];
lines{end+1} = ['- R5 chain figure: `', fig5a, '`'];
lines{end+1} = ['- R5 margin figure: `', fig5b, '`'];
lines{end+1} = '';
lines{end+1} = '## 5. Summary table';
lines{end+1} = '';
lines{end+1} = '| policy | req_violation_steps | req_violation_time_s | req_violation_fraction | min_margin_proxy | mean_margin_proxy | bubble_req_coincidence_ratio |';
lines{end+1} = '|---|---:|---:|---:|---:|---:|---:|';
for i = 1:height(T)
    lines{end+1} = ['| ', char(T.policy(i)), ...
        ' | ', num2str(T.req_violation_steps(i)), ...
        ' | ', num2str(T.req_violation_time_s(i), '%.6f'), ...
        ' | ', num2str(T.req_violation_fraction(i), '%.6f'), ...
        ' | ', num2str(T.min_margin_proxy(i), '%.12g'), ...
        ' | ', num2str(T.mean_margin_proxy(i), '%.12g'), ...
        ' | ', num2str(T.bubble_req_coincidence_ratio(i), '%.6f'), ' |'];
end

md = strjoin(lines, newline);
end
