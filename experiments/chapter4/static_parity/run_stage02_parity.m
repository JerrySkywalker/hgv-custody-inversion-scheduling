function out = run_stage02_parity(profile_stage01, cfg)
%RUN_STAGE02_PARITY Minimal Stage02 parity runner on top of new framework.

if nargin < 1 || isempty(profile_stage01)
    profile_stage01 = struct();
end

if nargin < 2 || isempty(cfg)
    cfg = struct();
    cfg.target_template = make_default_target_template();
elseif ~isfield(cfg, 'target_template')
    cfg.target_template = make_default_target_template();
end

stage01_out = run_stage01_parity(profile_stage01);
trajectory_set = propagate_track_set(stage01_out.task_set, cfg);

out = struct();
out.status = 'PASS';
out.stage_id = 'stage02';
out.cfg = cfg;
out.stage01 = stage01_out;
out.task_set = stage01_out.task_set;
out.task_set_summary = stage01_out.task_set_summary;
out.trajectory_set = trajectory_set;
out.trajectory_set_summary = summarize_trajectory_set_status(trajectory_set);
end

function summary = summarize_trajectory_set_status(trajectory_set)
summary = struct();
summary.count = trajectory_set.count;
summary.ok_count = sum(trajectory_set.ok_flags);
summary.fail_count = summary.count - summary.ok_count;
summary.track_ids_failed = trajectory_set.track_ids(~trajectory_set.ok_flags);
end
