function cfg = apply_ch5r_case_override(cfg, case_id)
%APPLY_CH5R_CASE_OVERRIDE
% Apply target case override for Chapter 5 without modifying core runner logic.
%
% Phase 2A helper:
% - keep current single-case pipeline unchanged
% - only rewrite configuration fields needed for future multi-case execution
%
% Inputs
%   cfg     : Chapter 5 config struct; if empty, default_ch5r_params(true) is used
%   case_id : target case id, e.g. 'N01', 'H04_+30', 'C1_track_plane_aligned'
%
% Outputs
%   cfg     : updated config

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
end

if nargin < 2 || isempty(case_id)
    error('apply_ch5r_case_override:InvalidInput', 'case_id is required.');
end

case_id = char(string(case_id));
family = local_guess_family(case_id);

if ~isfield(cfg, 'ch5r') || ~isstruct(cfg.ch5r)
    error('apply_ch5r_case_override:InvalidCfg', 'cfg.ch5r is missing.');
end

% --------------------------------
% bootstrap subtree
% --------------------------------
if ~isfield(cfg.ch5r, 'bootstrap') || ~isstruct(cfg.ch5r.bootstrap)
    cfg.ch5r.bootstrap = struct();
end

cfg.ch5r.bootstrap.force_case_id = case_id;
cfg.ch5r.bootstrap.strict_single_case = 1;
cfg.ch5r.bootstrap.applied_case_override = case_id;

% --------------------------------
% target_case subtree
% --------------------------------
if ~isfield(cfg.ch5r, 'target_case') || ~isstruct(cfg.ch5r.target_case)
    cfg.ch5r.target_case = struct();
end

% Preserve any existing stage cache fields / other metadata, but synchronize
% the explicit case identity fields so downstream logging does not keep stale N01.
cfg.ch5r.target_case.case_id = case_id;
cfg.ch5r.target_case.default_case_id = case_id;
cfg.ch5r.target_case.family = family;
cfg.ch5r.target_case.source = 'apply_ch5r_case_override';

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
