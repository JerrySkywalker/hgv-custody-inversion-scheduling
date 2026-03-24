function task_family = task_family_service(cfg)
if nargin < 1
    cfg = struct();
end

profile = struct();
if isfield(cfg, 'profile')
    profile = cfg.profile;
end

legacy_family = adapter_casebank_legacy(profile);
raw_cases = legacy_family.case_list;

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_cases')
    n = min(cfg.runtime.max_cases, numel(raw_cases));
    raw_cases = raw_cases(1:n);
else
    n = numel(raw_cases);
end

repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
legacy_root = fullfile(repo_root, 'legacy');

addpath(genpath(fullfile(legacy_root, 'src')));
addpath(genpath(fullfile(legacy_root, 'params')));

cfg_legacy = default_params();

trajs_in = repmat(struct('case', struct(), 'traj', struct()), n, 1);

for k = 1:n
    case_item = raw_cases{k};

    hgv_cfg = build_hgv_cfg_from_case_stage02(case_item, cfg_legacy);
    traj = propagate_hgv_case_stage02(hgv_cfg, cfg_legacy);

    trajs_in(k).case = case_item;
    trajs_in(k).traj = traj;
end

task_family = struct();
task_family.name = legacy_family.name;
task_family.mode = 'legacy_trajs_in';
task_family.case_list = raw_cases;
task_family.case_count = n;
task_family.trajs_in = trajs_in;
task_family.meta = struct('source', 'legacy');
end
