function task_family = task_family_service(cfg)
profile = cfg.profile;
family_spec = struct();

if isfield(profile, 'task_family') && ~isempty(profile.task_family)
    family_spec.family_name = char(string(profile.task_family));
else
    family_spec.family_name = 'nominal';
end

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_cases')
    family_spec.max_cases = cfg.runtime.max_cases;
end

if isfield(profile, 'allowed_heading_offsets_deg')
    family_spec.allowed_heading_offsets_deg = profile.allowed_heading_offsets_deg;
end

if isfield(profile, 'heading_offsets_deg')
    family_spec.heading_offsets_deg = profile.heading_offsets_deg;
end

if isfield(profile, 'nominal_case_count')
    family_spec.nominal_case_count = profile.nominal_case_count;
end

task_family = build_task_family(family_spec, cfg.engine_cfg);
task_family.mode = 'framework_trajs_in';
task_family.meta = struct('source', 'framework');
end
