function task_family = adapter_casebank_legacy(profile)
% Minimal adapter for legacy scenario/task-family construction.

if nargin < 1
    profile = struct();
end

repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
legacy_root = fullfile(repo_root, 'legacy');

addpath(genpath(fullfile(legacy_root, 'src')));
addpath(genpath(fullfile(legacy_root, 'params')));

cfg = default_params();

casebank = build_casebank_stage01(cfg);

disp('--- adapter_casebank_legacy: casebank fields ---');
disp(fieldnames(casebank));

family_name = 'nominal';
if isfield(profile, 'task_family') && ~isempty(profile.task_family)
    family_name = lower(string(profile.task_family));
end

switch char(family_name)
    case 'nominal'
        case_list = generate_nominal_entry_family(cfg, casebank);
    case 'heading'
        case_list = generate_heading_family(cfg, casebank);
    otherwise
        error('adapter_casebank_legacy:UnsupportedTaskFamily', ...
            'Unsupported task family: %s', family_name);
end

task_family = struct();
task_family.name = char(family_name);
task_family.mode = 'legacy_adapter';
task_family.case_list = case_list;
task_family.case_count = numel(case_list);
task_family.meta = struct('source', 'legacy');
end
