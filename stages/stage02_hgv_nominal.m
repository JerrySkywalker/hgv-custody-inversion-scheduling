function out = stage02_hgv_nominal(cfg, opts)
    %STAGE02_HGV_NOMINAL
    % Fresh-start Stage02 using VTC HGV dynamics with open-loop profiles.
    %
    % Stage04G.4 upgrade:
    %   - trajectory output now includes ENU / ECEF / ECI coordinates
    %   - casebank loaded from Stage01 geodetic-anchor version naturally propagates
    %   - summary / plots remain backward-compatible
    %
    % Outputs:
    %   out.casebank
    %   out.trajbank
    %   out.summary.family_summary
    %   out.summary.heading_summary
    %   out.summary.critical_summary
    %   out.fig_file
    %   out.fig3d_file
    
        % ------------------------------------------------------------
        % Init
        % ------------------------------------------------------------
        local_ensure_startup_once();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2
            opts = struct();
        end
        opts = local_normalize_opts(cfg, opts);
        cfg = local_apply_opts_to_cfg(cfg, opts);
    
        assert(isfield(cfg, 'stage01'), 'Missing cfg.stage01 in default_params().');
        assert(isfield(cfg, 'stage02'), 'Missing cfg.stage02 in default_params().');
    
        cfg.project_stage = 'stage02_hgv_nominal';
        seed_rng(cfg.random.seed);
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.figs);
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage02_hgv_nominal_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage02 started.');
    
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            log_msg(log_fid, 'INFO', 'Scene mode = %s', cfg.meta.scene_mode);
        end
        if isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
            log_msg(log_fid, 'INFO', ...
                'Geodetic anchor enabled: lat=%.3f deg, lon=%.3f deg, h=%.1f m', ...
                cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m);
            log_msg(log_fid, 'INFO', 'Epoch UTC = %s', cfg.time.epoch_utc);
        end
    
        % ------------------------------------------------------------
        % Load latest Stage01 cache
        % ------------------------------------------------------------
        [casebank, stage01_file] = local_load_latest_stage01_casebank(cfg);
    
        log_msg(log_fid, 'INFO', 'Loaded Stage01 cache: %s', stage01_file);
        n_total_stage01 = local_count_casebank(casebank);
        log_msg(log_fid, 'INFO', 'Total cases: %d', n_total_stage01);
    
        % ------------------------------------------------------------
        % Run families
        % ------------------------------------------------------------
        pool = local_prepare_parallel_pool(cfg, log_fid, 'stage02');
        trajbank = local_run_casebank(casebank, cfg, log_fid, pool);
    
        % ------------------------------------------------------------
        % Build structured summaries
        % ------------------------------------------------------------
        summary_extra = summarize_trajbank_stage02(trajbank);
    
        log_msg(log_fid, 'INFO', 'Family summary rows: %d', height(summary_extra.family_summary));
        log_msg(log_fid, 'INFO', 'Heading summary rows: %d', height(summary_extra.heading_summary));
        log_msg(log_fid, 'INFO', 'Critical summary rows: %d', height(summary_extra.critical_summary));
    
        % ------------------------------------------------------------
        % Count pass/fail
        % ------------------------------------------------------------
        all_structs = [trajbank.nominal; trajbank.heading; trajbank.critical];
        pass_flags = arrayfun(@(s) s.validation.pass, all_structs);
    
        num_pass = sum(pass_flags);
        num_fail = numel(pass_flags) - num_pass;
    
        log_msg(log_fid, 'INFO', 'Trajectory propagation finished.');
        log_msg(log_fid, 'INFO', 'Pass cases: %d', num_pass);
        log_msg(log_fid, 'INFO', 'Fail cases: %d', num_fail);
    
        % ------------------------------------------------------------
        % 2D / altitude plot
        % ------------------------------------------------------------
        fig_file = '';
        if isfield(cfg.stage02, 'make_plot') && cfg.stage02.make_plot
            fig = plot_hgv_casebank_stage02(cfg, trajbank);
            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage02_hgv_casebank_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);
            log_msg(log_fid, 'INFO', 'Trajectory plot saved to: %s', fig_file);
        end
    
        % ------------------------------------------------------------
        % 3D explanation plot
        % ------------------------------------------------------------
        fig3d_file = '';
        if isfield(cfg.stage02, 'make_plot_3d') && cfg.stage02.make_plot_3d
            fig3d = plot_hgv_entrypoint_3d_stage02(cfg, trajbank);
            fig3d_file = fullfile(cfg.paths.figs, ...
                sprintf('stage02_hgv_entrypoint_3d_%s.png', datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig3d, fig3d_file, 'Resolution', 180);
            close(fig3d);
            log_msg(log_fid, 'INFO', '3D trajectory plot saved to: %s', fig3d_file);
        end
    
        % ------------------------------------------------------------
        % Save cache
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.casebank = casebank;
        out.trajbank = trajbank;
    
        out.summary = struct();
        out.summary.num_total = numel(all_structs);
        out.summary.num_pass = num_pass;
        out.summary.num_fail = num_fail;
        out.summary.family_summary = summary_extra.family_summary;
        out.summary.heading_summary = summary_extra.heading_summary;
        out.summary.critical_summary = summary_extra.critical_summary;
        out.summary.scene_mode = local_get_scene_mode(cfg);
    
        out.status = ternary(num_fail == 0, 'PASS', 'WARN');
        out.stage = cfg.project_stage;
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.fig3d_file = fig3d_file;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        out.benchmark = struct( ...
            'mode', opts.mode, ...
            'parallel_config', opts.parallel_config);

        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage02_hgv_nominal_%s_%s.mat', opts.mode, datestr(now, 'yyyymmdd_HHMMSS')));
        out.cache_file = cache_file;
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage02 finished.');
    
        % ------------------------------------------------------------
        % Console summary
        % ------------------------------------------------------------
        fprintf('\n');
        fprintf('========== Stage02 Summary ==========\n');
        fprintf('Status      : %s\n', out.status);
        fprintf('Scene mode  : %s\n', out.summary.scene_mode);
        fprintf('Total cases : %d\n', out.summary.num_total);
        fprintf('Pass        : %d\n', out.summary.num_pass);
        fprintf('Fail        : %d\n', out.summary.num_fail);
        fprintf('Log file    : %s\n', out.log_file);
        fprintf('Mode        : %s\n', opts.mode);
        fprintf('Figure 2D   : %s\n', out.fig_file);
        fprintf('Figure 3D   : %s\n', out.fig3d_file);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    % ========================================================================
    % Local helper: run one family
    % ========================================================================
    function trajbank = local_run_casebank(casebank, cfg, log_fid, pool)
        all_cases = [casebank.nominal; casebank.heading; casebank.critical];
        all_tasks = local_prepare_case_tasks(all_cases, cfg);
        all_out = repmat(struct('case', [], 'traj', [], 'validation', [], 'summary', []), numel(all_tasks), 1);

        if ~isempty(pool)
            parfor k = 1:numel(all_tasks)
                all_out(k) = local_eval_case(all_tasks(k).case, cfg, all_tasks(k).hgv_cfg);
            end
        else
            for k = 1:numel(all_tasks)
                all_out(k) = local_eval_case(all_tasks(k).case, cfg, all_tasks(k).hgv_cfg);
            end
        end

        n_nominal = numel(casebank.nominal);
        n_heading = numel(casebank.heading);
        n_critical = numel(casebank.critical);

        idx_nominal = 1:n_nominal;
        idx_heading = n_nominal + (1:n_heading);
        idx_critical = n_nominal + n_heading + (1:n_critical);

        trajbank = struct();
        trajbank.nominal = all_out(idx_nominal);
        trajbank.heading = all_out(idx_heading);
        trajbank.critical = all_out(idx_critical);

        local_log_family('nominal', trajbank.nominal, log_fid, ~isempty(pool), cfg);
        local_log_family('heading', trajbank.heading, log_fid, ~isempty(pool), cfg);
        local_log_family('critical', trajbank.critical, log_fid, ~isempty(pool), cfg);
    end

    function local_log_family(family_name, family_out, log_fid, used_parallel, cfg)
        log_msg(log_fid, 'INFO', ...
            'Family %s processed: %d cases | parallel=%d', ...
            char(string(family_name)), numel(family_out), used_parallel);

        if ~isfield(cfg.stage02, 'log_each_case') || ~cfg.stage02.log_each_case
            return;
        end

        for k = 1:numel(family_out)
            s = family_out(k).summary;
            log_msg(log_fid, 'INFO', ...
                'Case %-24s | family=%-8s | pass=%d | steps=%d | dur=%.1f s | h=[%.1f, %.1f] km | V=[%.0f, %.0f] m/s | rmin=%.1f km', ...
                s.case_id, s.family, s.pass, s.num_steps, s.duration_s, ...
                s.h_range_km(1), s.h_range_km(2), ...
                s.v_range_mps(1), s.v_range_mps(2), ...
                s.r_min_to_center_km);
        end
    end

    function tasks = local_prepare_case_tasks(all_cases, cfg)
        tasks = repmat(struct('case', [], 'hgv_cfg', []), numel(all_cases), 1);
        for k = 1:numel(all_cases)
            tasks(k).case = all_cases(k);
            tasks(k).hgv_cfg = build_hgv_cfg_from_case_stage02(all_cases(k), cfg);
        end
    end

    function case_out = local_eval_case(case_i, cfg, hgv_cfg)
        traj = propagate_hgv_case_stage02(case_i, cfg, hgv_cfg);
        val = validate_hgv_trajectory_stage02(traj, cfg);
        s = summarize_hgv_case_stage02(case_i, traj, val);

        case_out = struct('case', case_i, 'traj', traj, 'validation', val, 'summary', s);
    end
    
    % ========================================================================
    % Local helper: count casebank
    % ========================================================================
    function n = local_count_casebank(casebank)
        n = 0;
        if isfield(casebank, 'nominal');  n = n + numel(casebank.nominal);  end
        if isfield(casebank, 'heading');  n = n + numel(casebank.heading);  end
        if isfield(casebank, 'critical'); n = n + numel(casebank.critical); end
    end
    
    % ========================================================================
    % Local helper: get scene mode
    % ========================================================================
    function scene_mode = local_get_scene_mode(cfg)
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            scene_mode = cfg.meta.scene_mode;
        elseif isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
            scene_mode = 'geodetic';
        else
            scene_mode = 'abstract';
        end
    end
    
    % ========================================================================
    % Local helper: ternary
    % ========================================================================
    function y = ternary(cond, a, b)
        if cond
            y = a;
        else
            y = b;
        end
    end

    function opts = local_normalize_opts(cfg, opts)
        if ~isfield(opts, 'mode') || isempty(opts.mode)
            opts.mode = 'serial';
        end
        opts.mode = char(lower(string(opts.mode)));

        if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
            opts.parallel_config = struct();
        end
        if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
            opts.parallel_config.enabled = strcmp(opts.mode, 'parallel');
        end
        if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
            opts.parallel_config.profile_name = cfg.stage02.parallel_pool_profile;
        end
        if ~isfield(opts.parallel_config, 'num_workers')
            opts.parallel_config.num_workers = cfg.stage02.parallel_num_workers;
        end
        if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
            opts.parallel_config.auto_start_pool = cfg.stage02.auto_start_pool;
        end
    end

    function cfg = local_apply_opts_to_cfg(cfg, opts)
        cfg.stage02.use_parallel = strcmp(opts.mode, 'parallel') && opts.parallel_config.enabled;
        cfg.stage02.parallel_pool_profile = opts.parallel_config.profile_name;
        cfg.stage02.parallel_num_workers = opts.parallel_config.num_workers;
        cfg.stage02.auto_start_pool = opts.parallel_config.auto_start_pool;
    end

    function pool = local_prepare_parallel_pool(cfg, log_fid, stage_name)
        pool = [];

        if ~isfield(cfg, stage_name) || ~isfield(cfg.(stage_name), 'use_parallel') || ...
                ~cfg.(stage_name).use_parallel
            log_msg(log_fid, 'INFO', 'Parallel mode disabled for %s.', stage_name);
            return;
        end

        try
            if isfield(cfg.(stage_name), 'auto_start_pool') && cfg.(stage_name).auto_start_pool
                requested_profile = char(string(cfg.(stage_name).parallel_pool_profile));
                pool = ensure_parallel_pool(requested_profile, cfg.(stage_name).parallel_num_workers);
            else
                pool = gcp('nocreate');
                if isempty(pool)
                    error(['cfg.' stage_name '.use_parallel=true but no parallel pool exists.']);
                end
            end

            log_msg(log_fid, 'INFO', 'Parallel mode enabled for %s: %s', ...
                stage_name, get_parallel_pool_desc(pool, string(cfg.(stage_name).parallel_pool_profile)));
        catch ME
            pool = [];
            log_msg(log_fid, 'INFO', ...
                'Parallel pool unavailable for %s. Fallback to serial. Reason: %s', ...
                stage_name, ME.message);
        end
    end

    function [casebank, stage01_file] = local_load_latest_stage01_casebank(cfg)
        persistent cached_stage01_file cached_casebank

        d = dir(fullfile(cfg.paths.cache, 'stage01_scenario_disk_*.mat'));
        assert(~isempty(d), 'No Stage01 cache found. Please run stage01_scenario_disk first.');

        [~, idx_latest] = max([d.datenum]);
        stage01_file = fullfile(d(idx_latest).folder, d(idx_latest).name);

        if ~isempty(cached_stage01_file) && strcmp(cached_stage01_file, stage01_file)
            casebank = cached_casebank;
            return;
        end

        tmp = load(stage01_file);
        assert(isfield(tmp, 'out') && isfield(tmp.out, 'casebank'), ...
            'Invalid Stage01 cache format: missing out.casebank');

        casebank = tmp.out.casebank;
        cached_stage01_file = stage01_file;
        cached_casebank = casebank;
    end

    function local_ensure_startup_once()
        persistent startup_done
        if isempty(startup_done) || ~startup_done
            startup();
            startup_done = true;
        end
    end
