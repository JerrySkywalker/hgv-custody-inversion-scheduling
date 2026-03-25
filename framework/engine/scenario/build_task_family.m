function task_family = build_task_family(family_spec, engine_cfg)
%BUILD_TASK_FAMILY Build a generic task family from the scenario casebank.
% Inputs:
%   family_spec : string or struct describing family selection
%   engine_cfg  : engine configuration tree; defaults to default_params()
%
% Output:
%   task_family : struct with name, case_count, case_list, trajs_in, summary

if nargin < 2 || isempty(engine_cfg)
    engine_cfg = default_params();
end

spec = local_normalize_family_spec(family_spec);
casebank = build_casebank(engine_cfg);

switch lower(spec.family_name)
    case 'nominal'
        selected_cases = casebank.nominal;
        if ~isempty(spec.max_cases)
            selected_cases = selected_cases(1:min(spec.max_cases, numel(selected_cases)));
        end
        trajs_in = propagate_target_family(selected_cases, engine_cfg);

    case 'heading'
        nominal_cases = casebank.nominal;
        if isempty(nominal_cases)
            error('build_task_family:EmptyNominalCasebank', ...
                'Heading family requires at least one nominal case.');
        end

        if isempty(spec.nominal_case_count)
            spec.nominal_case_count = 1;
        end
        n_nominal = min(spec.nominal_case_count, numel(nominal_cases));
        nominal_cases = nominal_cases(1:n_nominal);
        nominal_family = propagate_target_family(nominal_cases, engine_cfg);

        nominal_case_bank = reshape([nominal_family.case], size(nominal_family));
        nominal_traj_bank = reshape([nominal_family.traj], size(nominal_family));

        if isempty(spec.heading_offsets_deg)
            if isfield(casebank, 'meta') && isfield(casebank.meta, 'heading_offsets_deg')
                spec.heading_offsets_deg = casebank.meta.heading_offsets_deg;
            else
                spec.heading_offsets_deg = [0, -30, 30];
            end
        end

        trajs_in = build_heading_family( ...
            nominal_case_bank, nominal_traj_bank, spec.heading_offsets_deg, engine_cfg);

    case 'critical'
        selected_cases = casebank.critical;
        if ~isempty(spec.max_cases)
            selected_cases = selected_cases(1:min(spec.max_cases, numel(selected_cases)));
        end
        trajs_in = propagate_target_family(selected_cases, engine_cfg);

    otherwise
        error('build_task_family:UnsupportedFamily', ...
            'Unsupported family_name: %s', spec.family_name);
end

task_family = struct();
task_family.name = spec.family_name;
task_family.family_name = spec.family_name;
task_family.spec = spec;
task_family.casebank = casebank;
task_family.trajs_in = trajs_in;

task_family = subset_task_family(task_family, spec);
task_family.case_count = numel(task_family.trajs_in);
task_family.case_list = local_extract_case_list(task_family.trajs_in);
task_family.summary = summarize_task_family(task_family);
end

function spec = local_normalize_family_spec(family_spec)
if nargin < 1 || isempty(family_spec)
    family_spec = struct();
end

if ischar(family_spec) || isstring(family_spec)
    spec = struct('family_name', char(string(family_spec)));
else
    spec = family_spec;
end

if isfield(spec, 'task_family') && ~isfield(spec, 'family_name')
    spec.family_name = char(string(spec.task_family));
end
if ~isfield(spec, 'family_name') || isempty(spec.family_name)
    spec.family_name = 'nominal';
end
if ~isfield(spec, 'max_cases') || isempty(spec.max_cases)
    spec.max_cases = [];
end
if ~isfield(spec, 'allowed_heading_offsets_deg')
    spec.allowed_heading_offsets_deg = [];
end
if ~isfield(spec, 'heading_offsets_deg')
    spec.heading_offsets_deg = [];
end
if ~isfield(spec, 'case_ids')
    spec.case_ids = {};
end
if ~isfield(spec, 'nominal_case_count') || isempty(spec.nominal_case_count)
    spec.nominal_case_count = [];
end
end

function case_list = local_extract_case_list(trajs_in)
case_list = cell(numel(trajs_in), 1);
for k = 1:numel(trajs_in)
    if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'case_id')
        case_list{k} = trajs_in(k).case.case_id;
    else
        case_list{k} = sprintf('case_%d', k);
    end
end
end
