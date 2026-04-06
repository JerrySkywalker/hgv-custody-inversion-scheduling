function cfg = set_case_id_for_ch5r(cfg, case_id)
%SET_CASE_ID_FOR_CH5R
% R8X.3a:
%   Best-effort case-id injection helper for ch5_rebuild builders.

assert(ischar(case_id) || isstring(case_id), 'case_id invalid.');
case_id = char(string(case_id));

% top-level aliases
cfg.case_id = case_id;
cfg.current_case_id = case_id;
cfg.target_case_id = case_id;
cfg.case_name = case_id;
cfg.target_case = case_id;
cfg.truth_case_id = case_id;

% scenario-level aliases
if ~isfield(cfg, 'scenario') || ~isstruct(cfg.scenario)
    cfg.scenario = struct();
end
cfg.scenario.case_id = case_id;
cfg.scenario.case_name = case_id;
cfg.scenario.target_case_id = case_id;
cfg.scenario.target_case = case_id;

% case-bank aliases
if ~isfield(cfg, 'case_bank') || ~isstruct(cfg.case_bank)
    cfg.case_bank = struct();
end
cfg.case_bank.case_id = case_id;
cfg.case_bank.case_name = case_id;
cfg.case_bank.target_case_id = case_id;

% target block aliases
if ~isfield(cfg, 'target') || ~isstruct(cfg.target)
    cfg.target = struct();
end
cfg.target.case_id = case_id;
cfg.target.case_name = case_id;

% ch5r-specific aliases
if ~isfield(cfg, 'ch5r') || ~isstruct(cfg.ch5r)
    cfg.ch5r = struct();
end
cfg.ch5r.case_id = case_id;
cfg.ch5r.case_name = case_id;

if ~isfield(cfg.ch5r, 'scenario') || ~isstruct(cfg.ch5r.scenario)
    cfg.ch5r.scenario = struct();
end
cfg.ch5r.scenario.case_id = case_id;
cfg.ch5r.scenario.case_name = case_id;

if ~isfield(cfg.ch5r, 'target') || ~isstruct(cfg.ch5r.target)
    cfg.ch5r.target = struct();
end
cfg.ch5r.target.case_id = case_id;
cfg.ch5r.target.case_name = case_id;
end
