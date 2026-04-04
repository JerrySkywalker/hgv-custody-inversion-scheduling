function bundle = bootstrap_ch5r_from_stage04_stage05(cfg)
%BOOTSTRAP_CH5R_FROM_STAGE04_STAGE05  Build Phase R0 bootstrap bundle.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end

stage04_info = load_latest_stage04_cache(cfg);
stage05_info = load_latest_stage05_cache(cfg);

theta_star = select_static_min_solution(stage05_info, cfg);
theta_plus = select_static_plus_solution(stage05_info, theta_star, cfg);
target_case = select_representative_target_case(cfg, stage04_info, stage05_info);

sensor_profile = cfg.ch5r.sensor_profile;
gamma_req = stage04_info.gamma_req;

bundle = struct();
bundle.meta = struct();
bundle.meta.phase_name = 'R0';
bundle.meta.created_from = mfilename;
bundle.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

bundle.stage04 = stage04_info;
bundle.stage05 = stage05_info;
bundle.theta_star = theta_star;
bundle.theta_plus = theta_plus;
bundle.sensor_profile = sensor_profile;
bundle.target_case = target_case;
bundle.gamma_req = gamma_req;

out_dir = cfg.ch5r.output_dirs.phaseR0;
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
out_dir = fullfile(out_dir, 'bootstrap');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
mat_path = fullfile(out_dir, ['bootstrap_ch5r_from_stage04_stage05_' stamp '.mat']);
txt_path = fullfile(out_dir, ['bootstrap_ch5r_from_stage04_stage05_' stamp '.txt']);

save(mat_path, 'bundle');

fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open bootstrap summary: %s', txt_path);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Phase: %s\n', bundle.meta.phase_name);
fprintf(fid, 'Timestamp: %s\n', bundle.meta.timestamp);
fprintf(fid, 'Stage04 source: %s\n', stage04_info.file);
fprintf(fid, 'Stage05 source: %s\n', stage05_info.file);
fprintf(fid, 'gamma_req: %.12g\n', gamma_req);
fprintf(fid, 'theta_star: h=%.6g km, i=%.6g deg, P=%d, T=%d, F=%d, Ns=%d\n', ...
    theta_star.h_km, theta_star.i_deg, theta_star.P, theta_star.T, theta_star.F, theta_star.Ns);
fprintf(fid, 'theta_plus: h=%.6g km, i=%.6g deg, P=%d, T=%d, F=%d, Ns=%d\n', ...
    theta_plus.h_km, theta_plus.i_deg, theta_plus.P, theta_plus.T, theta_plus.F, theta_plus.Ns);
fprintf(fid, 'target_case: %s (%s)\n', target_case.case_id, target_case.family);

bundle.paths = struct();
bundle.paths.output_dir = out_dir;
bundle.paths.mat_file = mat_path;
bundle.paths.summary_file = txt_path;
end
