function out = stage01_scenario_disk(cfg, opts)
    %STAGE01_SCENARIO_DISK
    % Build abstract protected-disk scenario with optional geodetic anchor.
    %
    % Stage04G.3 upgrade:
    %   - casebank keeps local ENU fields for backward compatibility
    %   - when cfg.geo.enable_geodetic_anchor = true, each case additionally stores:
    %       entry_point_enu_m / km
    %       entry_point_ecef_m / km
    %       entry_point_eci_m_t0 / km
    %       heading_unit_enu / ecef_t0 / eci_t0
    %
    % Output:
    %   out.casebank
    %   out.summary
    %   out.fig_file
    %   out.status
    
        % ------------------------------------------------------------
        % Init
        % ------------------------------------------------------------
        cfg_missing = (nargin < 1 || isempty(cfg));
        if cfg_missing
            evalc('startup(''force'', false);');
            cfg = default_params();
        end
        if nargin < 2
            opts = struct();
        end
        opts = local_normalize_opts(cfg, opts);
        cfg.project_stage = 'stage01_scenario_disk';
        cfg = configure_stage_output_paths(cfg);
    
        if exist('seed_rng', 'file') == 2
            seed_rng(cfg.random.seed);
        end
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.figs);
    
        ts = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, sprintf('stage01_scenario_disk_%s.log', ts));
        log_fid = fopen(log_file, 'w');
        assert(log_fid > 0, 'Failed to open log file: %s', log_file);
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage01 started.');
        log_msg(log_fid, 'INFO', 'Protected disk radius R_D = %.1f km', cfg.stage01.R_D_km);
        log_msg(log_fid, 'INFO', 'Entry boundary radius R_in = %.1f km', cfg.stage01.R_in_km);
    
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            log_msg(log_fid, 'INFO', 'Scene mode = %s', cfg.meta.scene_mode);
        end
        if isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
            log_msg(log_fid, 'INFO', ...
                'Geodetic anchor enabled: lat=%.3f deg, lon=%.3f deg, h=%.1f m', ...
                cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m);
            log_msg(log_fid, 'INFO', 'Epoch UTC = %s', cfg.time.epoch_utc);
        else
            log_msg(log_fid, 'INFO', 'Geodetic anchor disabled; using abstract regional frame.');
        end
    
        % ------------------------------------------------------------
        % Build casebank
        % ------------------------------------------------------------
        casebank = build_casebank_stage01(cfg, opts);
    
        n_nominal  = numel(casebank.nominal);
        n_heading  = numel(casebank.heading);
        n_critical = numel(casebank.critical);
        n_total    = n_nominal + n_heading + n_critical;
    
        log_msg(log_fid, 'INFO', 'Nominal cases  : %d', n_nominal);
        log_msg(log_fid, 'INFO', 'Heading cases  : %d', n_heading);
        log_msg(log_fid, 'INFO', 'Critical cases : %d', n_critical);
        log_msg(log_fid, 'INFO', 'Total cases    : %d', n_total);
    
        % basic validation
        assert(n_nominal > 0, 'No nominal cases generated.');
        assert(n_heading > 0, 'No heading cases generated.');
        assert(n_critical > 0, 'No critical cases generated.');
        log_msg(log_fid, 'INFO', 'Basic case-count validation passed.');
    
        % ------------------------------------------------------------
        % Plot
        % ------------------------------------------------------------
        fig_file = '';
        if local_should_make_plot(cfg)
            fig = plot_casebank_stage01(casebank, cfg);
            fig_file = fullfile(cfg.paths.figs, sprintf('stage01_scenario_scheme_%s.png', ts));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);
            log_msg(log_fid, 'INFO', 'Scenario plot saved to: %s', fig_file);
        else
            log_msg(log_fid, 'INFO', 'Scenario plotting skipped (cfg.stage01.make_plot = false).');
        end
    
        % ------------------------------------------------------------
        % Save cache
        % ------------------------------------------------------------
        summary = struct();
        summary.n_nominal  = n_nominal;
        summary.n_heading  = n_heading;
        summary.n_critical = n_critical;
        summary.n_total    = n_total;
        summary.scene_mode = local_get_scene_mode(cfg);
    
        out = struct();
        out.cfg = cfg;
        out.casebank = casebank;
        out.summary = summary;
        out.status = 'PASS';
        out.stage = cfg.project_stage;
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        out.benchmark = struct( ...
            'mode', opts.mode, ...
            'parallel_config', opts.parallel_config);

        cache_file = fullfile(cfg.paths.cache, sprintf('stage01_scenario_disk_%s_%s.mat', opts.mode, ts));
        out.cache_file = cache_file;
        save(cache_file, 'out', '-v7.3');
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage01 finished successfully.');
    
        % ------------------------------------------------------------
        % Console summary
        % ------------------------------------------------------------
        fprintf('\n========== Stage01 Summary ==========\n');
        fprintf('Status      : %s\n', out.status);
        fprintf('Scene mode  : %s\n', summary.scene_mode);
        fprintf('Nominal     : %d\n', n_nominal);
        fprintf('Heading     : %d\n', n_heading);
        fprintf('Critical    : %d\n', n_critical);
        fprintf('Total cases : %d\n', n_total);
        fprintf('Log file    : %s\n', log_file);
        fprintf('Mode        : %s\n', opts.mode);
        if ~isempty(fig_file)
            fprintf('Figure      : %s\n', fig_file);
        else
            fprintf('Figure      : <skipped>\n');
        end
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    %% ========================================================================
    % Local helpers
    % ========================================================================
    
    function tf = local_should_make_plot(cfg)
        tf = isfield(cfg, 'stage01') && ...
            isfield(cfg.stage01, 'make_plot') && ...
            logical(cfg.stage01.make_plot);
    end
    
    function scene_mode = local_get_scene_mode(cfg)
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            scene_mode = cfg.meta.scene_mode;
        elseif isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
            scene_mode = 'geodetic';
        else
            scene_mode = 'abstract';
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
            opts.parallel_config.profile_name = cfg.stage01.parallel_pool_profile;
        end
        if ~isfield(opts.parallel_config, 'num_workers')
            opts.parallel_config.num_workers = cfg.stage01.parallel_num_workers;
        end
        if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
            opts.parallel_config.auto_start_pool = cfg.stage01.auto_start_pool;
        end
    end
