function out = manual_compare_stage06_heading_family()
cfg = default_params();

% legacy nominal trajectory
legacy_casebank = build_casebank_stage01(cfg);
nominal_case = legacy_casebank.nominal(1);
nominal_traj = propagate_hgv_case_stage02(nominal_case, cfg);

% legacy heading family
heading_offsets_deg = cfg.stage06.heading_offsets_deg;
legacy_trajs_in = stage06_build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

% engine heading family
engine_trajs_in = build_heading_family(nominal_case, nominal_traj, heading_offsets_deg, cfg);

out = struct();

out.legacy_count = numel(legacy_trajs_in);
out.engine_count = numel(engine_trajs_in);
out.count_match = (out.legacy_count == out.engine_count);

if out.count_match && out.legacy_count > 0
    legacy_offsets = arrayfun(@(s) s.case.heading_offset_deg, legacy_trajs_in);
    engine_offsets = arrayfun(@(s) s.case.heading_offset_deg, engine_trajs_in);

    out.legacy_offsets = legacy_offsets(:).';
    out.engine_offsets = engine_offsets(:).';
    out.offsets_match = isequal(out.legacy_offsets, out.engine_offsets);

    out.first_case_id_legacy = string(legacy_trajs_in(1).case.case_id);
    out.first_case_id_engine = string(engine_trajs_in(1).case.case_id);
    out.first_case_match = strcmp(out.first_case_id_legacy, out.first_case_id_engine);

    out.last_case_id_legacy = string(legacy_trajs_in(end).case.case_id);
    out.last_case_id_engine = string(engine_trajs_in(end).case.case_id);
    out.last_case_match = strcmp(out.last_case_id_legacy, out.last_case_id_engine);

    out.first_traj_size_legacy = size(legacy_trajs_in(1).traj.r_eci_km);
    out.first_traj_size_engine = size(engine_trajs_in(1).traj.r_eci_km);
    out.first_traj_size_match = isequal(out.first_traj_size_legacy, out.first_traj_size_engine);
else
    out.legacy_offsets = [];
    out.engine_offsets = [];
    out.offsets_match = false;

    out.first_case_id_legacy = "";
    out.first_case_id_engine = "";
    out.first_case_match = false;

    out.last_case_id_legacy = "";
    out.last_case_id_engine = "";
    out.last_case_match = false;

    out.first_traj_size_legacy = [];
    out.first_traj_size_engine = [];
    out.first_traj_size_match = false;
end
end
