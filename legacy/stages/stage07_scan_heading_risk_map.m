function out = stage07_scan_heading_risk_map(cfg, opts)
    %STAGE07_SCAN_HEADING_RISK_MAP
    % Stage07.3:
    %   Scan heading-risk map entry-by-entry under fixed reference Walker.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    cfg.project_stage = 'stage07_scan_heading_risk_map';
    cfg = configure_stage_output_paths(cfg);
    cfg = local_apply_stage07_opts(cfg, opts);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage07.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage07_scan_heading_risk_map_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanup_obj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage07.3 started.');

    [reference_walker, scope_spec, nominal_bank, stage07_ref_file, stage07_scope_file, stage02_file] = ...
        local_load_stage07_inputs(cfg, run_tag);

    scope_spec = local_apply_scope_overrides(scope_spec, cfg);
    nominal_bank = local_select_nominal_entries(nominal_bank, scope_spec.entry_sampling);
    nEntry = numel(nominal_bank);

    log_msg(log_fid, 'INFO', 'Loaded Stage07.1 reference Walker: %s', stage07_ref_file);
    log_msg(log_fid, 'INFO', 'Loaded Stage07.2 scope: %s', stage07_scope_file);
    log_msg(log_fid, 'INFO', 'Loaded Stage02 nominal cache: %s', stage02_file);
    log_msg(log_fid, 'INFO', 'Nominal family size = %d', numel(nominal_bank));
    log_msg(log_fid, 'INFO', 'Selected nominal entry count = %d', nEntry);

    disable_detail_bank = isfield(opts, 'disable_detail_bank') && opts.disable_detail_bank;
    risk_tables = cell(nEntry, 1);
    detail_banks = cell(nEntry, 1);
    entry_ids = nan(nEntry, 1);

    use_parallel = isfield(cfg.stage07, 'use_parallel') && cfg.stage07.use_parallel;
    if use_parallel
        cfg = local_apply_parallel_runtime_policy(cfg, disable_detail_bank);
    end
    if use_parallel && cfg.stage07.auto_start_pool
        ensure_parallel_pool(cfg.stage07.parallel_pool_profile, cfg.stage07.parallel_num_workers);
    end

    if use_parallel
        parfor i = 1:nEntry
            base_item = nominal_bank(i);
            [risk_tables{i}, detail_bank_i] = scan_heading_risk_map_stage07( ...
                base_item, reference_walker, scope_spec, cfg, disable_detail_bank);
            if disable_detail_bank
                detail_banks{i} = [];
            else
                detail_banks{i} = detail_bank_i;
            end
            entry_ids(i) = local_extract_entry_id_from_item(base_item, i);
        end
    else
        for i = 1:nEntry
            base_item = nominal_bank(i);
            [risk_tables{i}, detail_banks{i}] = scan_heading_risk_map_stage07( ...
                base_item, reference_walker, scope_spec, cfg, disable_detail_bank);
            entry_ids(i) = local_extract_entry_id_from_item(base_item, i);
        end
    end

    for i = 1:nEntry
        log_msg(log_fid, 'INFO', ...
            '[%2d/%2d] entry=%d | heading_count=%d | candidate_count=%d | min_D_G=%.3f | min_angle=%.3f', ...
            i, nEntry, ...
            entry_ids(i), ...
            height(risk_tables{i}), ...
            sum(risk_tables{i}.is_counterexample_candidate), ...
            min(risk_tables{i}.D_G_min, [], 'omitnan'), ...
            min(risk_tables{i}.mean_los_intersection_angle_deg, [], 'omitnan'));
    end

    risk_table = vertcat(risk_tables{:});
    entry_summary = local_build_entry_summary(risk_table, scope_spec);

    self_check = struct();
    self_check.nonempty = ~isempty(risk_table);
    self_check.has_multiple_entries = numel(unique(risk_table.entry_id)) >= 2;
    self_check.has_heading_scan = numel(unique(risk_table.heading_offset_deg)) >= 3;
    self_check.has_finite_metrics = ...
        any(isfinite(risk_table.coverage_ratio_2sat)) && ...
        any(isfinite(risk_table.mean_los_intersection_angle_deg)) && ...
        any(isfinite(risk_table.lambda_worst)) && ...
        any(isfinite(risk_table.D_G_min));
    self_check.all_ok = self_check.nonempty && ...
        self_check.has_multiple_entries && ...
        self_check.has_heading_scan && ...
        self_check.has_finite_metrics;

    risk_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage07_heading_risk_map_%s_%s.csv', run_tag, timestamp));
    entry_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage07_heading_risk_entry_summary_%s_%s.csv', run_tag, timestamp));
    summary_csv = fullfile(cfg.paths.tables, ...
        sprintf('stage07_heading_risk_summary_%s_%s.csv', run_tag, timestamp));

    summary_table = table( ...
        string(scope_spec.family_type), ...
        reference_walker.h_km, ...
        reference_walker.i_deg, ...
        reference_walker.P, ...
        reference_walker.T, ...
        reference_walker.Ns, ...
        height(risk_table), ...
        height(entry_summary), ...
        numel(unique(risk_table.heading_offset_deg)), ...
        sum(risk_table.is_counterexample_candidate), ...
        self_check.all_ok, ...
        'VariableNames', { ...
            'family_type', ...
            'h_km', ...
            'i_deg', ...
            'P', ...
            'T', ...
            'Ns', ...
            'n_risk_row', ...
            'n_entry', ...
            'n_heading_offset', ...
            'n_counterexample_candidate', ...
            'self_check_all_ok'});

    writetable(risk_table, risk_csv);
    writetable(entry_summary, entry_csv);
    writetable(summary_table, summary_csv);

    out = struct();
    out.cfg = cfg;
    out.reference_walker = reference_walker;
    out.scope_spec = scope_spec;
    out.risk_table = risk_table;
    out.entry_summary = entry_summary;
    out.detail_banks = detail_banks;
    out.self_check = self_check;
    out.summary_table = summary_table;

    out.files = struct();
    out.files.log_file = log_file;
    out.files.stage07_ref_file = stage07_ref_file;
    out.files.stage07_scope_file = stage07_scope_file;
    out.files.stage02_file = stage02_file;
    out.files.risk_csv = risk_csv;
    out.files.entry_csv = entry_csv;
    out.files.summary_csv = summary_csv;

    out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    cache_file = fullfile(cfg.paths.cache, ...
        sprintf('stage07_scan_heading_risk_map_%s_%s.mat', run_tag, timestamp));
    save(cache_file, 'out', '-v7.3');
    out.files.cache_file = cache_file;

    log_msg(log_fid, 'INFO', 'Risk CSV saved to: %s', risk_csv);
    log_msg(log_fid, 'INFO', 'Entry summary CSV saved to: %s', entry_csv);
    log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
    log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
    log_msg(log_fid, 'INFO', 'Stage07.3 finished.');

    fprintf('\n');
    fprintf('========== Stage07.3 Summary ==========\n');
    fprintf('Stage07.1 ref       : %s\n', stage07_ref_file);
    fprintf('Stage07.2 scope     : %s\n', stage07_scope_file);
    fprintf('Stage02 nominal     : %s\n', stage02_file);
    fprintf('Reference Walker    : h=%.1f km | i=%.1f deg | P=%d | T=%d | F=%d | Ns=%d\n', ...
        reference_walker.h_km, reference_walker.i_deg, ...
        reference_walker.P, reference_walker.T, reference_walker.F, reference_walker.Ns);
    fprintf('Risk row count      : %d\n', height(risk_table));
    fprintf('Entry count         : %d\n', height(entry_summary));
    fprintf('Heading offset cnt  : %d\n', numel(unique(risk_table.heading_offset_deg)));
    fprintf('Candidate count     : %d\n', sum(risk_table.is_counterexample_candidate));
    fprintf('Risk CSV            : %s\n', risk_csv);
    fprintf('Entry CSV           : %s\n', entry_csv);
    fprintf('Cache               : %s\n', cache_file);
    fprintf('Self-check all ok   : %d\n', self_check.all_ok);
    fprintf('=======================================\n');
