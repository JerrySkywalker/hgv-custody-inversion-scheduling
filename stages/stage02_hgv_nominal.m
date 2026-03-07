function out = stage02_hgv_nominal()
    %STAGE02_HGV_NOMINAL
    % Fresh-start Stage02 using VTC HGV dynamics with open-loop profiles.
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
        startup();
        cfg = default_params();
    
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
    
        % ------------------------------------------------------------
        % Load latest Stage01 cache
        % ------------------------------------------------------------
        d = dir(fullfile(cfg.paths.cache, 'stage01_scenario_disk_*.mat'));
        assert(~isempty(d), 'No Stage01 cache found. Please run stage01_scenario_disk first.');
    
        [~, idx_latest] = max([d.datenum]);
        stage01_file = fullfile(d(idx_latest).folder, d(idx_latest).name);
    
        tmp = load(stage01_file);
        assert(isfield(tmp, 'out') && isfield(tmp.out, 'casebank'), ...
            'Invalid Stage01 cache format: missing out.casebank');
    
        casebank = tmp.out.casebank;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage01 cache: %s', stage01_file);
        log_msg(log_fid, 'INFO', 'Total cases: %d', casebank.summary.num_total);
    
        % ------------------------------------------------------------
        % Run families
        % ------------------------------------------------------------
        trajbank = struct();
        trajbank.nominal = local_run_family(casebank.nominal, cfg, log_fid);
        trajbank.heading = local_run_family(casebank.heading, cfg, log_fid);
        trajbank.critical = local_run_family(casebank.critical, cfg, log_fid);
    
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
    
        out.status = ternary(num_fail == 0, 'PASS', 'WARN');
        out.stage = cfg.project_stage;
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.fig3d_file = fig3d_file;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage02_hgv_nominal_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage02 finished.');
    
        % ------------------------------------------------------------
        % Console summary
        % ------------------------------------------------------------
        fprintf('\n');
        fprintf('========== Stage02 Summary ==========\n');
        fprintf('Status      : %s\n', out.status);
        fprintf('Total cases : %d\n', out.summary.num_total);
        fprintf('Pass        : %d\n', out.summary.num_pass);
        fprintf('Fail        : %d\n', out.summary.num_fail);
        fprintf('Log file    : %s\n', out.log_file);
        fprintf('Figure 2D   : %s\n', out.fig_file);
        fprintf('Figure 3D   : %s\n', out.fig3d_file);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    % ========================================================================
    % Local helper: run one family
    % ========================================================================
    function family_out = local_run_family(cases_in, cfg, log_fid)
    
        if isempty(cases_in)
            family_out = struct('case', {}, 'traj', {}, 'validation', {}, 'summary', {});
            return;
        end
    
        family_out = repmat(struct('case', [], 'traj', [], 'validation', [], 'summary', []), numel(cases_in), 1);
    
        for k = 1:numel(cases_in)
            case_i = cases_in(k);
    
            traj = propagate_hgv_case_stage02(case_i, cfg);
            val = validate_hgv_trajectory_stage02(traj, cfg);
            s = summarize_hgv_case_stage02(case_i, traj, val);
    
            family_out(k).case = case_i;
            family_out(k).traj = traj;
            family_out(k).validation = val;
            family_out(k).summary = s;
    
            log_msg(log_fid, 'INFO', ...
                'Case %-24s | family=%-8s | pass=%d | steps=%d | dur=%.1f s | h=[%.1f, %.1f] km | V=[%.0f, %.0f] m/s | rmin=%.1f km', ...
                s.case_id, s.family, s.pass, s.num_steps, s.duration_s, ...
                s.h_range_km(1), s.h_range_km(2), ...
                s.v_range_mps(1), s.v_range_mps(2), ...
                s.r_min_to_center_km);
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