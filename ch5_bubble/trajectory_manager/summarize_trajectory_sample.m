function summary = summarize_trajectory_sample(traj_sample)
%SUMMARIZE_TRAJECTORY_SAMPLE Summarize one real propagated trajectory sample.

summary = struct();
summary.sample_id = traj_sample.sample_id;
summary.family_id = traj_sample.family_id;
summary.case_label = traj_sample.case_label;
summary.source_tag = traj_sample.source_tag;
summary.n_steps = traj_sample.n_steps;
summary.dt = traj_sample.dt;
summary.t_start = traj_sample.t_start;
summary.t_end = traj_sample.t_end;
summary.state_dim = traj_sample.state_dim;
summary.terminal_reason = traj_sample.terminal_reason;
summary.first_state = traj_sample.first_state;
summary.last_state = traj_sample.last_state;

if isfield(traj_sample, 'traj') && isfield(traj_sample.traj, 'h_km')
    summary.h_range_km = [min(traj_sample.traj.h_km), max(traj_sample.traj.h_km)];
else
    summary.h_range_km = [NaN, NaN];
end

if isfield(traj_sample, 'traj') && isfield(traj_sample.traj, 'v_mps')
    summary.v_range_mps = [min(traj_sample.traj.v_mps), max(traj_sample.traj.v_mps)];
else
    summary.v_range_mps = [NaN, NaN];
end
end
