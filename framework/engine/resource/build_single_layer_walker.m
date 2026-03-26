function walker = build_single_layer_walker(row, cfg)
%BUILD_SINGLE_LAYER_WALKER Build a single-layer Walker constellation from a design row.
%
% row fields:
%   h_km, i_deg, P, T, F
% Optional:
%   raan_deg  -> interpreted as constellation-level RAAN bias / scenario offset

cfg_eval = cfg;

cfg_eval.stage03.h_km = row.h_km;
cfg_eval.stage03.i_deg = row.i_deg;
cfg_eval.stage03.P = row.P;
cfg_eval.stage03.T = row.T;
cfg_eval.stage03.F = row.F;

if isfield(row, 'raan_deg') && ~isempty(row.raan_deg)
    cfg_eval.stage03.raan_bias_deg = row.raan_deg;
else
    cfg_eval.stage03.raan_bias_deg = 0;
end

walker = legacy_build_single_layer_walker_stage03_impl(cfg_eval);
end
