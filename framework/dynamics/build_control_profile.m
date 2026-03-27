function ctrl = build_control_profile(target_cfg)
%BUILD_CONTROL_PROFILE Build open-loop alpha/bank control profile for one target_cfg.

if nargin < 1 || ~isstruct(target_cfg)
    error('build_control_profile:InvalidInput', ...
        'target_cfg must be a struct.');
end

getv = @(s, name, defaultv) local_getfield_or_default(s, name, defaultv);

if ~isfield(target_cfg, 'control') || ~isstruct(target_cfg.control)
    error('build_control_profile:MissingControl', ...
        'target_cfg.control must exist.');
end

family = getv(target_cfg.control, 'family', 'nominal');
subfamily = getv(target_cfg.control, 'subfamily', '');
heading_offset_deg = 0;
if isfield(target_cfg, 'init') && isstruct(target_cfg.init)
    heading_offset_deg = getv(target_cfg.init, 'heading_offset_deg', 0);
end

switch family
    case 'nominal'
        alpha_deg = getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0));
        bank_deg  = getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0));

    case 'heading'
        alpha_deg = getv(target_cfg.control, 'alpha_heading_deg', getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0)));
        bank_deg  = getv(target_cfg.control, 'bank_heading_deg',  getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0)));

    case 'critical'
        switch subfamily
            case 'critical_track_plane_aligned'
                alpha_deg = getv(target_cfg.control, 'alpha_c1_deg', getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0)));
                bank_deg  = getv(target_cfg.control, 'bank_c1_deg',  getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0)));

            case 'critical_small_crossing_angle'
                alpha_deg = getv(target_cfg.control, 'alpha_c2_deg', getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0)));
                bank_deg  = getv(target_cfg.control, 'bank_c2_deg',  getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0)));

            otherwise
                alpha_deg = getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0));
                bank_deg  = getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0));
        end

    otherwise
        alpha_deg = getv(target_cfg.control, 'alpha_nominal_deg', getv(target_cfg.control, 'alpha_cmd_deg', 15.0));
        bank_deg  = getv(target_cfg.control, 'bank_nominal_deg',  getv(target_cfg.control, 'bank_cmd_deg',  0.0));
end

use_heading_bank_bias = getv(target_cfg.control, 'use_heading_offset_as_bank_seed', false);
heading_bank_gain_deg = getv(target_cfg.control, 'heading_offset_bank_gain_deg_per_deg', 0.0);

if strcmp(family, 'heading') && use_heading_bank_bias && isfinite(heading_offset_deg)
    bank_deg = bank_deg + heading_bank_gain_deg * heading_offset_deg;
end

ctrl = struct();
ctrl.alpha_deg = alpha_deg;
ctrl.bank_deg  = bank_deg;

ctrl.alpha = @(t) alpha_deg; %#ok<NASGU>
ctrl.gamma = @(t) bank_deg;  %#ok<NASGU>
end

function v = local_getfield_or_default(s, name, defaultv)
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = defaultv;
end
end
