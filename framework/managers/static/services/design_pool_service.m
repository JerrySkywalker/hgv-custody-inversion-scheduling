function design_pool = design_pool_service(cfg)
if nargin < 1
    cfg = struct();
end

use_profile_rows = false;
if isfield(cfg, 'profile') && isstruct(cfg.profile) ...
        && isfield(cfg.profile, 'design_pool') && isstruct(cfg.profile.design_pool) ...
        && isfield(cfg.profile.design_pool, 'rows') && ~isempty(cfg.profile.design_pool.rows)
    use_profile_rows = true;
end

if use_profile_rows
    rows = cfg.profile.design_pool.rows;
else
    rows = [ ...
        make_row('D0001', 8, 8, 800, 60, 0), ...
        make_row('D0002', 8, 10, 800, 60, 0), ...
        make_row('D0003', 10, 8, 800, 60, 0) ...
    ];
end

if isfield(cfg, 'runtime') && isfield(cfg.runtime, 'max_designs')
    n = min(cfg.runtime.max_designs, numel(rows));
    rows = rows(1:n);
end

design_pool = struct();
design_pool.name = 'static_design_pool';
design_pool.design_table = rows;
design_pool.design_count = numel(rows);
design_pool.meta = struct('status', 'ok');
end

function row = make_row(design_id, P, T, h_km, i_deg, F)
row = struct();
row.design_id = design_id;
row.P = P;
row.T = T;
row.h_km = h_km;
row.i_deg = i_deg;
row.F = F;
row.Ns = P * T;
end
