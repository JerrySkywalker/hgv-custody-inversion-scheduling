function out = stage03_visibility_pipeline()
    %STAGE03_VISIBILITY_PIPELINE
    % Build single-layer Walker baseline and compute visibility pipeline
    % for Stage02 trajectory bank.
    
        startup();
        cfg = default_params();
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

        % Assume Stage02 uses a common sampling step
        dt = cfg.stage02.Ts_s;
        t_s_common = (0:dt:t_max).';

        walker = build_single_layer_walker_stage03(cfg);
        satbank = propagate_constellation_stage03(walker, t_s_common);

        log_msg(log_fid, 'INFO', ...
            'Walker baseline built: h=%.1f km, i=%.1f deg, P=%d, T=%d, Ns=%d, Nt=%d', ...
            walker.h_km, walker.i_deg, walker.P, walker.T, walker.Ns, numel(t_s_common));
    
        % ------------------------------------------------------------
        % Run all families
        % ------------------------------------------------------------
        visbank = struct();
        visbank.nominal = local_run_family(trajbank.nominal, satbank, cfg, log_fid);
        visbank.heading = local_run_family(trajbank.heading, satbank, cfg, log_fid);
        visbank.critical = local_run_family(trajbank.critical, satbank, cfg, log_fid);
    
        summary_extra = summarize_visibility_bank_stage03(visbank);
    
        % ------------------------------------------------------------
        % Example plot
        % ------------------------------------------------------------
        fig_file = '';
        if cfg.stage03.make_plot
            example_vis = local_find_case(visbank, cfg.stage03.example_case_id);
            fig = plot_visibility_case_stage03(example_vis.vis_case, example_vis.los_geom, cfg);
    
            fig_file = fullfile(cfg.paths.figs, ...
                sprintf('stage03_visibility_case_%s_%s.png', cfg.stage03.example_case_id, datestr(now, 'yyyymmdd_HHMMSS')));
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
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage03_visibility_pipeline_%s.mat', datestr(now, 'yyyymmdd_HHMMSS')));
        save(cache_file, 'out', '-v7.3');
    
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage03 finished.');
    
        fprintf('\n');
        fprintf('========== Stage03 Summary ==========\n');
        fprintf('Log file  : %s\n', out.log_file);
        fprintf('Figure    : %s\n', out.fig_file);
        fprintf('Cache     : %s\n', cache_file);
        fprintf('=====================================\n');
    end
    
    function family_out = local_run_family(trajs_in, satbank, cfg, log_fid)
        family_out = repmat(struct('case_id', [], 'family', [], 'subfamily', [], ...
                                   'vis_case', [], 'los_geom', [], 'summary', []), numel(trajs_in), 1);
    
        for k = 1:numel(trajs_in)
            traj_case = trajs_in(k);
            vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg);
            los_geom = compute_los_geometry_stage03(vis_case, satbank);
            s = summarize_visibility_case_stage03(vis_case, los_geom);
    
            family_out(k).case_id = traj_case.case.case_id;
            family_out(k).family = traj_case.case.family;
            family_out(k).subfamily = traj_case.case.subfamily;
            family_out(k).vis_case = vis_case;
            family_out(k).los_geom = los_geom;
            family_out(k).summary = s;
    
            log_msg(log_fid, 'INFO', ...
                'Case %-24s | mean_vis=%.2f | dual_ratio=%.3f | min_LOS=%.2f deg', ...
                s.case_id, s.mean_num_visible, s.dual_coverage_ratio, s.min_los_crossing_angle_deg);
        end
    end
    
    function hit = local_find_case(visbank, case_id)
        all_structs = [visbank.nominal; visbank.heading; visbank.critical];
        idx = find(strcmp(string({all_structs.case_id}), string(case_id)), 1, 'first');
        assert(~isempty(idx), 'Case %s not found in visbank.', case_id);
        hit = all_structs(idx);
    end