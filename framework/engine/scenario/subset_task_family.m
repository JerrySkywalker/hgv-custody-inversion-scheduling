function task_family = subset_task_family(task_family, subset_spec)
%SUBSET_TASK_FAMILY Apply generic filters to a task family.
% Inputs:
%   task_family : struct with .trajs_in
%   subset_spec : struct with max_cases, allowed_heading_offsets_deg, case_ids
%
% Output:
%   task_family : filtered task-family struct

if nargin < 2 || isempty(subset_spec) || ~isfield(task_family, 'trajs_in')
    return;
end

trajs_in = task_family.trajs_in;
keep = true(numel(trajs_in), 1);

if isfield(subset_spec, 'allowed_heading_offsets_deg') && ~isempty(subset_spec.allowed_heading_offsets_deg)
    allowed = subset_spec.allowed_heading_offsets_deg(:).';
    keep_heading = false(numel(trajs_in), 1);
    for k = 1:numel(trajs_in)
        if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'heading_offset_deg')
            keep_heading(k) = any(trajs_in(k).case.heading_offset_deg == allowed);
        end
    end
    keep = keep & keep_heading;
end

if isfield(subset_spec, 'case_ids') && ~isempty(subset_spec.case_ids)
    case_ids = string(subset_spec.case_ids);
    keep_case = false(numel(trajs_in), 1);
    for k = 1:numel(trajs_in)
        if isfield(trajs_in(k), 'case') && isfield(trajs_in(k).case, 'case_id')
            keep_case(k) = any(string(trajs_in(k).case.case_id) == case_ids);
        end
    end
    keep = keep & keep_case;
end

trajs_in = trajs_in(keep);

if isfield(subset_spec, 'max_cases') && ~isempty(subset_spec.max_cases)
    trajs_in = trajs_in(1:min(subset_spec.max_cases, numel(trajs_in)));
end

task_family.trajs_in = trajs_in;
task_family.case_count = numel(trajs_in);
end