end

function [reference_walker, scope_spec, nominal_bank, stage07_ref_file, stage07_scope_file, stage02_file] = local_load_stage07_inputs(cfg, run_tag)
    persistent cache

    d71 = find_stage_cache_files(cfg.paths.cache, ...
        sprintf('stage07_select_reference_walker_%s_*.mat', run_tag));
    assert(~isempty(d71), 'No Stage07.1 cache found for run_tag=%s.', run_tag);
    [~, idx71] = max([d71.datenum]);
    stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);

    d72 = find_stage_cache_files(cfg.paths.cache, ...
        sprintf('stage07_define_critical_scope_refwalker_%s_*.mat', run_tag));
    assert(~isempty(d72), 'No Stage07.2 scope cache found for run_tag=%s.', run_tag);
    [~, idx72] = max([d72.datenum]);
    stage07_scope_file = fullfile(d72(idx72).folder, d72(idx72).name);

    d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
    assert(~isempty(d2), 'No Stage02 nominal cache found.');
    [~, idx2] = max([d2.datenum]);
    stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);

    cache_hit = isstruct(cache) && ...
        isfield(cache, 'stage07_ref_file') && strcmp(cache.stage07_ref_file, stage07_ref_file) && ...
        isfield(cache, 'stage07_scope_file') && strcmp(cache.stage07_scope_file, stage07_scope_file) && ...
        isfield(cache, 'stage02_file') && strcmp(cache.stage02_file, stage02_file);

    if ~cache_hit
        S71 = load(stage07_ref_file);
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache: missing reference_walker');

        S72 = load(stage07_scope_file);
        assert(isfield(S72, 'out') && isfield(S72.out, 'spec'), ...
            'Invalid Stage07.2 cache: missing spec');

        S2 = load(stage02_file);
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');

        cache = struct();
        cache.stage07_ref_file = stage07_ref_file;
        cache.stage07_scope_file = stage07_scope_file;
        cache.stage02_file = stage02_file;
        cache.reference_walker = S71.out.reference_walker;
        cache.scope_spec = S72.out.spec;
        cache.nominal_bank = S2.out.trajbank.nominal;
    end

    reference_walker = cache.reference_walker;
    scope_spec = cache.scope_spec;
    nominal_bank = cache.nominal_bank;
