function walker = legacy_build_single_layer_walker_stage03_impl(cfg)
%LEGACY_BUILD_SINGLE_LAYER_WALKER_STAGE03_IMPL Compatibility wrapper around legacy Stage03 Walker builder logic.

walker = struct();
walker.h_km = cfg.stage03.h_km;
walker.i_deg = cfg.stage03.i_deg;
walker.P = cfg.stage03.P;
walker.T = cfg.stage03.T;
walker.F = cfg.stage03.F;
walker.Ns = walker.P * walker.T;

if isfield(cfg.stage03, 'raan_bias_deg') && ~isempty(cfg.stage03.raan_bias_deg)
    raan_bias_deg = cfg.stage03.raan_bias_deg;
else
    raan_bias_deg = 0;
end

sat = repmat(struct(), walker.Ns, 1);
idx = 0;

for p = 1:walker.P
    for t = 1:walker.T
        idx = idx + 1;

        sat(idx).sat_id = idx;
        sat(idx).plane_id = p;
        sat(idx).slot_id = t;

        sat(idx).a_km = 6378.137 + walker.h_km;
        sat(idx).e = 0;
        sat(idx).i_deg = walker.i_deg;

        % Original Walker plane RAAN plus a scenario-level bias.
        sat(idx).raan_deg = mod((p - 1) * 360 / walker.P + raan_bias_deg, 360);

        sat(idx).argp_deg = 0;

        phase_offset_deg = (walker.F * (p - 1) * 360 / walker.Ns);
        sat(idx).M0_deg = mod((t - 1) * 360 / walker.T + phase_offset_deg, 360);
    end
end

walker.sat = sat;
end
