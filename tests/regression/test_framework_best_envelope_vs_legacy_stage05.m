function test_framework_best_envelope_vs_legacy_stage05()
startup;

r = run_engine_opend_nominal_small_formal();
tbl = r.truth_result.table;
envelope_tbl = build_best_envelope(tbl, 'Ns', 'pass_ratio', struct('i_deg', 60), 'max');

Ns_vals = unique(tbl.Ns);
Ns_vals = sort(Ns_vals(:));

for k = 1:numel(Ns_vals)
    ns = Ns_vals(k);
    direct_best = max(tbl.pass_ratio(tbl.i_deg == 60 & tbl.Ns == ns));
    row = envelope_tbl(envelope_tbl.Ns == ns, :);
    assert(height(row) == 1, 'Expected one envelope row per Ns.');
    assert(abs(row.pass_ratio - direct_best) < 1e-12, 'Envelope max-pass mismatch.');
end

disp('test_framework_best_envelope_vs_legacy_stage05 passed.');
end
