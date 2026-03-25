function out = manual_compare_stage06_heading_family()
cfg = default_params();
cfg = stage06_prepare_cfg(cfg);
cfg = configure_stage_output_paths(cfg);

run_tag = char(cfg.stage06.run_tag);

% ------------------------------------------------------------
% Load latest Stage06.1 scope by run_tag
% ------------------------------------------------------------
d6 = find_stage_cache_files(cfg.paths.cache, ...
    sprintf('stage06_define_heading_scope_%s_*.mat', run_tag));
assert(~isempty(d6), 'No Stage06.1 cache found for run_tag: %s', run_tag);

[~, idx6] = max([d6.datenum]);
stage06_scope_file = fullfile(d6(idx6).folder, d6(idx6).name);
S6 = load(stage06_scope_file);
spec = S6.out.spec;

heading_offsets_deg = spec.heading_offsets_deg;

% ------------------------------------------------------------
% Load latest Stage02 cache
% ------------------------------------------------------------
d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
assert(~isempty(d2), 'No Stage02 cache found.');

[~, idx2] = max([d2.datenum]);
stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
S2 = load(stage02_file);
trajs_nominal = S2.out.trajbank.nominal;

% ------------------------------------------------------------
% Legacy family
% ------------------------------------------------------------
legacy_trajs_in = stage06_build_heading_family( ...
    trajs_nominal, heading_offsets_deg, ...
    'HeadingMode', spec.heading_mode, ...
    'FamilyType', spec.family_type, ...
    'Cfg', cfg);

% ------------------------------------------------------------
% Engine family
% Be permissive about current engine wrapper signature.
% ------------------------------------------------------------
try
    engine_trajs_in = build_heading_family( ...
        trajs_nominal, heading_offsets_deg, ...
        'HeadingMode', spec.heading_mode, ...
        'FamilyType', spec.family_type, ...
        'Cfg', cfg);
catch
    try
        engine_trajs_in = build_heading_family( ...
            trajs_nominal, heading_offsets_deg, cfg);
    catch ME
        rethrow(ME);
    end
end

out = struct();

out.run_tag = string(run_tag);
out.stage06_scope_file = string(stage06_scope_file);
out.stage02_file = string(stage02_file);

out.legacy_count = numel(legacy_trajs_in);
out.engine_count = numel(engine_trajs_in);
out.count_match = (out.legacy_count == out.engine_count);

if out.count_match && out.legacy_count > 0
    legacy_offsets = arrayfun(@(s) s.case.heading_offset_deg, legacy_trajs_in);
    engine_offsets = arrayfun(@(s) s.case.heading_offset_deg, engine_trajs_in);

    out.legacy_offsets = legacy_offsets(:).';
    out.engine_offsets = engine_offsets(:).';
    out.offsets_match = isequal(out.legacy_offsets, out.engine_offsets);

    out.first_case_id_legacy = string(legacy_trajs_in(1).case.case_id);
    out.first_case_id_engine = string(engine_trajs_in(1).case.case_id);
    out.first_case_match = strcmp(out.first_case_id_legacy, out.first_case_id_engine);

    out.last_case_id_legacy = string(legacy_trajs_in(end).case.case_id);
    out.last_case_id_engine = string(engine_trajs_in(end).case.case_id);
    out.last_case_match = strcmp(out.last_case_id_legacy, out.last_case_id_engine);

    out.first_traj_size_legacy = size(legacy_trajs_in(1).traj.r_eci_km);
    out.first_traj_size_engine = size(engine_trajs_in(1).traj.r_eci_km);
    out.first_traj_size_match = isequal(out.first_traj_size_legacy, out.first_traj_size_engine);
else
    out.legacy_offsets = [];
    out.engine_offsets = [];
    out.offsets_match = false;

    out.first_case_id_legacy = "";
    out.first_case_id_engine = "";
    out.first_case_match = false;

    out.last_case_id_legacy = "";
    out.last_case_id_engine = "";
    out.last_case_match = false;

    out.first_traj_size_legacy = [];
    out.first_traj_size_engine = [];
    out.first_traj_size_match = false;
end
end
