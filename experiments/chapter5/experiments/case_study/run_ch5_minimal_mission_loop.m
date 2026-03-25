function result = run_ch5_minimal_mission_loop()
%RUN_CH5_MINIMAL_MISSION_LOOP Minimal Chapter 5 mission loop using engine bases.

startup;

profile = make_ch5_minimal_profile();
gamma_info = load_stage04_nominal_gamma_req();
cfg = default_params();
cfg.stage04.Tw_s = gamma_info.Tw_s;
cfg.stage04.gamma_req = gamma_info.gamma_req;

nominal_family = build_task_family(struct( ...
    'family_name', 'nominal', ...
    'max_cases', profile.nominal_case_count), cfg);
heading_family = build_task_family(struct( ...
    'family_name', 'heading', ...
    'max_cases', numel(profile.heading_offsets_deg), ...
    'heading_offsets_deg', profile.heading_offsets_deg, ...
    'allowed_heading_offsets_deg', profile.heading_offsets_deg, ...
    'nominal_case_count', profile.nominal_case_count), cfg);

open_search = run_design_grid_search_opend(profile.design_rows, nominal_family, cfg, struct( ...
    'gamma_eff_scalar', gamma_info.gamma_req, ...
    'run_tag', [profile.name '_opend'], ...
    'source_profile', profile));
closed_search = run_design_grid_search_closedd(profile.design_rows, heading_family, cfg, struct( ...
    'gamma_eff_scalar', gamma_info.gamma_req, ...
    'run_tag', [profile.name '_closedd'], ...
    'source_profile', profile));

open_table = open_search.grid_table;
closed_table = closed_search.grid_table;

mission_table = local_build_mission_table(open_table, closed_table);
best_design_table = local_pick_best_design(mission_table);

output_dir = profile.output_dir;
artifact_open = artifact_service(open_table, output_dir, 'ch5_minimal_opend');
artifact_closed = artifact_service(closed_table, output_dir, 'ch5_minimal_closedd');
artifact_mission = artifact_service(mission_table, output_dir, 'ch5_minimal_mission');
artifact_best = artifact_service(best_design_table, output_dir, 'ch5_minimal_best_design');

manifest = make_artifact_manifest('ch5_minimal_mission_loop', ...
    {artifact_open, artifact_closed, artifact_mission, artifact_best});
manifest_paths = save_artifact_manifest(manifest, output_dir, 'ch5_minimal_mission_loop');

result = struct();
result.profile = profile;
result.gamma_info = gamma_info;
result.nominal_family = nominal_family;
result.heading_family = heading_family;
result.open_search = open_search;
result.closed_search = closed_search;
result.open_table = open_table;
result.closed_table = closed_table;
result.mission_table = mission_table;
result.best_design_table = best_design_table;
result.artifact_open = artifact_open;
result.artifact_closed = artifact_closed;
result.artifact_mission = artifact_mission;
result.artifact_best = artifact_best;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[chapter5] Minimal mission loop completed.');
disp(mission_table(:, {'design_id', 'Ns', 'open_pass_ratio', 'closed_pass_ratio', 'open_joint_margin', 'closed_joint_margin', 'mission_score'}));
disp(best_design_table);
end

function mission_table = local_build_mission_table(open_table, closed_table)
open_tbl = open_table(:, {'design_id', 'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', ...
    'pass_ratio', 'feasible_flag', 'joint_margin', 'DG_rob', 'rank_score'});
open_tbl = renamevars(open_tbl, ...
    {'pass_ratio', 'feasible_flag', 'joint_margin', 'DG_rob', 'rank_score'}, ...
    {'open_pass_ratio', 'open_feasible_flag', 'open_joint_margin', 'open_DG_rob', 'open_rank_score'});

closed_tbl = closed_table(:, {'design_id', 'pass_ratio', 'feasible_flag', 'joint_margin', ...
    'DG_rob', 'DA_rob', 'DT_bar_rob', 'DT_rob', 'rank_score', 'dominant_fail_tag'});
closed_tbl = renamevars(closed_tbl, ...
    {'pass_ratio', 'feasible_flag', 'joint_margin', 'DG_rob', 'DA_rob', 'DT_bar_rob', 'DT_rob', 'rank_score', 'dominant_fail_tag'}, ...
    {'closed_pass_ratio', 'closed_feasible_flag', 'closed_joint_margin', 'closed_DG_rob', 'closed_DA_rob', 'closed_DT_bar_rob', 'closed_DT_rob', 'closed_rank_score', 'closed_dominant_fail_tag'});

mission_table = innerjoin(open_tbl, closed_tbl, 'Keys', 'design_id');
mission_table.mission_feasible = mission_table.open_feasible_flag & mission_table.closed_feasible_flag;
mission_table.mission_score = mission_table.Ns - 1e-3 * mission_table.closed_joint_margin;
mission_table = sortrows(mission_table, {'Ns', 'closed_joint_margin'}, {'ascend', 'descend'});
end

function best_design_table = local_pick_best_design(mission_table)
if isempty(mission_table)
    best_design_table = mission_table;
    return;
end

feasible_tbl = mission_table(mission_table.mission_feasible, :);
if isempty(feasible_tbl)
    feasible_tbl = mission_table;
end

best_design_table = feasible_tbl(1, :);
end
