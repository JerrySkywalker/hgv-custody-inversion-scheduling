function cfg = apply_ch5r_case_override(cfg, case_id)
%APPLY_CH5R_CASE_OVERRIDE
% Apply target case override for Chapter 5 without modifying core runner logic.
%
% This Phase 2A helper only rewrites configuration fields that are already
% consumed by current bootstrap / case-building logic.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
end
if nargin < 2 || isempty(case_id)
    error('case_id is required.');
end

case_id = char(string(case_id));

if ~isfield(cfg, 'ch5r') || ~isstruct(cfg.ch5r)
    error('cfg.ch5r is missing.');
end

if ~isfield(cfg.ch5r, 'bootstrap') || ~isstruct(cfg.ch5r.bootstrap)
    cfg.ch5r.bootstrap = struct();
end
cfg.ch5r.bootstrap.force_case_id = case_id;
cfg.ch5r.bootstrap.strict_single_case = 1;

if ~isfield(cfg.ch5r, 'target_case') || ~isstruct(cfg.ch5r.target_case)
    cfg.ch5r.target_case = struct();
end
cfg.ch5r.target_case.default_case_id = case_id;
cfg.ch5r.target_case.family = local_guess_family(case_id);

disp(' ')
disp('=== [ch5r:case-override] applied ===')
disp(cfg.ch5r.target_case)
disp(cfg.ch5r.bootstrap)
end

function family = local_guess_family(case_id)
if startsWith(case_id, 'N', 'IgnoreCase', true)
    family = 'nominal';
elseif startsWith(case_id, 'H', 'IgnoreCase', true)
    family = 'heading';
elseif startsWith(case_id, 'C', 'IgnoreCase', true)
    family = 'critical';
else
    family = 'unknown';
end
end
