function test_engine_resource_stage03_bootstrap()
startup;

cfg = default_params();

design_row = struct( ...
    'h_km', cfg.stage03.h_km, ...
    'i_deg', cfg.stage03.i_deg, ...
    'P', cfg.stage03.P, ...
    'T', cfg.stage03.T, ...
    'F', cfg.stage03.F);
t_s_common = (0:120:1200).';

walker_engine = build_single_layer_walker(design_row, cfg);
satbank_engine = propagate_constellation(walker_engine, t_s_common, cfg);

cfg_legacy = cfg;
cfg_legacy.stage03.h_km = design_row.h_km;
cfg_legacy.stage03.i_deg = design_row.i_deg;
cfg_legacy.stage03.P = design_row.P;
cfg_legacy.stage03.T = design_row.T;
cfg_legacy.stage03.F = design_row.F;

walker_legacy = build_single_layer_walker_stage03(cfg_legacy);
satbank_legacy = propagate_constellation_stage03(walker_legacy, t_s_common);

assert(walker_engine.Ns == walker_legacy.Ns, 'Walker Ns mismatch.');
assert(numel(walker_engine.sat) == numel(walker_legacy.sat), 'Satellite count mismatch.');
assert(numel(satbank_engine.t_s) == numel(satbank_legacy.t_s), 'Time-grid length mismatch.');
assert(isequal(size(satbank_engine.r_eci_km), size(satbank_legacy.r_eci_km)), ...
    'Constellation tensor size mismatch.');

sample_idx = [1, min(3, walker_engine.Ns), walker_engine.Ns];
for k = 1:numel(sample_idx)
    s = sample_idx(k);
    diff_norm = max(abs(satbank_engine.r_eci_km(:, :, s) - satbank_legacy.r_eci_km(:, :, s)), [], 'all');
    assert(diff_norm < 1e-10, 'Satellite %d propagation mismatch: %.3e', s, diff_norm);
end

disp('test_engine_resource_stage03_bootstrap passed.');
end
