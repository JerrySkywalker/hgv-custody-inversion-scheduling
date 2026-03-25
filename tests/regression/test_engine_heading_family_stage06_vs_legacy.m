function test_engine_heading_family_stage06_vs_legacy()
startup;

ctx = build_engine_test_context();
family = build_heading_family(ctx.nominal_case, ctx.nominal_traj, ctx.heading_offsets_deg, ctx.cfg);
heading_offsets = arrayfun(@(s) s.case.heading_offset_deg, family);

assert(numel(family) == numel(ctx.heading_offsets_deg), 'Heading family size mismatch.');
assert(isequal(heading_offsets(:).', ctx.heading_offsets_deg(:).'), 'Heading offsets mismatch.');
traj_lengths = arrayfun(@(s) numel(s.traj.t_s), family);
assert(all(traj_lengths == numel(ctx.nominal_traj.t_s)), ...
    'Heading trajectory time grid mismatch.');

disp('test_engine_heading_family_stage06_vs_legacy passed.');
end
