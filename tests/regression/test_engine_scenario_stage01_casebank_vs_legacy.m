function test_engine_scenario_stage01_casebank_vs_legacy()
startup;

cfg = default_params();
casebank_engine = build_casebank(cfg);
casebank_legacy = build_casebank_stage01(cfg);

assert(numel(casebank_engine.nominal) == numel(casebank_legacy.nominal), 'Nominal case count mismatch.');
assert(numel(casebank_engine.heading) == numel(casebank_legacy.heading), 'Heading case count mismatch.');
assert(numel(casebank_engine.critical) == numel(casebank_legacy.critical), 'Critical case count mismatch.');

assert(strcmp(casebank_engine.nominal(1).case_id, casebank_legacy.nominal(1).case_id), ...
    'Nominal first case_id mismatch.');
assert(casebank_engine.heading(1).heading_offset_deg == casebank_legacy.heading(1).heading_offset_deg, ...
    'Heading offset mismatch.');

disp('test_engine_scenario_stage01_casebank_vs_legacy passed.');
end
