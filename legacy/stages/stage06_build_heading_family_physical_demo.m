function out = stage06_build_heading_family_physical_demo(cfg)
    %STAGE06_BUILD_HEADING_FAMILY_PHYSICAL_DEMO
    % Demo / self-check for Stage06.2b physical heading perturbation.

        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage06_prepare_cfg(cfg);
        cfg.project_stage = 'stage06_build_heading_family_physical_demo';
        cfg = configure_stage_output_paths(cfg);
        run_tag = char(cfg.stage06.run_tag);

        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);

        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_build_heading_family_physical_demo_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.2b demo started.');
    
        % ------------------------------------------------------------
        % Load latest Stage06.1 scope (by run_tag)
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
        % Build physical family
        % ------------------------------------------------------------
        family_out = stage06_build_heading_family( ...
            trajs_nominal, heading_offsets_deg, ...
            'HeadingMode', spec.heading_mode, ...
            'FamilyType', spec.family_type, ...
            'Cfg', cfg);
    
        n_nominal = numel(trajs_nominal);
        n_heading = numel(heading_offsets_deg);
        n_total = numel(family_out);
    
        assert(n_total == n_nominal * n_heading, ...
            'Family size mismatch.');
    
        % ------------------------------------------------------------
        % Build self-check table:
        % compare first-point and second-point ENU positions
        % ------------------------------------------------------------
        case_id = strings(n_total,1);
        source_case_id = strings(n_total,1);
        entry_id = nan(n_total,1);
        heading_offset_deg = nan(n_total,1);
        heading_deg = nan(n_total,1);
    
        dr0_km = nan(n_total,1);   % should be ~0
        dr1_km = nan(n_total,1);   % should differ for nonzero offsets
        sigma0_deg = nan(n_total,1);
    
        for k = 1:n_total
            item = family_out(k);
    
            case_id(k) = string(item.case.case_id);
            source_case_id(k) = string(item.case.source_case_id);
            entry_id(k) = item.case.entry_id;
            heading_offset_deg(k) = item.case.heading_offset_deg;
            heading_deg(k) = item.case.heading_deg;
    
            src_idx = item.case.entry_id;
            base_item = trajs_nominal(src_idx);
    
            r0_new = item.traj.r_enu_km(1,:);
            r0_old = base_item.traj.r_enu_km(1,:);
            dr0_km(k) = norm(r0_new - r0_old);
    
            if size(item.traj.r_enu_km,1) >= 2 && size(base_item.traj.r_enu_km,1) >= 2
                r1_new = item.traj.r_enu_km(2,:);
                r1_old = base_item.traj.r_enu_km(2,:);
                dr1_km(k) = norm(r1_new - r1_old);
            end
    
            if isfield(item.traj, 'meta') && isfield(item.traj.meta, 'sigma0_deg')
                sigma0_deg(k) = item.traj.meta.sigma0_deg;
            end
        end
    
        check_table = table( ...
            case_id, source_case_id, entry_id, ...
            heading_offset_deg, heading_deg, sigma0_deg, ...
            dr0_km, dr1_km);
    
        summary_table = table();
        summary_table.n_nominal = n_nominal;
        summary_table.n_heading_offsets = n_heading;
        summary_table.family_size = n_total;
        summary_table.max_dr0_km = max(dr0_km, [], 'omitnan');
        summary_table.mean_dr0_km = mean(dr0_km, 'omitnan');
        summary_table.mean_dr1_km_nonzero = mean(dr1_km(abs(heading_offset_deg) > 0), 'omitnan');
    
        check_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_family_physical_check_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_heading_family_physical_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(check_table, check_csv);
        writetable(summary_table, summary_csv);
    
        out = struct();
        out.family_out = family_out;
        out.check_table = check_table;
        out.summary_table = summary_table;
        out.stage02_file = stage02_file;
        out.stage06_scope_file = stage06_scope_file;
        out.log_file = log_file;
        out.files = struct();
        out.files.check_csv = check_csv;
        out.files.summary_csv = summary_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_build_heading_family_physical_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Family size = %d', n_total);
        log_msg(log_fid, 'INFO', 'max_dr0_km = %.6e', summary_table.max_dr0_km);
        log_msg(log_fid, 'INFO', 'mean_dr1_km_nonzero = %.6e', summary_table.mean_dr1_km_nonzero);
        log_msg(log_fid, 'INFO', 'Stage06.2b demo finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.2b Summary ==========\n');
        fprintf('Family size            : %d\n', n_total);
        fprintf('max dr0 (km)           : %.6e\n', summary_table.max_dr0_km);
        fprintf('mean dr1 nonzero (km)  : %.6e\n', summary_table.mean_dr1_km_nonzero);
        fprintf('Check CSV              : %s\n', check_csv);
        fprintf('Summary CSV            : %s\n', summary_csv);
        fprintf('Cache                  : %s\n', cache_file);
        fprintf('========================================\n');
    end
