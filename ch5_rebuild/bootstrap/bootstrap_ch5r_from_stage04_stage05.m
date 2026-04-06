function bundle = bootstrap_ch5r_from_stage04_stage05(cfg)
%BOOTSTRAP_CH5R_FROM_STAGE04_STAGE05  Build Phase R0 bootstrap bundle.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end

stage04_info = load_latest_stage04_cache(cfg);
stage05_info = load_latest_stage05_cache(cfg);

if cfg.ch5r.bootstrap.require_stage04_cache
    assert(stage04_info.found, '[ch5r:R0] Stage04 cache not found.');
    assert(stage04_info.load_ok, '[ch5r:R0] Stage04 cache exists but failed to load.');
end

if cfg.ch5r.bootstrap.require_stage05_cache
    assert(stage05_info.found, '[ch5r:R0] Stage05 cache not found.');
    assert(stage05_info.load_ok, '[ch5r:R0] Stage05 cache exists but failed to load.');
end

if cfg.ch5r.bootstrap.require_stage05_feasible_table
    assert(istable(stage05_info.feasible_table), ...
        '[ch5r:R0] Stage05 feasible_table is missing or not a table.');
    assert(~isempty(stage05_info.feasible_table), ...
        '[ch5r:R0] Stage05 feasible_table is empty.');
end

target_case = select_representative_target_case(cfg, stage04_info, stage05_info);
theta_star = select_static_min_solution(stage05_info, cfg, target_case.case_id);
theta_plus = select_static_plus_solution(stage05_info, theta_star, cfg, target_case.case_id);

sensor_profile = cfg.ch5r.sensor_profile;
gamma_req = stage04_info.gamma_req;

consistency = local_build_consistency(stage04_info, stage05_info, target_case, theta_star, theta_plus, cfg);

if ~consistency.ok
    local_throw_consistency_error(consistency);
end

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
bundle.consistency = consistency;

bundle.paths = struct();
bundle.paths.output_dir = '';
bundle.paths.mat_file = '';
bundle.paths.summary_file = '';

if isfield(cfg.ch5r.bootstrap, 'write_outputs') && cfg.ch5r.bootstrap.write_outputs
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

    bundle.paths.output_dir = out_dir;
    bundle.paths.mat_file = mat_path;
    bundle.paths.summary_file = txt_path;

    save(mat_path, 'bundle');

    fid = fopen(txt_path, 'w');
    assert(fid >= 0, 'Failed to open bootstrap summary: %s', txt_path);
    cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, 'Phase: %s\n', bundle.meta.phase_name);
    fprintf(fid, 'Timestamp: %s\n', bundle.meta.timestamp);
    fprintf(fid, 'Stage04 source: %s\n', stage04_info.file);
    fprintf(fid, 'Stage05 source: %s\n', stage05_info.file);
    fprintf(fid, 'gamma_req: %.12g\n', gamma_req);
    fprintf(fid, 'forced_case_id: %s\n', target_case.case_id);
    fprintf(fid, 'stage04 timestamp: %s\n', consistency.stage04_timestamp_text);
    fprintf(fid, 'stage05 timestamp: %s\n', consistency.stage05_timestamp_text);
    fprintf(fid, 'cache timestamp matched: %d\n', consistency.cache_timestamp_match);
    fprintf(fid, 'strict_ok: %d\n', consistency.ok);
    fprintf(fid, 'theta_star: h=%.6g km, i=%.6g deg, P=%d, T=%d, F=%d, Ns=%d, case_id=%s, source=%s\n', ...
        theta_star.h_km, theta_star.i_deg, theta_star.P, theta_star.T, theta_star.F, theta_star.Ns, ...
        theta_star.case_id, theta_star.source);
    fprintf(fid, 'theta_plus: h=%.6g km, i=%.6g deg, P=%d, T=%d, F=%d, Ns=%d, case_id=%s, source=%s\n', ...
        theta_plus.h_km, theta_plus.i_deg, theta_plus.P, theta_plus.T, theta_plus.F, theta_plus.Ns, ...
        theta_plus.case_id, theta_plus.source);

    if ~isempty(consistency.messages)
        fprintf(fid, 'messages:\n');
        for i = 1:numel(consistency.messages)
            fprintf(fid, '  - %s\n', consistency.messages{i});
        end
    end
end
end

function consistency = local_build_consistency(stage04_info, stage05_info, target_case, theta_star, theta_plus, cfg)
consistency = struct();
consistency.ok = true;
consistency.messages = {};

consistency.stage04_timestamp = local_extract_timestamp_from_path(stage04_info.file);
consistency.stage05_timestamp = local_extract_timestamp_from_path(stage05_info.file);
consistency.stage04_timestamp_text = local_dt_to_text(consistency.stage04_timestamp);
consistency.stage05_timestamp_text = local_dt_to_text(consistency.stage05_timestamp);