end

function bank_out = local_select_nominal_entries(bank_in, entry_sampling)
    bank_out = bank_in;
    if ~entry_sampling.enable
        return;
    end

    n = numel(bank_in);
    n_keep = min(entry_sampling.max_entry_count, n);

    switch lower(char(entry_sampling.rule))
        case 'all_stage02_nominal_entries'
            bank_out = bank_in(1:n_keep);
        otherwise
            bank_out = bank_in(1:n_keep);
    end
end

function entry_id = local_extract_entry_id_from_item(item, fallback_id)
    entry_id = fallback_id;

    if isfield(item, 'case')
        C = item.case;
    else
        C = item;
    end

    if isfield(C, 'entry_id') && isnumeric(C.entry_id) && isfinite(C.entry_id)
        entry_id = C.entry_id;
        return;
    end
    if isfield(C, 'entry_point_id') && isnumeric(C.entry_point_id) && isfinite(C.entry_point_id)
        entry_id = C.entry_point_id;
        return;
    end
    if isfield(C, 'case_id') && ~isempty(C.case_id)
        cid = char(string(C.case_id));
        tok = regexp(cid, '^N(\d+)$', 'tokens', 'once');
        if ~isempty(tok)
            entry_id = str2double(tok{1});
        end
    end
end

function entry_summary = local_build_entry_summary(risk_table, scope_spec)
    uEntry = unique(risk_table.entry_id);
    nEntry = numel(uEntry);

    entry_summary = table('Size', [nEntry, 10], ...
        'VariableTypes', {'double','double','double','double','double','double','double','double','double','double'}, ...
        'VariableNames', { ...
            'entry_id', ...
            'n_heading', ...
            'max_coverage_ratio_2sat', ...
            'min_mean_los_intersection_angle_deg', ...
            'min_lambda_worst', ...
            'min_D_G_min', ...
            'n_high_coverage', ...
            'n_counterexample_candidate', ...
            'heading_at_min_D_G_deg', ...
            'heading_at_min_angle_deg'});

    for i = 1:nEntry
        eid = uEntry(i);
        sub = risk_table(risk_table.entry_id == eid, :);

        [minDG, idxDG] = min(sub.D_G_min, [], 'omitnan');
        [minAng, idxAng] = min(sub.mean_los_intersection_angle_deg, [], 'omitnan');

        if isempty(idxDG) || ~isfinite(idxDG), idxDG = 1; end
        if isempty(idxAng) || ~isfinite(idxAng), idxAng = 1; end

        entry_summary.entry_id(i) = eid;
        entry_summary.n_heading(i) = height(sub);
        entry_summary.max_coverage_ratio_2sat(i) = max(sub.coverage_ratio_2sat, [], 'omitnan');
        entry_summary.min_mean_los_intersection_angle_deg(i) = minAng;
        entry_summary.min_lambda_worst(i) = min(sub.lambda_worst, [], 'omitnan');
        entry_summary.min_D_G_min(i) = minDG;
        entry_summary.n_high_coverage(i) = sum(sub.coverage_ratio_2sat >= scope_spec.danger.coverage_good_threshold);
        entry_summary.n_counterexample_candidate(i) = sum(sub.is_counterexample_candidate);
        entry_summary.heading_at_min_D_G_deg(i) = sub.heading_deg(idxDG);
        entry_summary.heading_at_min_angle_deg(i) = sub.heading_deg(idxAng);
    end
