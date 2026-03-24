function out = stage06_define_heading_scope(cfg)
    %STAGE06_DEFINE_HEADING_SCOPE
    % Stage06.1:
    %   Freeze experiment scope for heading-extended family search.
    %   This stage does NOT run search yet.
    %
    % Main tasks:
    %   1) inherit gamma_req from latest Stage04 cache
    %   2) verify Stage02 nominal family size
    %   3) freeze heading-family definition and Stage06 search grid
    %   4) save a standardized Stage06 spec cache for later stages
    %
    % Outputs:
    %   out.spec
    %   out.files
    %   out.summary
    %
    % Notes:
    %   - no family generator yet
    %   - no Walker search yet
    %   - this is a scope-freezing / self-check stage only
    
        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage06_prepare_cfg(cfg);
        cfg.project_stage = 'stage06_define_heading_scope';
        cfg = configure_stage_output_paths(cfg);
        run_tag = char(cfg.stage06.run_tag);

        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);

        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_define_heading_scope_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.1 started.');
    
        % ============================================================
        % Load latest Stage04 cache: inherit gamma_req
        % ============================================================
        d4 = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
        assert(~isempty(d4), ...
            'No Stage04 cache found. Please run stage04_window_worstcase first.');
    
        [~, idx4] = max([d4.datenum]);
        stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
        S4 = load(stage04_file);
    
        assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
        assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
            'Stage04 cache missing summary.gamma_meta');
    
        gamma_req = S4.out.summary.gamma_meta.gamma_req;
        cfg.stage06.gamma_req = gamma_req;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
        log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
    
        % ============================================================
        % Load latest Stage02 cache: use nominal family as Stage06 source
        % ============================================================
        d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        assert(~isempty(d2), ...
            'No Stage02 cache found. Please run stage02_hgv_nominal first.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
    
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
    
        trajs_nominal = S2.out.trajbank.nominal;
        nominal_count = numel(trajs_nominal);
    
        log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size = %d', nominal_count);
    
        % ============================================================
        % Freeze heading-family spec
        % ============================================================
        heading_offsets_deg = cfg.stage06.active_heading_offsets_deg(:).';
        n_heading = numel(heading_offsets_deg);
        expected_family_size = nominal_count * n_heading;
    
        if isequal(sort(heading_offsets_deg), sort(cfg.stage06.heading_offsets_small_deg))
            heading_mode_label = "small";
        elseif isequal(sort(heading_offsets_deg), sort(cfg.stage06.heading_offsets_full_deg))
            heading_mode_label = "full";
        else
            heading_mode_label = "custom";
        end
    
        % ============================================================
        % Self-check
        % ============================================================
        self_check = struct();
        self_check.nominal_count_ok = (nominal_count == cfg.stage06.expected_nominal_case_count);
    
        switch heading_mode_label
            case "small"
                self_check.family_size_ok = ...
                    (expected_family_size == cfg.stage06.expected_small_family_size);
            case "full"
                self_check.family_size_ok = ...
                    (expected_family_size == cfg.stage06.expected_full_family_size);
            otherwise
                self_check.family_size_ok = true;
        end
    
        self_check.i_grid_ok = isequal(cfg.stage06.i_grid_deg, [30 40 50 60 70 80 90]);
        self_check.P_grid_ok = isequal(cfg.stage06.P_grid, [4 6 8 10 12]);
        self_check.T_grid_ok = isequal(cfg.stage06.T_grid, [4 6 8 10 12 16]);
        self_check.h_fixed_ok = isequal(cfg.stage06.h_fixed_km, 1000);
        self_check.criteria_ok = ...
            isequal(cfg.stage06.require_pass_ratio, cfg.stage05.require_pass_ratio) && ...
            isequal(cfg.stage06.require_D_G_min, cfg.stage05.require_D_G_min);
    
        self_check.all_ok = all(struct2array(self_check));
    
        % ============================================================
        % Build spec struct
        % ============================================================
        spec = struct();
        spec.stage_name = 'Stage06.1';
        spec.stage_desc = 'Freeze experiment scope for heading-extended Walker search';
        spec.family_type = cfg.stage06.family_scope;
        spec.family_source = cfg.stage06.family_source;
        spec.heading_mode = char(heading_mode_label);
        spec.heading_offsets_deg = heading_offsets_deg;
        spec.nominal_case_count = nominal_count;
        spec.expected_family_size = expected_family_size;
    
        spec.h_fixed_km = cfg.stage06.h_fixed_km;
        spec.F_fixed = cfg.stage06.F_fixed;
        spec.i_grid_deg = cfg.stage06.i_grid_deg;
        spec.P_grid = cfg.stage06.P_grid;
        spec.T_grid = cfg.stage06.T_grid;
    
        spec.gamma_source = cfg.stage06.gamma_source;
        spec.gamma_req = gamma_req;
    
        spec.metric_fields = {'D_G_min', 'pass_ratio', 'feasible'};
        spec.require_pass_ratio = cfg.stage06.require_pass_ratio;
        spec.require_D_G_min = cfg.stage06.require_D_G_min;
        spec.rank_rule = cfg.stage06.rank_rule;
    
        spec.notes = {
            'Stage06 keeps the Stage05 search grid unchanged';
            'Only family definition changes from nominal to heading-extended';
            'Entry-point set remains unchanged';
            'Each nominal entry case is replicated over heading offsets';
            'This stage freezes scope only, without running search'
            };
    
        % ============================================================
        % Save summary table
        % ============================================================
        summary_table = table( ...
            string(spec.family_type), ...
            string(spec.heading_mode), ...
            nominal_count, ...
            n_heading, ...
            expected_family_size, ...
            spec.h_fixed_km, ...
            gamma_req, ...
            cfg.stage06.require_D_G_min, ...
            cfg.stage06.require_pass_ratio, ...
            self_check.all_ok, ...
            'VariableNames', { ...
            'family_type', ...
            'heading_mode', ...
            'nominal_case_count', ...
            'n_heading_offsets', ...
            'expected_family_size', ...
            'h_fixed_km', ...
            'gamma_req', ...
            'require_D_G_min', ...
            'require_pass_ratio', ...
            'self_check_all_ok'});
    
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_scope_summary_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save cache
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.spec = spec;
        out.self_check = self_check;
        out.summary_table = summary_table;
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage04_file = stage04_file;
        out.files.stage02_file = stage02_file;
        out.files.summary_csv = summary_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_define_heading_scope_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Debug prints
        % ============================================================
        log_msg(log_fid, 'INFO', 'Stage06 family_type      = %s', spec.family_type);
        log_msg(log_fid, 'INFO', 'Stage06 heading_mode     = %s', spec.heading_mode);
        log_msg(log_fid, 'INFO', 'Heading offsets (deg)    = %s', mat2str(spec.heading_offsets_deg));
        log_msg(log_fid, 'INFO', 'Expected family size     = %d', spec.expected_family_size);
        log_msg(log_fid, 'INFO', 'h_fixed_km               = %.1f', spec.h_fixed_km);
        log_msg(log_fid, 'INFO', 'i_grid_deg               = %s', mat2str(spec.i_grid_deg));
        log_msg(log_fid, 'INFO', 'P_grid                   = %s', mat2str(spec.P_grid));
        log_msg(log_fid, 'INFO', 'T_grid                   = %s', mat2str(spec.T_grid));
        log_msg(log_fid, 'INFO', 'Criteria: D_G_min >= %.3f, pass_ratio >= %.3f', ...
            spec.require_D_G_min, spec.require_pass_ratio);
        log_msg(log_fid, 'INFO', 'Self-check all ok = %d', self_check.all_ok);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to      : %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage06.1 finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.1 Summary ==========\n');
        fprintf('Stage04 cache      : %s\n', stage04_file);
        fprintf('Stage02 cache      : %s\n', stage02_file);
        fprintf('Log file           : %s\n', log_file);
        fprintf('Heading mode       : %s\n', spec.heading_mode);
        fprintf('Heading offsets    : %s\n', mat2str(spec.heading_offsets_deg));
        fprintf('Nominal case count : %d\n', nominal_count);
        fprintf('Expected family sz : %d\n', expected_family_size);
        fprintf('h_fixed_km         : %.1f\n', spec.h_fixed_km);
        fprintf('gamma_req          : %.6e\n', gamma_req);
        fprintf('Summary CSV        : %s\n', summary_csv);
        fprintf('Cache file         : %s\n', cache_file);
        fprintf('Self-check all ok  : %d\n', self_check.all_ok);
        fprintf('=======================================\n');
    end
