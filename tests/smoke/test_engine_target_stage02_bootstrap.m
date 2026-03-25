function test_engine_target_stage02_bootstrap()
startup;

cfg = default_params();

engine_casebank = build_casebank_nominal(cfg);
legacy_casebank = build_casebank_stage01(cfg);

assert(isfield(engine_casebank, 'nominal'), 'Engine casebank missing nominal field.');
assert(numel(engine_casebank.nominal) == numel(legacy_casebank.nominal), ...
    'Nominal case count mismatch.');

case_engine = engine_casebank.nominal(1);
case_legacy = legacy_casebank.nominal(1);

assert(strcmp(case_engine.case_id, case_legacy.case_id), 'First nominal case_id mismatch.');
assert(strcmp(case_engine.family, case_legacy.family), 'First nominal family mismatch.');

traj_engine = propagate_target_case(case_engine, cfg);
traj_legacy = propagate_hgv_case_stage02(case_legacy, cfg);

required_fields = {'case_id', 'family', 'subfamily', 't_s', 'r_eci_km', 'xy_km', 'meta'};
for k = 1:numel(required_fields)
    assert(isfield(traj_engine, required_fields{k}), ...
        'Engine trajectory missing field %s.', required_fields{k});
end

assert(numel(traj_engine.t_s) == numel(traj_legacy.t_s), 'Time-grid length mismatch.');
assert(isequal(size(traj_engine.r_eci_km), size(traj_legacy.r_eci_km)), 'ECI size mismatch.');
assert(isequal(size(traj_engine.xy_km), size(traj_legacy.xy_km)), 'XY size mismatch.');

eci_diff = max(abs(traj_engine.r_eci_km - traj_legacy.r_eci_km), [], 'all');
xy_diff = max(abs(traj_engine.xy_km - traj_legacy.xy_km), [], 'all');

assert(eci_diff < 1e-8, 'Target ECI mismatch: %.3e', eci_diff);
assert(xy_diff < 1e-8, 'Target XY mismatch: %.3e', xy_diff);

disp('test_engine_target_stage02_bootstrap passed.');
end
