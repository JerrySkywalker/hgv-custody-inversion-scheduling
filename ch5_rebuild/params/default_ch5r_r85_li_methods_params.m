function cfg = default_ch5r_r85_li_methods_params(cfg)
%DEFAULT_CH5R_R85_LI_METHODS_PARAMS
% R8.5a:
%   Li-style method structure reproduction under current ch5r experiment parameters.
%
% This file DOES NOT reproduce Li's original scene parameters.
% It only reproduces:
%   - three tracking modes
%   - four relay-selection criteria
% and binds them to the current ch5r case.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
end

cfg.r85 = struct();
cfg.r85.phase_name = 'R8.5a';
cfg.r85.method_family = 'Li2024-structure-only';
cfg.r85.scene_policy = 'use_current_ch5r_case';

cfg.r85.mode_set = struct();
cfg.r85.mode_set.names = {'stare', 'track_rate', 'relay'};
cfg.r85.mode_set.notes = { ...
    'Inertially fixed pointing mode', ...
    'Continuously slewed target-following mode', ...
    'Interval-based relay tracking mode'};

cfg.r85.selection_set = struct();
cfg.r85.selection_set.names = {'pta', 'cn', 'detY_rim', 'detY_fast'};
cfg.r85.selection_set.notes = { ...
    'Predicted tracking arc length criterion', ...
    'Condition number of observability matrix criterion', ...
    'Recursive information matrix determinant criterion', ...
    'Fast determinant-of-information criterion'};

cfg.r85.resource = struct();
cfg.r85.resource.sats_per_interval = 2;
cfg.r85.resource.interval_source = 'inherit_current_window';
cfg.r85.resource.interval_s = NaN;
if isfield(cfg, 'ch5r') && isfield(cfg.ch5r, 'window_length_s')
    cfg.r85.resource.interval_s = cfg.ch5r.window_length_s;
elseif isfield(cfg, 'stage04') && isfield(cfg.stage04, 'Tw_s')
    cfg.r85.resource.interval_s = cfg.stage04.Tw_s;
end

cfg.r85.logging = struct();
cfg.r85.logging.print_sensor_meta = true;
cfg.r85.logging.print_case_meta = true;
cfg.r85.logging.print_registry = true;

end