end

function scope_spec = local_apply_scope_overrides(scope_spec, cfg)
    if isfield(cfg, 'stage07') && isfield(cfg.stage07, 'entry_sampling')
        scope_spec.entry_sampling = cfg.stage07.entry_sampling;
    end
    if isfield(cfg, 'stage07') && isfield(cfg.stage07, 'heading_scan')
        scope_spec.heading_scan = cfg.stage07.heading_scan;
        max_abs = scope_spec.heading_scan.max_abs_offset_deg;
        step = scope_spec.heading_scan.step_deg;
        scope_spec.heading_scan.offset_grid_deg = (-max_abs:step:max_abs).';
    end
end

function cfg = local_apply_stage07_opts(cfg, opts)
    if ~isfield(opts, 'mode') || isempty(opts.mode)
        return;
    end

    use_parallel = strcmpi(string(opts.mode), "parallel");
    cfg.stage07.use_parallel = use_parallel;

    if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
        opts.parallel_config = struct();
    end
    if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
        opts.parallel_config.enabled = use_parallel;
    end
    if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
        opts.parallel_config.profile_name = cfg.stage07.parallel_pool_profile;
    end
    if ~isfield(opts.parallel_config, 'num_workers')
        opts.parallel_config.num_workers = cfg.stage07.parallel_num_workers;
    end
    if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
        opts.parallel_config.auto_start_pool = cfg.stage07.auto_start_pool;
    end

    cfg.stage07.use_parallel = use_parallel && opts.parallel_config.enabled;
    cfg.stage07.parallel_pool_profile = opts.parallel_config.profile_name;
    cfg.stage07.parallel_num_workers = opts.parallel_config.num_workers;
    cfg.stage07.auto_start_pool = opts.parallel_config.auto_start_pool;
end

function cfg = local_apply_parallel_runtime_policy(cfg, disable_detail_bank)
    prefer_threads = isfield(cfg.stage07, 'prefer_thread_pool_for_batch') && ...
        cfg.stage07.prefer_thread_pool_for_batch;
    if ~prefer_threads || ~disable_detail_bank
        return;
    end
    if strcmpi(string(cfg.stage07.parallel_pool_profile), "local")
        cfg.stage07.parallel_pool_profile = 'threads';
    end
end
