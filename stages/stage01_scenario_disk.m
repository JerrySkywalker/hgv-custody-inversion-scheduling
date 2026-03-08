function out = stage01_scenario_disk()
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
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage01_scenario_disk';
    
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
        casebank = build_casebank_stage01(cfg);
    
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
        fig = local_plot_stage01(casebank, cfg);
        fig_file = fullfile(cfg.paths.figs, sprintf('stage01_scenario_scheme_%s.png', ts));
        exportgraphics(fig, fig_file, 'Resolution', 180);
        close(fig);
        log_msg(log_fid, 'INFO', 'Scenario plot saved to: %s', fig_file);
    
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
    
        cache_file = fullfile(cfg.paths.cache, sprintf('stage01_scenario_disk_%s.mat', ts));
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
        fprintf('Figure      : %s\n', fig_file);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    %% ========================================================================
    % Local helpers
    % ========================================================================
    
    function fig = local_plot_stage01(casebank, cfg)
    
        fig = figure('Color', 'w', 'Position', [100,100,960,860]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    
        R_D  = cfg.stage01.R_D_km;
        R_in = cfg.stage01.R_in_km;
    
        th = linspace(0, 2*pi, 400);
        plot(ax, R_D*cos(th),  R_D*sin(th),  'LineWidth', 2.2);
        plot(ax, R_in*cos(th), R_in*sin(th), '--', 'LineWidth', 1.8);
    
        scatter(ax, 0, 0, 70, 'filled');
    
        % nominal cases
        for k = 1:numel(casebank.nominal)
            c = casebank.nominal(k);
            p = c.entry_point_enu_km(:).';
            scatter(ax, p(1), p(2), 28, 'filled');
    
            u = c.heading_unit_enu(:).';
            quiver(ax, p(1), p(2), 1100*u(1), 1100*u(2), 0, ...
                'LineWidth', 1.2, 'MaxHeadSize', 0.45);
        end
    
        % heading fan around first nominal point
        if ~isempty(casebank.heading)
            ids = string({casebank.heading.case_id});
            idx = startsWith(ids, "H01_");
            H = casebank.heading(idx);
            if isempty(H)
                H = casebank.heading(1:min(5, numel(casebank.heading)));
            end
            p = H(1).entry_point_enu_km(:).';
            for i = 1:numel(H)
                u = H(i).heading_unit_enu(:).';
                quiver(ax, p(1), p(2), 1300*u(1), 1300*u(2), 0, ...
                    'LineWidth', 1.1, 'MaxHeadSize', 0.45);
            end
        end
    
        % critical
        for k = 1:numel(casebank.critical)
            c = casebank.critical(k);
            p = c.entry_point_enu_km(:).';
            u = c.heading_unit_enu(:).';
            quiver(ax, p(1), p(2), 1600*u(1), 1600*u(2), 0, ...
                'LineWidth', 1.8, 'MaxHeadSize', 0.5);
            text(ax, p(1)+120, p(2)+120, strrep(c.case_id, '_', '\_'), 'Interpreter', 'tex');
        end
    
        axis(ax, 'equal');
        xlim(ax, [-5500, 5500]);
        ylim(ax, [-5500, 5500]);
        xlabel(ax, 'Regional ENU east (km)', 'Interpreter', 'none');
        ylabel(ax, 'Regional ENU north (km)', 'Interpreter', 'none');
    
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            title(ax, sprintf('Scenario design (%s mode)', cfg.meta.scene_mode), 'Interpreter', 'none');
        end
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