function design_pool = design_pool_service(cfg)
if nargin < 1
    cfg = struct();
end

row = struct();
row.design_id = 'D0001';
row.P = cfg.design.default_P;
row.T = cfg.design.default_T;
row.h_km = cfg.design.default_h_km;
row.i_deg = cfg.design.default_i_deg;
row.F = 0;
row.Ns = row.P * row.T;

design_pool = struct();
design_pool.name = 'bootstrap_pool';
design_pool.design_table = row;
design_pool.design_count = 1;
design_pool.meta = struct('status', 'minimal');
end
