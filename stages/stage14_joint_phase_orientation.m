function out = stage14_joint_phase_orientation(cfg, overrides)
%STAGE14_JOINT_PHASE_ORIENTATION
% Stage14.4 formal wrapper for B1 joint phase-orientation sensitivity.
%
% This stage intentionally reuses the frozen A1 legacy exploration asset
% as the first formal Stage14.4 implementation.
%
% Current formal scope:
%   - representative case A1
%   - fixed (h,i,P,T) = A1 baseline
%   - scan F and Omega_rel (RAAN)
%
% Output:
%   out.raw          : raw result returned by legacy grid script
%   out.meta         : formal metadata for Stage14.4
%   out.files        : propagated file bundle

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    local = struct();
    local.case_name = "A1";
    local.h_fixed_km = 1000;
    local.i_deg = 40;
    local.P = 8;
    local.T = 6;
    local.F_values = 0:7;
    local.RAAN_values = 0:15:345;
    local.case_limit = inf;
    local.use_early_stop = false;
    local.hard_case_first = true;
    local.require_pass_ratio = 1.0;
    local.require_D_G_min = 1.0;
    local.save_fig = true;
    local.visible = "on";

    fn = fieldnames(overrides);
    for k = 1:numel(fn)
        local.(fn{k}) = overrides.(fn{k});
    end

    raw_overrides = struct();
    raw_overrides.h_fixed_km = local.h_fixed_km;
    raw_overrides.i_deg = local.i_deg;
    raw_overrides.P = local.P;
    raw_overrides.T = local.T;
    raw_overrides.F_values = local.F_values;
    raw_overrides.RAAN_values = local.RAAN_values;
    raw_overrides.case_limit = local.case_limit;
    raw_overrides.use_early_stop = local.use_early_stop;
    raw_overrides.hard_case_first = local.hard_case_first;
    raw_overrides.require_pass_ratio = local.require_pass_ratio;
    raw_overrides.require_D_G_min = local.require_D_G_min;
    raw_overrides.save_fig = local.save_fig;
    raw_overrides.visible = char(local.visible);

    legacy_name = local_resolve_legacy_joint_grid();
    assert(~isempty(legacy_name), ...
        'Stage14.4 wrapper cannot find legacy A1 joint grid function.');

    raw = feval(legacy_name, cfg, raw_overrides);

    out = struct();
    out.raw = raw;
    out.meta = struct();
    out.meta.stage = "Stage14.4";
    out.meta.substage = "B1";
    out.meta.case_name = local.case_name;
    out.meta.description = "joint phase-orientation sensitivity";
    out.meta.h_fixed_km = local.h_fixed_km;
    out.meta.i_deg = local.i_deg;
    out.meta.P = local.P;
    out.meta.T = local.T;
    out.meta.F_values = local.F_values;
    out.meta.RAAN_values = local.RAAN_values;

    if isfield(raw, 'files')
        out.files = raw.files;
    else
        out.files = struct();
    end

    fprintf('\n=== Stage14.4 B1 Joint Phase-Orientation ===\n');
    fprintf('legacy source    : %s\n', legacy_name);
    fprintf('case             : %s\n', local.case_name);
    fprintf('design           : h=%g, i=%g, P=%d, T=%d\n', ...
        local.h_fixed_km, local.i_deg, local.P, local.T);
    fprintf('F range          : [%g .. %g], count=%d\n', ...
        local.F_values(1), local.F_values(end), numel(local.F_values));
    fprintf('Omega_rel count  : %d\n\n', numel(local.RAAN_values));
end

function name = local_resolve_legacy_joint_grid()
    candidates = { ...
        'manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329', ...
        'manual_smoke_stage14_F_RAAN_grid_A1' ...
        };
    name = "";
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file') == 2
            name = string(candidates{k});
            return;
        end
    end
end