consistency.cache_timestamp_match = true;
if cfg.ch5r.bootstrap.require_matching_cache_timestamps
    dt4 = consistency.stage04_timestamp;
    dt5 = consistency.stage05_timestamp;
    if ~isnat(dt4) && ~isnat(dt5)
        gap_s = abs(seconds(dt5 - dt4));
        consistency.cache_timestamp_gap_seconds = gap_s;
        consistency.cache_timestamp_match = (gap_s <= cfg.ch5r.bootstrap.cache_timestamp_tolerance_seconds);
        if ~consistency.cache_timestamp_match
            consistency.ok = false;
            consistency.messages{end+1} = sprintf( ...
                'Stage04/Stage05 cache timestamps mismatch: gap %.3f s exceeds tolerance %.3f s.', ...
                gap_s, cfg.ch5r.bootstrap.cache_timestamp_tolerance_seconds);
        end
    else
        consistency.cache_timestamp_gap_seconds = NaN;
        consistency.ok = false;
        consistency.cache_timestamp_match = false;
        consistency.messages{end+1} = 'Failed to parse Stage04 or Stage05 cache timestamp from filename.';
    end
else
    consistency.cache_timestamp_gap_seconds = NaN;
end

forced_case = string(cfg.ch5r.bootstrap.force_case_id);

if cfg.ch5r.bootstrap.strict_single_case
    if string(target_case.case_id) ~= forced_case
        consistency.ok = false;
        consistency.messages{end+1} = sprintf( ...
            'target_case.case_id=%s does not match forced_case_id=%s.', ...
            string(target_case.case_id), forced_case);
    end
    if string(theta_star.case_id) ~= forced_case
        consistency.ok = false;
        consistency.messages{end+1} = sprintf( ...
            'theta_star.case_id=%s does not match forced_case_id=%s.', ...
            string(theta_star.case_id), forced_case);
    end
    if string(theta_plus.case_id) ~= forced_case
        consistency.ok = false;
        consistency.messages{end+1} = sprintf( ...
            'theta_plus.case_id=%s does not match forced_case_id=%s.', ...
            string(theta_plus.case_id), forced_case);
    end
end

if isfield(theta_star, 'used_fallback') && theta_star.used_fallback
    consistency.ok = false;
    consistency.messages{end+1} = 'theta_star was selected by fallback, which is forbidden in strict R0.';
end

if isfield(theta_plus, 'used_fallback') && theta_plus.used_fallback
    consistency.ok = false;
    consistency.messages{end+1} = 'theta_plus was selected by fallback, which is forbidden in strict R0.';
end

if ~(isfield(theta_star, 'Ns') && isnumeric(theta_star.Ns) && isfinite(theta_star.Ns) && theta_star.Ns > 0)
    consistency.ok = false;
    consistency.messages{end+1} = 'theta_star.Ns is invalid.';
end

if ~(isfield(theta_plus, 'Ns') && isnumeric(theta_plus.Ns) && isfinite(theta_plus.Ns) && theta_plus.Ns > theta_star.Ns)
    consistency.ok = false;
    consistency.messages{end+1} = 'theta_plus.Ns must be strictly larger than theta_star.Ns.';
end

if cfg.ch5r.bootstrap.forbid_theta_plus_equal_theta_star
    if isequal(theta_plus.P, theta_star.P) && ...
       isequal(theta_plus.T, theta_star.T) && ...
       isequal(theta_plus.F, theta_star.F) && ...
       isequal(theta_plus.i_deg, theta_star.i_deg) && ...
       isequal(theta_plus.h_km, theta_star.h_km)
        consistency.ok = false;
        consistency.messages{end+1} = 'theta_plus is identical to theta_star.';
    end
end

if ~(isfield(stage05_info, 'feasible_table') && istable(stage05_info.feasible_table) && ~isempty(stage05_info.feasible_table))
    consistency.ok = false;
    consistency.messages{end+1} = 'stage05_info.feasible_table is missing or empty.';
end

if ~(isfield(stage04_info, 'gamma_req') && isnumeric(stage04_info.gamma_req) && isfinite(stage04_info.gamma_req) && stage04_info.gamma_req > 0)
    consistency.ok = false;
    consistency.messages{end+1} = 'stage04_info.gamma_req is invalid.';
end
end

function dt = local_extract_timestamp_from_path(file_path)
dt = NaT;
if isempty(file_path)
    return;
end
[~, name, ~] = fileparts(file_path);
token = regexp(name, '(\d{8}_\d{6})', 'tokens', 'once');
if isempty(token)
    return;
end
try
    dt = datetime(token{1}, 'InputFormat', 'yyyyMMdd_HHmmss');
catch
    dt = NaT;
end
end

function txt = local_dt_to_text(dt)
if isnat(dt)
    txt = 'NaT';
else
    txt = char(dt);
end
end

function local_throw_consistency_error(consistency)
msg = sprintf('[ch5r:R0] strict bootstrap validation failed.\n');
for i = 1:numel(consistency.messages)
    msg = sprintf('%s  - %s\n', msg, consistency.messages{i});
end
error('%s', msg);
end
