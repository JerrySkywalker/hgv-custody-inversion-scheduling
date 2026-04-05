function out = run_ch5r_phase8_5a_li_method_smoke()
%RUN_CH5R_PHASE8_5A_LI_METHOD_SMOKE
% R8.5a:
%   Reproduce Li-style method interfaces under current ch5r experiment parameters.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

li_case = build_r85_li_case_from_current_case(cfg);
registry = li_case.registry;

summary = struct();
summary.phase_name = string(cfg.r85.phase_name);
summary.method_family = string(cfg.r85.method_family);
summary.scene_policy = string(cfg.r85.scene_policy);
summary.case_id = string(li_case.meta.case_id);
summary.family = string(li_case.meta.family);
summary.dt = li_case.meta.dt;
summary.n_steps = li_case.meta.n_steps;
summary.window_length_s = li_case.meta.window_length_s;
summary.window_length_steps = li_case.meta.window_length_steps;
summary.gamma_req = li_case.meta.gamma_req;
summary.sats_per_interval = li_case.resource.sats_per_interval;
summary.interval_s = li_case.resource.interval_s;
summary.interval_steps = li_case.resource.interval_steps;
summary.sigma_angle_deg = li_case.sensor.sigma_angle_deg;
summary.sigma_angle_rad = li_case.sensor.sigma_angle_rad;
summary.max_range_km = li_case.sensor.max_range_km;
summary.fov_deg = li_case.sensor.fov_deg;
summary.off_nadir_deg = li_case.sensor.off_nadir_deg;
summary.n_modes = numel(registry.modes);
summary.n_selection_criteria = numel(registry.selection);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_5a_li_method_smoke');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR8_5a_li_method_smoke_' stamp '.mat']);
md_file = fullfile(out_dir, ['phaseR8_5a_li_method_smoke_' stamp '.md']);

save(mat_file, 'cfg', 'li_case', 'registry', 'summary');

md = local_build_md(summary, registry, mat_file);
fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file: %s', md_file);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', md);

disp(' ')
disp('=== [ch5r:R8.5a] Li-style method interface smoke summary ===')
disp(summary)
disp('--- modes ---')
disp(string({registry.modes.name})')
disp('--- relay selection criteria ---')
disp(string({registry.selection.name})')
disp(['mat file             : ' mat_file])
disp(['md file              : ' md_file])

out = struct();
out.cfg = cfg;
out.li_case = li_case;
out.registry = registry;
out.summary = summary;
out.paths = struct( ...
    'mat_file', mat_file, ...
    'md_file', md_file, ...
    'output_dir', out_dir);
out.ok = true;
end

function md = local_build_md(summary, registry, mat_file)
lines = {};
lines{end+1} = '# Phase R8.5a Li-style method interface smoke';
lines{end+1} = '';
fns = fieldnames(summary);
for i = 1:numel(fns)
    v = summary.(fns{i});
    if (isnumeric(v) || islogical(v)) && isscalar(v)
        lines{end+1} = ['- ', fns{i}, ' = ', num2str(v, '%.12g')];
    elseif isstring(v) && isscalar(v)
        lines{end+1} = ['- ', fns{i}, ' = ', char(v)];
    end
end
lines{end+1} = '';
lines{end+1} = '## modes';
for i = 1:numel(registry.modes)
    lines{end+1} = ['- ', registry.modes(i).name, ' -> ', registry.modes(i).entry];
end
lines{end+1} = '';
lines{end+1} = '## relay selection criteria';
for i = 1:numel(registry.selection)
    lines{end+1} = ['- ', registry.selection(i).name, ' -> ', registry.selection(i).entry];
end
lines{end+1} = '';
lines{end+1} = ['- mat file: `', mat_file, '`'];
md = strjoin(lines, newline);
end
