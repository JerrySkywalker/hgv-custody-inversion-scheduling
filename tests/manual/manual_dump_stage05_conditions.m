function out = manual_dump_stage05_conditions()
startup;

cfg = default_params();
cfg = stage09_prepare_cfg(cfg);
cfg = configure_stage_output_paths(cfg);

gamma_info = load_stage04_nominal_gamma_req();

out = struct();
out.created_at = string(datetime('now'));
out.sensor = cfg.sensor;
out.stage03 = cfg.stage03;
out.walker = cfg.walker;
out.stage05 = cfg.stage05;
out.stage09_search_domain = cfg.stage09.search_domain;
out.gamma_info = gamma_info;

output_dir = fullfile('outputs', 'manual', 'stage05_conditions');
if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
mat_path = fullfile(output_dir, sprintf('stage05_conditions_%s.mat', timestamp));
txt_path = fullfile(output_dir, sprintf('stage05_conditions_%s.txt', timestamp));
latest_mat = fullfile(output_dir, 'stage05_conditions_latest.mat');
latest_txt = fullfile(output_dir, 'stage05_conditions_latest.txt');

save(mat_path, 'out');
save(latest_mat, 'out');

fid = fopen(txt_path, 'w');
fprintf(fid, 'Stage05 Conditions Snapshot\n');
fprintf(fid, 'created_at: %s\n\n', char(out.created_at));

fprintf(fid, '[sensor]\n');
fprintf(fid, 'sigma_angle_deg: %.10g\n\n', out.sensor.sigma_angle_deg);

fprintf(fid, '[stage03]\n');
fprintf(fid, 'h_km: %.10g\n', out.stage03.h_km);
fprintf(fid, 'i_deg: %.10g\n', out.stage03.i_deg);
fprintf(fid, 'P: %.10g\n', out.stage03.P);
fprintf(fid, 'T: %.10g\n', out.stage03.T);
fprintf(fid, 'F: %.10g\n', out.stage03.F);
fprintf(fid, 'max_range_km: %.10g\n', out.stage03.max_range_km);
fprintf(fid, 'min_elevation_deg: %.10g\n', out.stage03.min_elevation_deg);
fprintf(fid, 'require_earth_occlusion_check: %d\n', out.stage03.require_earth_occlusion_check);
fprintf(fid, 'enable_offnadir_constraint: %d\n', out.stage03.enable_offnadir_constraint);
fprintf(fid, 'max_offnadir_deg: %.10g\n', out.stage03.max_offnadir_deg);
fprintf(fid, 'use_stage02_time_grid: %d\n\n', out.stage03.use_stage02_time_grid);

fprintf(fid, '[walker]\n');
fprintf(fid, 'h_km_list: %s\n', mat2str(out.walker.h_km_list));
fprintf(fid, 'i_deg_list: %s\n', mat2str(out.walker.i_deg_list));
fprintf(fid, 'P_list: %s\n', mat2str(out.walker.P_list));
fprintf(fid, 'T_list: %s\n\n', mat2str(out.walker.T_list));

fprintf(fid, '[stage05]\n');
fprintf(fid, 'family_scope: %s\n', string(out.stage05.family_scope));
fprintf(fid, 'gamma_source: %s\n', string(out.stage05.gamma_source));
fprintf(fid, 'h_fixed_km: %.10g\n', out.stage05.h_fixed_km);
fprintf(fid, 'F_fixed: %.10g\n', out.stage05.F_fixed);
fprintf(fid, 'i_grid_deg: %s\n', mat2str(out.stage05.i_grid_deg));
fprintf(fid, 'P_grid: %s\n', mat2str(out.stage05.P_grid));
fprintf(fid, 'T_grid: %s\n', mat2str(out.stage05.T_grid));
fprintf(fid, 'require_pass_ratio: %.10g\n', out.stage05.require_pass_ratio);
fprintf(fid, 'require_D_G_min: %.10g\n', out.stage05.require_D_G_min);
fprintf(fid, 'rank_rule: %s\n', string(out.stage05.rank_rule));
fprintf(fid, 'use_early_stop: %d\n', out.stage05.use_early_stop);
fprintf(fid, 'hard_case_first: %d\n\n', out.stage05.hard_case_first);

fprintf(fid, '[stage09_search_domain]\n');
fprintf(fid, 'h_grid_km: %s\n', mat2str(out.stage09_search_domain.h_grid_km));
fprintf(fid, 'i_grid_deg: %s\n', mat2str(out.stage09_search_domain.i_grid_deg));
fprintf(fid, 'P_grid: %s\n', mat2str(out.stage09_search_domain.P_grid));
fprintf(fid, 'T_grid: %s\n', mat2str(out.stage09_search_domain.T_grid));
fprintf(fid, 'F_fixed: %.10g\n', out.stage09_search_domain.F_fixed);
fprintf(fid, 'round_to_integer: %d\n', out.stage09_search_domain.round_to_integer);
fprintf(fid, 'max_config_count: %.10g\n\n', out.stage09_search_domain.max_config_count);

fprintf(fid, '[gamma_info]\n');
gamma_fields = fieldnames(out.gamma_info);
for i = 1:numel(gamma_fields)
    f = gamma_fields{i};
    v = out.gamma_info.(f);
    if isnumeric(v)
        if isscalar(v)
            fprintf(fid, '%s: %.10g\n', f, v);
        else
            fprintf(fid, '%s: %s\n', f, mat2str(v));
        end
    elseif isstring(v) || ischar(v)
        fprintf(fid, '%s: %s\n', f, string(v));
    else
        fprintf(fid, '%s: [non-scalar %s]\n', f, class(v));
    end
end
fclose(fid);

copyfile(txt_path, latest_txt);

out.mat_path = string(mat_path);
out.txt_path = string(txt_path);
out.latest_mat = string(latest_mat);
out.latest_txt = string(latest_txt);

disp('[manual] Stage05 conditions snapshot written.');
disp(out);
end
