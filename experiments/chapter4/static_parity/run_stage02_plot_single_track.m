function out = run_stage02_plot_single_track(profile_stage01, cfg, plot_opts)
%RUN_STAGE02_PLOT_SINGLE_TRACK Plot one propagated track using framework APIs only.

if nargin < 1 || isempty(profile_stage01)
    profile_stage01 = struct();
    profile_stage01.task_family_def = struct();
    profile_stage01.task_family_def.class_name = "nominal";
    profile_stage01.task_family_def.selection_mode = "filter";
    profile_stage01.task_family_def.selector = struct();
    profile_stage01.task_family_def.selector.traj_id = "traj_nominal_001";
end

if nargin < 2 || isempty(cfg)
    cfg = struct();
    cfg.target_template = make_default_target_template();
end

if nargin < 3 || isempty(plot_opts)
    plot_opts = struct();
end

stage01_out = run_stage01_parity(profile_stage01);
if stage01_out.task_set.item_count ~= 1
    error('run_stage02_plot_single_track:ExpectedSingleTrack', ...
        'task_set must contain exactly one track.');
end

track_i = stage01_out.task_set.items(1,:);
target_cfg = build_target_cfg_from_track(track_i, cfg);
traj = propagate_single_track(target_cfg);

coord_mode = "enu_km";
if isfield(plot_opts, 'CoordinateMode') && ~isempty(plot_opts.CoordinateMode)
    coord_mode = plot_opts.CoordinateMode;
end

fig_visible = "on";
if isfield(plot_opts, 'FigureVisible') && ~isempty(plot_opts.FigureVisible)
    fig_visible = plot_opts.FigureVisible;
end

output_path = "";
if isfield(plot_opts, 'OutputPath') && ~isempty(plot_opts.OutputPath)
    output_path = plot_opts.OutputPath;
end

fig = plot_single_trajectory_3d(traj, ...
    'CoordinateMode', coord_mode, ...
    'FigureVisible', fig_visible, ...
    'OutputPath', output_path);

out = struct();
out.stage01 = stage01_out;
out.track = track_i;
out.target_cfg = target_cfg;
out.traj = traj;
out.fig = fig;
end
