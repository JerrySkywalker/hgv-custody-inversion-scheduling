function task_family = task_family_service(cfg)
profile = cfg.profile;

family_name = 'nominal';
if isfield(profile, 'task_family') && ~isempty(profile.task_family)
    family_name = char(string(profile.task_family));
end

cfg_legacy = default_params();
casebank = build_casebank_stage01(cfg_legacy);

switch lower(family_name)
    case 'nominal'
        trajs_in = build_nominal_trajs_in(casebank, cfg);
        case_list = extract_case_ids_from_trajs_in(trajs_in);

    case 'heading'
        trajs_in = build_heading_trajs_in(casebank, cfg);
        trajs_in = apply_heading_offset_filter_if_needed(trajs_in, profile, cfg);
        case_list = extract_case_ids_from_trajs_in(trajs_in);

    otherwise
        error('task_family_service:UnsupportedFamily', ...
            'Unsupported task family: %s', family_name);
end

task_family = struct();
task_family.name = family_name;
task_family.mode = 'legacy_trajs_in';
task_family.case_list = case_list;
task_family.case_count = numel(trajs_in);
task_family.trajs_in = trajs_in;
task_family.meta = struct();
task_family.meta.source = 'legacy';
end

function trajs_in = build_nominal_trajs_in(casebank, cfg)
cfg_legacy = default_params();
entry = pick_first_nominal_case(casebank.nominal);

trajs_in = struct('case', {}, 'traj', {});
k = 1;

case_item = entry;
traj = propagate_hgv_case_stage02(case_item, cfg_legacy);

trajs_in(k).case = case_item;
trajs_in(k).traj = traj;

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_cases')
    n = min(cfg.runtime.max_cases, numel(trajs_in));
    trajs_in = trajs_in(1:n);
end
end

function trajs_in = build_heading_trajs_in(casebank, ~)
cfg_legacy = default_params();
heading_offsets = [0, -30, 30];

nominal_entry = pick_first_nominal_case(casebank.nominal);
trajs_in = struct('case', {}, 'traj', {});
k = 0;

for i = 1:numel(heading_offsets)
    k = k + 1;
    case_item = nominal_entry;
    case_item.case_id = sprintf('H01_%+03d', heading_offsets(i));
    case_item.family = 'heading';
    case_item.subfamily = 'heading_small';
    case_item.heading_offset_deg = heading_offsets(i);

    traj = propagate_hgv_case_stage02(case_item, cfg_legacy);

    trajs_in(k).case = case_item;
    trajs_in(k).traj = traj;
end
end

function trajs_out = apply_heading_offset_filter_if_needed(trajs_in, profile, cfg)
trajs_out = trajs_in;

if ~isfield(profile, 'allowed_heading_offsets_deg') || isempty(profile.allowed_heading_offsets_deg)
    % no-op
else
    allowed = profile.allowed_heading_offsets_deg;
    keep_mask = false(numel(trajs_in), 1);

    for k = 1:numel(trajs_in)
        case_k = trajs_in(k).case;
        if isfield(case_k, 'heading_offset_deg')
            keep_mask(k) = any(case_k.heading_offset_deg == allowed);
        end
    end

    trajs_out = trajs_in(keep_mask);

    if isempty(trajs_out)
        error('task_family_service:EmptyHeadingSelection', ...
            'Heading offset filter removed all heading cases.');
    end
end

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_cases')
    n = min(cfg.runtime.max_cases, numel(trajs_out));
    trajs_out = trajs_out(1:n);
end
end

function case_list = extract_case_ids_from_trajs_in(trajs_in)
case_list = cell(numel(trajs_in), 1);
for k = 1:numel(trajs_in)
    case_item = trajs_in(k).case;
    if isfield(case_item, 'case_id')
        case_list{k} = case_item.case_id;
    else
        case_list{k} = sprintf('case_%d', k);
    end
end
end

function case_item = pick_first_nominal_case(nominal_entry)
if isstruct(nominal_entry)
    case_item = nominal_entry(1);
else
    error('task_family_service:InvalidNominalEntry', ...
        'casebank.nominal must be a struct or struct array.');
end
end
