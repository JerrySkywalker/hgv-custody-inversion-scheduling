function out = stage03_visibility_pipeline(cfg, opts)
    %STAGE03_VISIBILITY_PIPELINE
    % Build single-layer Walker baseline and compute visibility pipeline
    % for Stage02 trajectory bank.
    %
    % Stage04G.5:
    %   - use true Stage02 traj.r_eci_km as target inertial trajectory
    %   - keep current project structure unchanged
    %   - keep outputs compatible with Stage04
    
        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        if nargin < 2
            opts = struct();
        end
        opts = local_normalize_opts(cfg, opts);
        cfg = local_apply_opts_to_cfg(cfg, opts);
        cfg.project_stage = 'stage03_visibility_pipeline';
        seed_rng(cfg.random.seed);
    
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.figs);
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage03_visibility_pipeline_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
        log_fid = fopen(log_file, 'w');
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage03 started.');
    
        % ------------------------------------------------------------
        % Load latest Stage02 cache
        % ------------------------------------------------------------
        d = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        assert(~isempty(d), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

        [~, idx_latest] = max([d.datenum]);
        stage02_file = fullfile(d(idx_latest).folder, d(idx_latest).name);

        tmp = load(stage02_file);
        trajbank = tmp.out.trajbank;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
    
        % ------------------------------------------------------------
        % Build a common time grid covering all Stage02 trajectories
        % ------------------------------------------------------------
        all_trajs = [trajbank.nominal; trajbank.heading; trajbank.critical];
        t_end_all = arrayfun(@(s) s.traj.t_s(end), all_trajs);
        t_max = max(t_end_all);
    
        dt = cfg.stage02.Ts_s;
        t_s_common = (0:dt:t_max).';
    
        walker = build_single_layer_walker_stage03(cfg);
        satbank = propagate_constellation_stage03(walker, t_s_common);

        log_msg(log_fid, 'INFO', ...
            'Walker baseline built: h=%.1f km, i=%.1f deg, P=%d, T=%d, Ns=%d, Nt=%d', ...
            walker.h_km, walker.i_deg, walker.P, walker.T, walker.Ns, numel(t_s_common));

        pool = local_prepare_parallel_pool(cfg, log_fid, 'stage03');

        % ------------------------------------------------------------
        % Run all families
        % ------------------------------------------------------------
        visbank = local_run_visbank(trajbank, satbank, cfg, log_fid, pool);
    
        summary_extra = summarize_visibility_bank_stage03(visbank);
    
        % ------------------------------------------------------------
        % Example plot
        % ------------------------------------------------------------
        fig_file = '';
        if cfg.stage03.make_plot
            example_vis = local_find_case(visbank, cfg.stage03.example_case_id);
            fig = plot_visibility_case_stage03(example_vis.vis_case, example_vis.los_geom, cfg);
    
            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage03_visibility_case_%s_%s.png', ...
                cfg.stage03.example_case_id, datestr(now, 'yyyymmdd_HHMMSS')));
            exportgraphics(fig, fig_file, 'Resolution', 180);
            close(fig);
    
            log_msg(log_fid, 'INFO', 'Example visibility plot saved to: %s', fig_file);
        end
    
        % ------------------------------------------------------------
        % Save
        % ------------------------------------------------------------
        out = struct();
        out.cfg = cfg;
        out.walker = walker;
        out.satbank = satbank;
        out.visbank = visbank;
        out.summary = summary_extra;
        out.log_file = log_file;
        out.fig_file = fig_file;
        out.stage = cfg.project_stage;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        out.benchmark = struct( ...
            'mode', opts.mode, ...
            'parallel_config', opts.parallel_config);

        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage03_visibility_pipeline_%s_%s.mat', opts.mode, datestr(now, 'yyyymmdd_HHMMSS')));
        out.cache_file = cache_file;
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage03 finished.');
    
        fprintf('\n');
        fprintf('========== Stage03 Summary ==========\n');
        fprintf('Log file  : %s\n', out.log_file);
        fprintf('Mode      : %s\n', opts.mode);
        fprintf('Figure    : %s\n', out.fig_file);
        fprintf('Cache     : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    %% ========================================================================
    % local helpers
    % ========================================================================
    
    function visbank = local_run_visbank(trajbank, satbank, cfg, log_fid, pool)
        all_trajs = [trajbank.nominal; trajbank.heading; trajbank.critical];
        all_out = repmat(struct('case_id', [], 'family', [], 'subfamily', [], ...
                                'vis_case', [], 'los_geom', [], 'summary', []), numel(all_trajs), 1);
        if ~isempty(pool)
            parfor k = 1:numel(all_trajs)
                all_out(k) = local_eval_visibility_case(all_trajs(k), satbank, cfg);
            end
        else
            for k = 1:numel(all_trajs)
                all_out(k) = local_eval_visibility_case(all_trajs(k), satbank, cfg);
            end
        end

        n_nominal = numel(trajbank.nominal);
        n_heading = numel(trajbank.heading);
        n_critical = numel(trajbank.critical);

        idx_nominal = 1:n_nominal;
        idx_heading = n_nominal + (1:n_heading);
        idx_critical = n_nominal + n_heading + (1:n_critical);

        visbank = struct();
        visbank.nominal = all_out(idx_nominal);
        visbank.heading = all_out(idx_heading);
        visbank.critical = all_out(idx_critical);

        local_log_family('nominal', visbank.nominal, log_fid, ~isempty(pool), cfg);
        local_log_family('heading', visbank.heading, log_fid, ~isempty(pool), cfg);
        local_log_family('critical', visbank.critical, log_fid, ~isempty(pool), cfg);
    end

    function case_out = local_eval_visibility_case(traj_case, satbank, cfg)
        vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg);
        los_geom = compute_los_geometry_stage03(vis_case, satbank);
        s = summarize_visibility_case_stage03(vis_case, los_geom);

        case_out = struct();
        case_out.case_id = traj_case.case.case_id;
        case_out.family = traj_case.case.family;
        case_out.subfamily = traj_case.case.subfamily;
        case_out.vis_case = vis_case;
        case_out.los_geom = los_geom;
        case_out.summary = s;
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

    function local_log_family(family_name, family_out, log_fid, used_parallel, cfg)
        log_msg(log_fid, 'INFO', ...
            'Family %s processed: %d cases | parallel=%d', ...
            char(string(family_name)), numel(family_out), used_parallel);

        if ~isfield(cfg.stage03, 'log_each_case') || ~cfg.stage03.log_each_case
            return;
        end

        for k = 1:numel(family_out)
            s = family_out(k).summary;
            log_msg(log_fid, 'INFO', ...
                'Case %-24s | mean_vis=%.2f | dual_ratio=%.3f | min_LOS=%.2f deg', ...
                s.case_id, s.mean_num_visible, s.dual_coverage_ratio, s.min_los_crossing_angle_deg);
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
            opts.parallel_config.profile_name = cfg.stage03.parallel_pool_profile;
        end
        if ~isfield(opts.parallel_config, 'num_workers')
            opts.parallel_config.num_workers = cfg.stage03.parallel_num_workers;
        end
        if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
            opts.parallel_config.auto_start_pool = cfg.stage03.auto_start_pool;
        end
    end

    function cfg = local_apply_opts_to_cfg(cfg, opts)
        cfg.stage03.use_parallel = strcmp(opts.mode, 'parallel') && opts.parallel_config.enabled;
        cfg.stage03.parallel_pool_profile = opts.parallel_config.profile_name;
        cfg.stage03.parallel_num_workers = opts.parallel_config.num_workers;
        cfg.stage03.auto_start_pool = opts.parallel_config.auto_start_pool;
    end

    function hit = local_find_case(visbank, case_id)
        all_structs = [visbank.nominal; visbank.heading; visbank.critical];
        idx = find(strcmp(string({all_structs.case_id}), string(case_id)), 1, 'first');
        assert(~isempty(idx), 'Case %s not found in visbank.', case_id);
        hit = all_structs(idx);
    end
