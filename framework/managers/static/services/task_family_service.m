function task_family = task_family_service(cfg)
if nargin < 1
    cfg = struct();
end

profile = struct();
if isfield(cfg, 'profile')
    profile = cfg.profile;
end

task_family = adapter_casebank_legacy(profile);

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_cases')
    n = min(cfg.runtime.max_cases, task_family.case_count);
    task_family.case_list = task_family.case_list(1:n);
    task_family.case_count = n;
end
end
