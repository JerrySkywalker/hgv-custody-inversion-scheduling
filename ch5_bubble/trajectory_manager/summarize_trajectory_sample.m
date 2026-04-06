function summary = summarize_trajectory_sample(traj_sample)
%SUMMARIZE_TRAJECTORY_SAMPLE Summarize a trajectory sample.

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

end
