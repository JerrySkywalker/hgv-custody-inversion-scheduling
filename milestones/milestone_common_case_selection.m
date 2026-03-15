function selection = milestone_common_case_selection(cfg, milestone_id)
%MILESTONE_COMMON_CASE_SELECTION Build a lightweight milestone case selector.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end

selection = struct();
selection.milestone_id = string(milestone_id);
selection.case_set = string(cfg.milestones.case_set);
selection.baseline_case_id = string(cfg.milestones.baseline_case_id);
selection.diagnosis_case_id = string(cfg.milestones.diagnosis_case_id);
selection.case_family = "nominal";

switch upper(string(milestone_id))
    case "ME"
        selection.case_id = string(cfg.milestones.diagnosis_case_id);
        selection.case_family = "critical";
    otherwise
        selection.case_id = string(cfg.milestones.baseline_case_id);
end
end
