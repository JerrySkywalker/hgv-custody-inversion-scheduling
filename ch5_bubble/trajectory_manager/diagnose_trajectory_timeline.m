function diag_out = diagnose_trajectory_timeline(traj_sample)
%DIAGNOSE_TRAJECTORY_TIMELINE Diagnose real propagated trajectory timeline.

time = traj_sample.time(:);
dt_series = diff(time);

diag_out = struct();
diag_out.sample_id = traj_sample.sample_id;
diag_out.n_steps = numel(time);
diag_out.t_start = time(1);
diag_out.t_end = time(end);
diag_out.duration = time(end) - time(1);

if isempty(dt_series)
    diag_out.dt_min = NaN;
    diag_out.dt_max = NaN;
    diag_out.dt_mean = NaN;
    diag_out.is_uniform_dt = true;
else
    diag_out.dt_min = min(dt_series);
    diag_out.dt_max = max(dt_series);
    diag_out.dt_mean = mean(dt_series);
    diag_out.is_uniform_dt = max(abs(dt_series - dt_series(1))) < 1e-9;
end

diag_out.time_monotonic = all(dt_series > 0);
diag_out.truth_rows_match = size(traj_sample.truth,1) == numel(time);
diag_out.terminal_reason = traj_sample.terminal_reason;

if isfield(traj_sample, 'traj') && isfield(traj_sample.traj, 'h_km')
    diag_out.h_start_km = traj_sample.traj.h_km(1);
    diag_out.h_end_km = traj_sample.traj.h_km(end);
else
    diag_out.h_start_km = NaN;
    diag_out.h_end_km = NaN;
end

if isfield(traj_sample, 'traj') && isfield(traj_sample.traj, 'v_mps')
    diag_out.v_start_mps = traj_sample.traj.v_mps(1);
    diag_out.v_end_mps = traj_sample.traj.v_mps(end);
else
    diag_out.v_start_mps = NaN;
    diag_out.v_end_mps = NaN;
end
end
