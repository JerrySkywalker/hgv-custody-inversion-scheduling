function out = manual_compare_stage03_resource()
cfg = default_params();

design_row = struct( ...
    'h_km', cfg.stage03.h_km, ...
    'i_deg', cfg.stage03.i_deg, ...
    'P', cfg.stage03.P, ...
    'T', cfg.stage03.T, ...
    'F', cfg.stage03.F);

legacy_walker = build_single_layer_walker_stage03(cfg);
engine_walker = build_single_layer_walker(design_row, cfg);

legacy_satbank = propagate_constellation_stage03(legacy_walker, cfg.stage03.t_s_common);
engine_satbank = propagate_constellation(engine_walker, cfg.stage03.t_s_common, cfg);

out = struct();
out.legacy_Ns = legacy_satbank.Ns;
out.engine_Ns = engine_satbank.Ns;
out.Ns_match = (out.legacy_Ns == out.engine_Ns);

out.legacy_r_size = size(legacy_satbank.r_eci_km);
out.engine_r_size = size(engine_satbank.r_eci_km);
out.r_size_match = isequal(out.legacy_r_size, out.engine_r_size);
end
