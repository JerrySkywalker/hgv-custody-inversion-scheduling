function cfg = set_case_id_for_ch5r(cfg, case_id)
%SET_CASE_ID_FOR_CH5R
% Best-effort case-id injection helper for R8X.3.

assert(ischar(case_id) || isstring(case_id), 'case_id invalid.');
case_id = char(string(case_id));

cfg.case_id = case_id;
cfg.current_case_id = case_id;
cfg.target_case_id = case_id;

if ~isfield(cfg, 'case_bank') || ~isstruct(cfg.case_bank)
    cfg.case_bank = struct();
end
cfg.case_bank.case_id = case_id;

if ~isfield(cfg, 'scenario') || ~isstruct(cfg.scenario)
    cfg.scenario = struct();
end
cfg.scenario.case_id = case_id;
end
