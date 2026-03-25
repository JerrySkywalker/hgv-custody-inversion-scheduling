function test_engine_heading_family_stage06_bootstrap()
startup;

cfg = default_params();
heading_offsets_deg = [0, -30, 30];

casebank = build_casebank_nominal(cfg);
nominal_case = casebank.nominal(1);
nominal_traj = propagate_target_case(nominal_case, cfg);

engine_trajs = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

base_item = struct('case', nominal_case, 'traj', nominal_traj, 'validation', [], 'summary', []);
legacy_family = stage06_build_heading_family( ...
    base_item, heading_offsets_deg, ...
    'HeadingMode', cfg.stage06.active_heading_set_name, ...
    'FamilyType', 'heading_extended', ...
    'Cfg', cfg);

assert(numel(engine_trajs) == numel(heading_offsets_deg), 'Heading family size mismatch.');
assert(numel(engine_trajs) == numel(legacy_family), 'Engine/legacy heading family count mismatch.');

for k = 1:numel(engine_trajs)
    case_k = engine_trajs(k).case;
    traj_k = engine_trajs(k).traj;
    legacy_k = legacy_family(k);

    assert(isfield(case_k, 'case_id') && isfield(case_k, 'heading_offset_deg'), ...
        'Heading family case metadata incomplete at item %d.', k);
    assert(case_k.heading_offset_deg == heading_offsets_deg(k), ...
        'Heading offset mismatch at item %d.', k);
    assert(strcmp(case_k.case_id, legacy_k.case.case_id), ...
        'Heading case_id mismatch at item %d.', k);
    assert(strcmp(case_k.family, legacy_k.case.family), ...
        'Heading family label mismatch at item %d.', k);
    assert(strcmp(case_k.subfamily, legacy_k.case.subfamily), ...
        'Heading subfamily mismatch at item %d.', k);

    assert(isequal(size(traj_k.t_s), size(legacy_k.traj.t_s)), ...
        'Heading trajectory time-grid mismatch at item %d.', k);

    diff_xy = max(abs(traj_k.xy_km - legacy_k.traj.xy_km), [], 'all');
    assert(diff_xy < 1e-8, 'Heading trajectory XY mismatch at item %d: %.3e', k, diff_xy);
end

disp('test_engine_heading_family_stage06_bootstrap passed.');
end
