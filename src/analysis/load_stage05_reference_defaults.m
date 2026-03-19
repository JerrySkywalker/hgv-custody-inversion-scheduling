function refs = load_stage05_reference_defaults(cfg)
%LOAD_STAGE05_REFERENCE_DEFAULTS Load centralized Stage05 reference defaults.

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end

refs = struct();
refs.reference_tag = "stage05_strict_reference";
refs.description = "Centralized Stage05 reference defaults extracted from default_params.m for strict replica use.";
refs.h_fixed_km = cfg.stage05.h_fixed_km;
refs.height_grid_km = reshape(cfg.stage05.h_fixed_km, 1, []);
refs.inclination_grid_deg = reshape(cfg.stage05.i_grid_deg, 1, []);
refs.P_grid = reshape(cfg.stage05.P_grid, 1, []);
refs.T_grid = reshape(cfg.stage05.T_grid, 1, []);
refs.Ns_grid = unique(kron(refs.P_grid, refs.T_grid), 'sorted');
refs.F_fixed = cfg.stage03.F;
refs.use_parallel = logical(local_getfield_or(cfg.stage05, 'use_parallel', true));
refs.max_off_boresight_deg = cfg.stage03.max_offnadir_deg;
refs.angle_resolution_arcsec = cfg.stage04.sigma_angle_deg * 3600;
refs.angle_resolution_rad = deg2rad(refs.angle_resolution_arcsec / 3600);
refs.plot_xlim_ns = [min(refs.Ns_grid), max(refs.Ns_grid)];
refs.source_files = { ...
    'params/default_params.m', ...
    'src/search/build_stage05_search_grid.m', ...
    'src/search/summarize_stage05_grid.m'};
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
