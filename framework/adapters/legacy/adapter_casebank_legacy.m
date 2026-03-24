function task_family = adapter_casebank_legacy(profile)
% Minimal adapter for legacy scenario/task-family construction.
% Use prebuilt legacy casebank entries directly as task cases.

if nargin < 1
    profile = struct();
end

repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
legacy_root = fullfile(repo_root, 'legacy');

addpath(genpath(fullfile(legacy_root, 'src')));
addpath(genpath(fullfile(legacy_root, 'params')));

cfg = default_params();
casebank = build_casebank_stage01(cfg);

family_name = 'nominal';
if isfield(profile, 'task_family') && ~isempty(profile.task_family)
    family_name = lower(string(profile.task_family));
end

switch char(family_name)
    case 'nominal'
        raw_cases = casebank.nominal;

    case 'heading'
        raw_cases = casebank.heading;

    case 'critical'
        raw_cases = casebank.critical;

    otherwise
        error('adapter_casebank_legacy:UnsupportedTaskFamily', ...
            'Unsupported task family: %s', family_name);
end

% Normalize to cell array of structs
if isstruct(raw_cases)
    if numel(raw_cases) == 1
        case_list = {raw_cases};
    else
        case_list = arrayfun(@(s) s, raw_cases, 'UniformOutput', false);
    end
elseif iscell(raw_cases)
    case_list = raw_cases;
else
    error('adapter_casebank_legacy:UnexpectedCaseType', ...
        'Unexpected raw_cases type: %s', class(raw_cases));
end

task_family = struct();
task_family.name = char(family_name);
task_family.mode = 'legacy_casebank';
task_family.case_list = case_list;
task_family.case_count = numel(case_list);
task_family.meta = struct('source', 'legacy');
end
