function selection = milestone_common_case_selection(cfg, milestone_id, overrides)
%MILESTONE_COMMON_CASE_SELECTION Resolve milestone case selection against real casebank IDs.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end
if nargin < 2 || isempty(milestone_id)
    milestone_id = 'MA';
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_defaults(cfg);
stage01_out = stage01_scenario_disk(cfg);
casebank = stage01_out.casebank;

[case_list, family_list, family_index, case_structs] = local_flatten_casebank(casebank);

selection = struct();
selection.milestone_id = string(milestone_id);
selection.case_set = string(cfg.milestones.case_set);
selection.available_case_ids = case_list;
selection.available_case_families = family_list;
selection.case_id = "";
selection.case_family = "";
selection.case_index = NaN;
selection.case_exists = false;
selection.case_label = "";
selection.case_mode = "";
selection.case_struct = struct();
selection.casebank = casebank;

request = local_pick_request(cfg, milestone_id, overrides);
[idx, resolved_mode] = local_resolve_case_index(request, case_list, family_list);

selection.case_mode = string(resolved_mode);
selection.case_label = string(request.case_label);
selection.requested_case_id = string(request.case_id);
selection.requested_case_mode = string(request.case_mode);

if ~isnan(idx)
    selection.case_id = case_list(idx);
    selection.case_family = family_list(idx);
    selection.case_index = family_index(idx);
    selection.case_exists = true;
    selection.case_struct = case_structs{idx};
    if strlength(selection.case_label) == 0
        selection.case_label = selection.case_id;
    end
end
end

function request = local_pick_request(cfg, milestone_id, overrides)
request = struct('case_mode', '', 'case_id', '', 'case_label', '');

switch upper(string(milestone_id))
    case "ME"
        request.case_mode = cfg.milestones.diagnosis_case_mode;
        request.case_id = cfg.milestones.diagnosis_case_id;
        request.case_label = cfg.milestones.diagnosis_case_label;
    otherwise
        request.case_mode = cfg.milestones.baseline_case_mode;
        request.case_id = cfg.milestones.baseline_case_id;
        request.case_label = cfg.milestones.baseline_case_label;
end

if isfield(overrides, 'case_mode') && ~isempty(overrides.case_mode)
    request.case_mode = overrides.case_mode;
end
if isfield(overrides, 'case_id') && ~isempty(overrides.case_id)
    request.case_id = overrides.case_id;
end
if isfield(overrides, 'case_label') && ~isempty(overrides.case_label)
    request.case_label = overrides.case_label;
end
end

function [case_list, family_list, family_index, case_structs] = local_flatten_casebank(casebank)
families = {'nominal', 'heading', 'critical'};
case_list = strings(0, 1);
family_list = strings(0, 1);
family_index = zeros(0, 1);
case_structs = {};

for i = 1:numel(families)
    family_name = families{i};
    bank = casebank.(family_name);
    for k = 1:numel(bank)
        case_list(end+1, 1) = string(bank(k).case_id); %#ok<AGROW>
        family_list(end+1, 1) = string(family_name); %#ok<AGROW>
        family_index(end+1, 1) = k; %#ok<AGROW>
        case_structs{end+1, 1} = bank(k); %#ok<AGROW>
    end
end
end

function [idx, resolved_mode] = local_resolve_case_index(request, case_list, family_list)
idx = NaN;
resolved_mode = string(request.case_mode);
mode = lower(strtrim(char(string(request.case_mode))));
requested_id = string(request.case_id);

switch mode
    case {'exact', 'case_id'}
        idx = find(case_list == requested_id, 1, 'first');
    case 'first_nominal'
        idx = find(family_list == "nominal", 1, 'first');
    case 'first_heading'
        idx = find(family_list == "heading", 1, 'first');
    case 'first_critical'
        idx = find(family_list == "critical", 1, 'first');
    otherwise
        if strlength(requested_id) > 0
            idx = find(case_list == requested_id, 1, 'first');
            resolved_mode = "exact";
        end
end

if isnan(idx)
    fallback_idx = find(family_list == "nominal", 1, 'first');
    if isempty(fallback_idx)
        fallback_idx = 1;
    end
    idx = fallback_idx;
    resolved_mode = resolved_mode + "_fallback";
end
end
