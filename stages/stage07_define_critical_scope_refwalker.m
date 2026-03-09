function out = stage07_define_critical_scope_refwalker(cfg)
    %STAGE07_DEFINE_CRITICAL_SCOPE_REFWALKER
    % Stage07.2:
    %   Define critical-geometry scope relative to one fixed reference Walker.
    %
    % Main tasks:
    %   1) load latest Stage07.1 reference Walker cache
    %   2) build Stage07 critical scope/spec relative to that Walker
    %   3) freeze C1/C2 definitions and heading-scan settings
    %   4) save summary table / cache
    %
    % Outputs:
    %   out.reference_walker
    %   out.spec
    %   out.summary_table
    %   out.files
    %
    % Notes:
    %   - This stage does NOT generate cases
    %   - This stage does NOT evaluate geometry
    %   - It only fixes the relative definitions for later Stage07 stages
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_define_critical_scope_refwalker';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        run_tag = char(cfg.stage07.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_define_critical_scope_refwalker_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.2 started.');
    
        % ============================================================
        % Load latest Stage07.1 reference Walker
        % ============================================================
        d71 = dir(fullfile(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_*.mat', run_tag)));
        assert(~isempty(d71), ...
            'No Stage07.1 reference-Walker cache found for run_tag=%s.', run_tag);
    
        [~, idx71] = max([d71.datenum]);
        stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);
        S71 = load(stage07_ref_file);
    
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache: missing out.reference_walker');
    
        reference_walker = S71.out.reference_walker;
        log_msg(log_fid, 'INFO', 'Loaded Stage07.1 reference Walker: %s', stage07_ref_file);
    
        % ============================================================
        % Build heading scan grid
        % ============================================================
        heading_offsets_deg = local_build_heading_offset_grid(cfg.stage07.heading_scan);
        n_heading_offset = numel(heading_offsets_deg);
    
        % ============================================================
        % Build critical scope/spec
        % ============================================================
        spec = struct();
    
        spec.run_tag = string(run_tag);
        spec.family_type = "critical_geometry_refwalker";
        spec.is_reference_relative = logical(cfg.stage07.is_reference_relative);
    
        spec.reference_walker = reference_walker;
        spec.gamma_req = reference_walker.gamma_req;
    
        % ---------- C1 ----------
        spec.C1 = struct();
        spec.C1.mode_id = string(cfg.stage07.C1.mode_id);
        spec.C1.description = string(cfg.stage07.C1.description);
        spec.C1.selection_rule = string(cfg.stage07.C1.selection_rule);
        spec.C1.use_both_branches = logical(cfg.stage07.C1.use_both_branches);
        spec.C1.keep_nearest_branch_only = logical(cfg.stage07.C1.keep_nearest_branch_only);
        spec.C1.max_branch_count = cfg.stage07.C1.max_branch_count;
    
        % Reference-dependent interpretation:
        % local track-plane heading is computed from reference_walker.i_deg
        spec.C1.reference_inclination_deg = reference_walker.i_deg;
        spec.C1.reference_altitude_km = reference_walker.h_km;
        spec.C1.reference_plane_count = reference_walker.P;
        spec.C1.reference_sat_per_plane = reference_walker.T;
    
        % ---------- C2 ----------
        spec.C2 = struct();
        spec.C2.mode_id = string(cfg.stage07.C2.mode_id);
        spec.C2.description = string(cfg.stage07.C2.description);
        spec.C2.selection_rule = string(cfg.stage07.C2.selection_rule);
        spec.C2.use_scan = logical(cfg.stage07.C2.use_scan);
        spec.C2.require_high_coverage = cfg.stage07.C2.require_high_coverage;
        spec.C2.primary_objective = string(cfg.stage07.C2.primary_objective);
        spec.C2.secondary_objective = string(cfg.stage07.C2.secondary_objective);
        spec.C2.tertiary_objective = string(cfg.stage07.C2.tertiary_objective);
        spec.C2.allow_fallback_nominal = logical(cfg.stage07.C2.allow_fallback_nominal);
    
        % ---------- Heading scan ----------
        spec.heading_scan = struct();
        spec.heading_scan.enable = logical(cfg.stage07.heading_scan.enable);
        spec.heading_scan.step_deg = cfg.stage07.heading_scan.step_deg;
        spec.heading_scan.max_abs_offset_deg = cfg.stage07.heading_scan.max_abs_offset_deg;
        spec.heading_scan.offset_grid_deg = heading_offsets_deg(:).';
        spec.heading_scan.n_heading_offset = n_heading_offset;
        spec.heading_scan.wrap_mode = string(cfg.stage07.heading_scan.wrap_mode);
    
        % ---------- Danger thresholds ----------
        spec.danger = struct();
        spec.danger.coverage_good_threshold = cfg.stage07.danger.coverage_good_threshold;
        spec.danger.angle_bad_threshold_deg = cfg.stage07.danger.angle_bad_threshold_deg;
        spec.danger.D_G_bad_threshold = cfg.stage07.danger.D_G_bad_threshold;
        spec.danger.lambda_bad_factor = cfg.stage07.danger.lambda_bad_factor;
    
        % ---------- Entry sampling ----------
        spec.entry_sampling = struct();
        spec.entry_sampling.enable = logical(cfg.stage07.entry_sampling.enable);
        spec.entry_sampling.max_entry_count = cfg.stage07.entry_sampling.max_entry_count;
        spec.entry_sampling.rule = string(cfg.stage07.entry_sampling.rule);
    
        % ============================================================
        % Self-check
        % ============================================================
        self_check = struct();
        self_check.has_reference_walker = ~isempty(reference_walker);
        self_check.reference_relative = logical(spec.is_reference_relative);
        self_check.has_gamma_req = isfield(reference_walker, 'gamma_req') && isfinite(reference_walker.gamma_req);
        self_check.has_heading_scan = n_heading_offset >= 3;
        self_check.C1_relative_to_ref = isfield(spec.C1, 'reference_inclination_deg') && ...
                                        isfinite(spec.C1.reference_inclination_deg);
        self_check.C2_scan_enabled = logical(spec.C2.use_scan);
        self_check.C2_no_silent_fallback = ~logical(spec.C2.allow_fallback_nominal);
    
        self_check.all_ok = self_check.has_reference_walker && ...
                            self_check.reference_relative && ...
                            self_check.has_gamma_req && ...
                            self_check.has_heading_scan && ...
                            self_check.C1_relative_to_ref && ...
                            self_check.C2_scan_enabled && ...
                            self_check.C2_no_silent_fallback;
    
        % ============================================================
        % Build summary table
        % ============================================================
        summary_table = table( ...
            string(spec.family_type), ...
            string(reference_walker.selection_rule), ...
            reference_walker.h_km, ...
            reference_walker.i_deg, ...
            reference_walker.P, ...
            reference_walker.T, ...
            reference_walker.F, ...
            reference_walker.Ns, ...
            reference_walker.D_G_min, ...
            reference_walker.pass_ratio, ...
            reference_walker.gamma_req, ...
            n_heading_offset, ...
            spec.C2.require_high_coverage, ...
            spec.danger.angle_bad_threshold_deg, ...
            self_check.all_ok, ...
            'VariableNames', { ...
                'family_type', ...
                'reference_selection_rule', ...
                'h_km', ...
                'i_deg', ...
                'P', ...
                'T', ...
                'F', ...
                'Ns', ...
                'D_G_min', ...
                'pass_ratio', ...
                'gamma_req', ...
                'n_heading_offset', ...
                'C2_require_high_coverage', ...
                'angle_bad_threshold_deg', ...
                'self_check_all_ok'});
    
        % ============================================================
        % Save outputs
        % ============================================================
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_critical_scope_refwalker_summary_%s_%s.csv', run_tag, timestamp));
    
        heading_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_critical_scope_refwalker_heading_grid_%s_%s.csv', run_tag, timestamp));
    
        heading_table = table(heading_offsets_deg(:), ...
            'VariableNames', {'heading_offset_deg'});
    
        writetable(summary_table, summary_csv);
        writetable(heading_table, heading_csv);
    
        out = struct();
        out.cfg = cfg;
        out.reference_walker = reference_walker;
        out.spec = spec;
        out.self_check = self_check;
        out.summary_table = summary_table;
        out.heading_table = heading_table;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage07_ref_file = stage07_ref_file;
        out.files.summary_csv = summary_csv;
        out.files.heading_csv = heading_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_define_critical_scope_refwalker_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logs
        % ============================================================
        log_msg(log_fid, 'INFO', 'Reference Walker source: %s', stage07_ref_file);
        log_msg(log_fid, 'INFO', ...
            'Reference Walker = h=%.1f km | i=%.1f deg | P=%d | T=%d | F=%d | Ns=%d', ...
            reference_walker.h_km, reference_walker.i_deg, ...
            reference_walker.P, reference_walker.T, reference_walker.F, reference_walker.Ns);
        log_msg(log_fid, 'INFO', ...
            'C1 mode = %s | relative inclination = %.1f deg', ...
            char(spec.C1.mode_id), spec.C1.reference_inclination_deg);
        log_msg(log_fid, 'INFO', ...
            'C2 mode = %s | heading scan count = %d | high-coverage threshold = %.3f', ...
            char(spec.C2.mode_id), n_heading_offset, spec.C2.require_high_coverage);
        log_msg(log_fid, 'INFO', 'Self-check all ok = %d', self_check.all_ok);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Heading CSV saved to: %s', heading_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.2 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.2 Summary ==========\n');
        fprintf('Stage07.1 reference  : %s\n', stage07_ref_file);
        fprintf('Reference Walker     : h=%.1f km | i=%.1f deg | P=%d | T=%d | F=%d | Ns=%d\n', ...
            reference_walker.h_km, reference_walker.i_deg, ...
            reference_walker.P, reference_walker.T, reference_walker.F, reference_walker.Ns);
        fprintf('C1 mode              : %s\n', char(spec.C1.mode_id));
        fprintf('C2 mode              : %s\n', char(spec.C2.mode_id));
        fprintf('Heading offset count : %d\n', n_heading_offset);
        fprintf('gamma_req            : %.6e\n', reference_walker.gamma_req);
        fprintf('Summary CSV          : %s\n', summary_csv);
        fprintf('Heading CSV          : %s\n', heading_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('Self-check all ok    : %d\n', self_check.all_ok);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function heading_offsets_deg = local_build_heading_offset_grid(scan_cfg)
    
        assert(scan_cfg.enable, 'cfg.stage07.heading_scan.enable must be true.');
    
        step_deg = scan_cfg.step_deg;
        max_abs_deg = scan_cfg.max_abs_offset_deg;
    
        assert(step_deg > 0, 'heading scan step_deg must be positive.');
        assert(max_abs_deg > 0, 'heading scan max_abs_offset_deg must be positive.');
    
        heading_offsets_deg = (-max_abs_deg):step_deg:(max_abs_deg);
    
        if ~any(abs(heading_offsets_deg) < 1e-12)
            heading_offsets_deg = unique([heading_offsets_deg, 0], 'sorted');
        end
    end