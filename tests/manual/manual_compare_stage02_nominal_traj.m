function out = manual_compare_stage02_nominal_traj()
cfg = default_params();

legacy_casebank = build_casebank_stage01(cfg);
case_item = legacy_casebank.nominal(1);

legacy_traj = propagate_hgv_case_stage02(case_item, cfg);
engine_traj = propagate_target_case(case_item, cfg);

out = struct();
out.n_time_legacy = numel(legacy_traj.t_s);
out.n_time_engine = numel(engine_traj.t_s);
out.time_count_match = (out.n_time_legacy == out.n_time_engine);

if isfield(legacy_traj, 'r_eci_km') && isfield(engine_traj, 'r_eci_km')
    out.state_size_legacy = size(legacy_traj.r_eci_km);
    out.state_size_engine = size(engine_traj.r_eci_km);
    out.state_size_match = isequal(out.state_size_legacy, out.state_size_engine);
else
    out.state_size_legacy = [];
    out.state_size_engine = [];
    out.state_size_match = false;
end
end
