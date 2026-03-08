function out = milestone_m1_export_baseline()
    %MILESTONE_M1_EXPORT_BASELINE
    % Export baseline figures/tables/notes for Chapter 4 milestone package.
    %
    % Milestone convention:
    %   - Titles are controlled by a top-level switch
    %   - Default is no in-figure title, suitable for thesis insertion
    %   - Title text is fully overridable from the options block below
    
        %% ============================================================
        % User options (milestone convention)
        % =============================================================
        opt = struct();
    
        % Global switch: show/hide in-figure titles
        opt.show_titles = true;
    
        % Representative case IDs
        opt.visibility_case_id = 'N01';
        opt.window_case_id = 'N01';
    
        % Title text (no stage numbering)
        opt.title_text = struct();
        opt.title_text.scenario        = 'Scenario design';
        opt.title_text.traj2d          = 'Representative trajectories in the regional plane';
        opt.title_text.traj3d          = 'Representative 3D trajectories';
        opt.title_text.visibility      = 'Representative visibility and LOS geometry';
        opt.title_text.window_case     = 'Worst-window spectrum scan for a representative case';
        opt.title_text.window_family   = 'Distribution of worst-window spectrum';
        opt.title_text.margin          = 'Pass ratio under the worst-window criterion';
    
        % Figure export resolution
        opt.resolution = 200;
    
        % =============================================================
        % Init
        % =============================================================
        startup();
        cfg = default_params();
    
        project_root = fileparts(fileparts(mfilename('fullpath')));
    
        out_dirs = struct();
        out_dirs.root   = fullfile(project_root, 'deliverables', 'milestone_m1');
        out_dirs.figs   = fullfile(out_dirs.root, 'figs');
        out_dirs.tables = fullfile(out_dirs.root, 'tables');
        out_dirs.notes  = fullfile(out_dirs.root, 'notes');
    
        local_ensure_dir(out_dirs.root);
        local_ensure_dir(out_dirs.figs);
        local_ensure_dir(out_dirs.tables);
        local_ensure_dir(out_dirs.notes);
    
        fprintf('[M1] Output root  : %s\n', out_dirs.root);
        fprintf('[M1] Figures dir  : %s\n', out_dirs.figs);
        fprintf('[M1] Tables dir   : %s\n', out_dirs.tables);
        fprintf('[M1] Notes dir    : %s\n', out_dirs.notes);
    
        % =============================================================
        % Load latest caches
        % =============================================================
        stage01 = local_load_latest_cache(cfg.paths.cache, 'stage01_scenario_disk_*.mat');
        stage02 = local_load_latest_cache(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        stage03 = local_load_latest_cache(cfg.paths.cache, 'stage03_visibility_pipeline_*.mat');
        stage04 = local_load_latest_cache(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
    
        % =============================================================
        % M1.1 scenario + trajectory baseline
        % =============================================================
        fig1 = local_plot_scenario_m1(stage01.out.casebank, cfg, opt);
        exportgraphics(fig1, fullfile(out_dirs.figs, 'fig_m1_1_scenario.png'), 'Resolution', opt.resolution);
        close(fig1);
    
        fig2 = local_plot_traj2d_m1(stage02.out.trajbank, cfg, opt);
        exportgraphics(fig2, fullfile(out_dirs.figs, 'fig_m1_1_traj_2d.png'), 'Resolution', opt.resolution);
        close(fig2);
    
        fig3 = local_plot_traj3d_m1(stage02.out.trajbank, cfg, opt);
        exportgraphics(fig3, fullfile(out_dirs.figs, 'fig_m1_1_traj_3d.png'), 'Resolution', opt.resolution);
        close(fig3);
    
        tab_case_design = local_build_case_design_table(stage01.out.casebank);
        writetable(tab_case_design, fullfile(out_dirs.tables, 'tab_m1_1_case_design.csv'));
    
        writetable(stage02.out.summary.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_family_summary.csv'));
        writetable(stage02.out.summary.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_heading_summary.csv'));
        writetable(stage02.out.summary.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_1_traj_critical_summary.csv'));
    
        tab_param = local_build_parameter_table(cfg);
        writetable(tab_param, fullfile(out_dirs.tables, 'tab_m1_1_parameter_summary.csv'));
    
        % =============================================================
        % M1.2 visibility baseline
        % =============================================================
        fig4 = local_plot_visibility_case_m1(stage03.out.visbank, stage03.out.satbank, opt.visibility_case_id, opt);
        exportgraphics(fig4, fullfile(out_dirs.figs, 'fig_m1_2_visibility_case.png'), 'Resolution', opt.resolution);
        close(fig4);
    
        tab_walker = local_build_walker_baseline_table(stage03.out.walker, cfg);
        writetable(tab_walker, fullfile(out_dirs.tables, 'tab_m1_2_walker_baseline.csv'));
    
        writetable(stage03.out.summary.case_table, ...
            fullfile(out_dirs.tables, 'tab_m1_2_visibility_case_summary.csv'));
    
        % =============================================================
        % M1.3 worst-window spectrum and margin
        % =============================================================
        fig5 = local_plot_window_case_m1(stage04.out.winbank, opt.window_case_id, opt);
        exportgraphics(fig5, fullfile(out_dirs.figs, 'fig_m1_3_window_case.png'), 'Resolution', opt.resolution);
        close(fig5);
    
        fig6 = local_plot_window_family_m1(stage04.out.summary_spectrum, opt);
        exportgraphics(fig6, fullfile(out_dirs.figs, 'fig_m1_3_window_family.png'), 'Resolution', opt.resolution);
        close(fig6);
    
        fig7 = local_plot_window_margin_m1(stage04.out.summary_margin, opt);
        exportgraphics(fig7, fullfile(out_dirs.figs, 'fig_m1_3_margin.png'), 'Resolution', opt.resolution);
        close(fig7);
    
        writetable(stage04.out.summary_spectrum.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_family_summary.csv'));
        writetable(stage04.out.summary_spectrum.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_heading_summary.csv'));
        writetable(stage04.out.summary_spectrum.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_critical_summary.csv'));
    
        writetable(stage04.out.summary_margin.family_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_family.csv'));
        writetable(stage04.out.summary_margin.heading_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_heading.csv'));
        writetable(stage04.out.summary_margin.critical_summary, ...
            fullfile(out_dirs.tables, 'tab_m1_3_margin_critical.csv'));
    
        % =============================================================
        % Notes
        % =============================================================
        notes_file = fullfile(out_dirs.notes, 'notes_m1_baseline_summary.md');
        local_write_notes_m1(notes_file, cfg, stage02.out, stage03.out, stage04.out);
    
        % =============================================================
        % Output summary
        % =============================================================
        out = struct();
        out.options = opt;
        out.out_dirs = out_dirs;
        out.stage01_cache = stage01.file;
        out.stage02_cache = stage02.file;
        out.stage03_cache = stage03.file;
        out.stage04_cache = stage04.file;
        out.notes_file = notes_file;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        fprintf('\n');
        fprintf('========== Milestone M1 Export ==========\n');
        fprintf('Output root : %s\n', out_dirs.root);
        fprintf('Figures dir : %s\n', out_dirs.figs);
        fprintf('Tables dir  : %s\n', out_dirs.tables);
        fprintf('Notes file  : %s\n', notes_file);
        fprintf('=========================================\n');
    end
    
    %% ========================================================================
    % Generic helpers
    % ========================================================================
    
    function local_ensure_dir(dir_path)
        if exist(dir_path, 'dir') ~= 7
            [ok, msg, msgid] = mkdir(dir_path);
            assert(ok, 'Failed to create directory: %s\n%s (%s)', dir_path, msg, msgid);
        end
    end
    
    function S = local_load_latest_cache(cache_dir, pattern)
        d = dir(fullfile(cache_dir, pattern));
        assert(~isempty(d), 'No cache found for pattern: %s', pattern);
        [~, idx_latest] = max([d.datenum]);
        file = fullfile(d(idx_latest).folder, d(idx_latest).name);
        tmp = load(file);
        S = struct();
        S.file = file;
        S.out = tmp.out;
    end
    
    function local_apply_title(ax, txt, opt)
        if opt.show_titles
            title(ax, txt, 'Interpreter', 'none');
        end
    end
    
    function idx = local_find_case_idx_by_id(S, case_id)
        ids = string({S.case_id});
        idx = find(ids == string(case_id), 1, 'first');
        assert(~isempty(idx), 'Case %s not found.', case_id);
    end
    
    function y = local_clip_for_log(y_raw, y_floor)
        y = y_raw;
        y(y <= 0) = y_floor;
    end
    
    %% ========================================================================
    % M1.1 scenario figure
    % ========================================================================
    
    function fig = local_plot_scenario_m1(casebank, cfg, opt)
    
        fig = figure('Color', 'w', 'Position', [100,100,940,860]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    
        R_D = cfg.stage01.R_D_km;
        R_in = cfg.stage01.R_in_km;
    
        th = linspace(0, 2*pi, 400);
        plot(ax, R_D*cos(th), R_D*sin(th), 'LineWidth', 2.2);
        plot(ax, R_in*cos(th), R_in*sin(th), '--', 'LineWidth', 1.8);
    
        scatter(ax, 0, 0, 70, 'filled');
    
        % nominal entry points and arrows
        for k = 1:numel(casebank.nominal)
            c = casebank.nominal(k);
            p = c.entry_point_xy_km(:).';
            scatter(ax, p(1), p(2), 26, 'filled');
    
            if isfield(c, 'heading_unit_xy')
                u = c.heading_unit_xy(:).';
            else
                hd = deg2rad(c.heading_deg);
                u = [cos(hd), sin(hd)];
            end
            quiver(ax, p(1), p(2), 1100*u(1), 1100*u(2), 0, 'LineWidth', 1.2, 'MaxHeadSize', 0.45);
        end
    
        % heading-family illustrative fan at first heading point
        idx_h = find(strcmp(string({casebank.heading.subfamily}), "heading"), 1, 'first');
        if ~isempty(idx_h)
            % actually use H01_* family if available
            ids = string({casebank.heading.case_id});
            hsel = startsWith(ids, "H01_");
            H = casebank.heading(hsel);
            if isempty(H)
                H = casebank.heading(1:min(numel(casebank.heading),5));
            end
            p = H(1).entry_point_xy_km(:).';
            for i = 1:numel(H)
                hd = deg2rad(H(i).heading_deg);
                u = [cos(hd), sin(hd)];
                quiver(ax, p(1), p(2), 1300*u(1), 1300*u(2), 0, 'LineWidth', 1.1, 'MaxHeadSize', 0.45);
            end
        end
    
        % critical annotations
        for k = 1:numel(casebank.critical)
            c = casebank.critical(k);
            p = c.entry_point_xy_km(:).';
            hd = deg2rad(c.heading_deg);
            u = [cos(hd), sin(hd)];
            quiver(ax, p(1), p(2), 1600*u(1), 1600*u(2), 0, 'LineWidth', 1.8, 'MaxHeadSize', 0.5);
            text(ax, p(1)+120, p(2)+120, strrep(c.case_id, '_', '\_'), 'Interpreter', 'tex');
        end
    
        axis(ax, 'equal');
        xlim(ax, [-5500, 5500]);
        ylim(ax, [-5500, 5500]);
        xlabel(ax, 'Regional frame x (km)', 'Interpreter', 'none');
        ylabel(ax, 'Regional frame y (km)', 'Interpreter', 'none');
    
        local_apply_title(ax, opt.title_text.scenario, opt);
    end
    
    %% ========================================================================
    % M1.1 trajectory 2D figure
    % ========================================================================
    
    function fig = local_plot_traj2d_m1(trajbank, cfg, opt)

        fig = figure('Color', 'w', 'Position', [100,100,1500,620]);
    
        % left: xy trajectories
        ax1 = subplot(1,2,1); hold(ax1, 'on'); grid(ax1, 'on');
    
        R_D = cfg.stage01.R_D_km;
        th = linspace(0,2*pi,400);
        plot(ax1, R_D*cos(th), R_D*sin(th), 'LineWidth', 2.2);
    
        % representative nominal
        traj_nom = trajbank.nominal(1).traj;
        plot(ax1, traj_nom.xy_km(:,1), traj_nom.xy_km(:,2), 'LineWidth', 1.8);
    
        % representative heading set: H01_* if possible
        case_ids = string(arrayfun(@(s) s.case.case_id, trajbank.heading, 'UniformOutput', false));
        wanted = ["H01_+00","H01_-30","H01_+30","H01_-60","H01_+60"];
        for i = 1:numel(wanted)
            idx = find(case_ids == wanted(i), 1, 'first');
            if ~isempty(idx)
                tr = trajbank.heading(idx).traj;
                plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), 'LineWidth', 1.4);
            end
        end
    
        % critical
        for k = 1:numel(trajbank.critical)
            tr = trajbank.critical(k).traj;
            plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), '--', 'LineWidth', 1.5);
        end
    
        axis(ax1, 'equal');
        xlabel(ax1, 'x (km)', 'Interpreter', 'none');
        ylabel(ax1, 'y (km)', 'Interpreter', 'none');
        xlim(ax1, [-3000, 3000]);
        ylim(ax1, [-3050, 3000]);
        local_apply_title(ax1, opt.title_text.traj2d, opt);
    
        % right: altitude histories
        ax2 = subplot(1,2,2); hold(ax2, 'on'); grid(ax2, 'on');
    
        plot(ax2, traj_nom.t_s, traj_nom.h_km, 'LineWidth', 1.8);
        for i = 1:numel(wanted)
            idx = find(case_ids == wanted(i), 1, 'first');
            if ~isempty(idx)
                tr = trajbank.heading(idx).traj;
                plot(ax2, tr.t_s, tr.h_km, 'LineWidth', 1.3);
            end
        end
    
        xlabel(ax2, 'time (s)', 'Interpreter', 'none');
        ylabel(ax2, 'altitude (km)', 'Interpreter', 'none');
        ylim(ax2, [35, 60]);
        local_apply_title(ax2, 'Representative altitude histories', opt);
    end
    
    %% ========================================================================
    % M1.1 trajectory 3D figure
    % ========================================================================
    
    function fig = local_plot_traj3d_m1(trajbank, cfg, opt)

        fig = figure('Color', 'w', 'Position', [100,100,1250,860]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    
        % protected disk footprint at z=0
        R_D = cfg.stage01.R_D_km;
        th = linspace(0,2*pi,300);
        plot3(ax, R_D*cos(th), R_D*sin(th), zeros(size(th)), 'LineWidth', 2.2);
    
        % representative nominal
        traj_nom = trajbank.nominal(1).traj;
        plot3(ax, traj_nom.xy_km(:,1), traj_nom.xy_km(:,2), traj_nom.h_km, 'LineWidth', 1.8);
    
        % representative heading set
        case_ids = string(arrayfun(@(s) s.case.case_id, trajbank.heading, 'UniformOutput', false));
        wanted = ["H01_+00","H01_-30","H01_+30","H01_-60","H01_+60"];
        for i = 1:numel(wanted)
            idx = find(case_ids == wanted(i), 1, 'first');
            if ~isempty(idx)
                tr = trajbank.heading(idx).traj;
                plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, 'LineWidth', 1.4);
            end
        end
    
        % critical
        for k = 1:numel(trajbank.critical)
            tr = trajbank.critical(k).traj;
            plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, '--', 'LineWidth', 1.7);
        end
    
        xlabel(ax, 'x (km)', 'Interpreter', 'none');
        ylabel(ax, 'y (km)', 'Interpreter', 'none');
        zlabel(ax, 'altitude (km)', 'Interpreter', 'none');
        view(ax, [-125, 20]);
        local_apply_title(ax, opt.title_text.traj3d, opt);
    end
    
    %% ========================================================================
    % M1.2 visibility figure
    % ========================================================================
    
    function fig = local_plot_visibility_case_m1(visbank, satbank, case_id, opt)
    
        % collect all vis structs
        all_vis = [visbank.nominal; visbank.heading; visbank.critical];
        ids = string(arrayfun(@(s) s.vis_case.case_id, all_vis, 'UniformOutput', false));
        idx_case = find(ids == string(case_id), 1, 'first');
        assert(~isempty(idx_case), 'Visibility case %s not found.', case_id);
    
        vis_case = all_vis(idx_case).vis_case;
    
        t_s = vis_case.t_s;
        num_visible = vis_case.num_visible;
        min_los_deg = local_compute_min_los_series(vis_case, satbank);
    
        fig = figure('Color', 'w', 'Position', [100,100,1480,620]);
    
        ax1 = subplot(1,2,1); hold(ax1, 'on'); grid(ax1, 'on');
        stairs(ax1, t_s, num_visible, 'LineWidth', 2.0);
        yline(ax1, 2, '--', 'LineWidth', 1.2);
        xlabel(ax1, 'time (s)', 'Interpreter', 'none');
        ylabel(ax1, 'number of visible satellites', 'Interpreter', 'none');
        local_apply_title(ax1, opt.title_text.visibility, opt);
    
        ax2 = subplot(1,2,2); hold(ax2, 'on'); grid(ax2, 'on');
        plot(ax2, t_s, min_los_deg, 'LineWidth', 2.0);
        xlabel(ax2, 'time (s)', 'Interpreter', 'none');
        ylabel(ax2, 'minimum LOS crossing angle (deg)', 'Interpreter', 'none');
        local_apply_title(ax2, 'Representative LOS geometry', opt);
    end
    
    function min_los_deg = local_compute_min_los_series(vis_case, satbank)
        Nt = numel(vis_case.t_s);
        min_los_deg = nan(Nt,1);
    
        for k = 1:Nt
            idx_vis = find(vis_case.visible_mask(k,:));
            if numel(idx_vis) < 2
                min_los_deg(k) = NaN;
                continue;
            end
    
            r_t = vis_case.r_tgt_eci_km(k,:);
            U = zeros(numel(idx_vis), 3);
    
            for j = 1:numel(idx_vis)
                s = idx_vis(j);
                r_s = satbank.r_eci_km(k,:,s);
                los = r_s - r_t;
                U(j,:) = los / norm(los);
            end
    
            amin = inf;
            for i = 1:size(U,1)-1
                for j = i+1:size(U,1)
                    c = dot(U(i,:), U(j,:));
                    c = max(min(c,1),-1);
                    a = acosd(c);
                    if a < amin
                        amin = a;
                    end
                end
            end
            min_los_deg(k) = amin;
        end
    end
    
    %% ========================================================================
    % M1.3 window-case figure
    % ========================================================================
    
    function fig = local_plot_window_case_m1(winbank, case_id, opt)
    
        all_structs = [winbank.nominal; winbank.heading; winbank.critical];
        idx = find(strcmp(string({all_structs.case_id}), string(case_id)), 1, 'first');
        assert(~isempty(idx), 'Window case %s not found.', case_id);
    
        wc = all_structs(idx).window_case;
        t0_s = wc.window_grid.start_idx * wc.window_grid.dt;
    
        fig = figure('Color', 'w', 'Position', [100,100,1180,560]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    
        plot(ax, t0_s, wc.lambda_min, 'LineWidth', 2.0);
        xline(ax, wc.t0_worst_s, '--', 'LineWidth', 1.2);
    
        xlabel(ax, 'window start time t_0 (s)', 'Interpreter', 'none');
        ylabel(ax, 'lambda\_min(W_r)', 'Interpreter', 'tex');
        local_apply_title(ax, opt.title_text.window_case, opt);
    end
    
    %% ========================================================================
    % M1.3 family/window spectrum figure
    % ========================================================================
    
    function fig = local_plot_window_family_m1(summary_spectrum, opt)

        T = summary_spectrum.case_table;
    
        fig = figure('Color', 'w', 'Position', [100,100,1180,440]);
    
        % display floor for zeros on log axis
        y_floor = 1e-3;
    
        % collect all positive displayed values for axis upper bound
        all_y_raw = T.lambda_worst;
        all_y_plot = local_clip_for_log(all_y_raw, y_floor);
        y_max_data = max(all_y_plot, [], 'omitnan');
        if isempty(y_max_data) || ~isfinite(y_max_data) || y_max_data <= y_floor
            y_max_data = 1;
        end
        % give a modest headroom, but do not over-expand
        y_upper = 10^(ceil(log10(y_max_data)) + 0.2);
    
        % ============================================================
        % left: family-level
        % ============================================================
        ax1 = subplot(1,2,1); hold(ax1, 'on'); grid(ax1, 'on');
    
        family_order = ["nominal","heading","critical"];
        x_family = 1:numel(family_order);
    
        for i = 1:numel(family_order)
            fam = family_order(i);
            idx = strcmp(string(T.families), fam);
            y_raw = T.lambda_worst(idx);
            if isempty(y_raw), continue; end
    
            y_plot = local_clip_for_log(y_raw, y_floor);
    
            if numel(y_plot) == 1
                jitter = 0;
            else
                jitter = linspace(-0.12, 0.12, numel(y_plot)).';
            end
            xj = x_family(i) + jitter;
    
            scatter(ax1, xj, y_plot, 34, 'filled', ...
                'MarkerFaceAlpha', 0.72, ...
                'MarkerEdgeAlpha', 0.72);
    
            y_med = median(y_raw, 'omitnan');
            y_med_plot = max(y_med, y_floor);
            plot(ax1, [x_family(i)-0.22, x_family(i)+0.22], [y_med_plot, y_med_plot], ...
                'k-', 'LineWidth', 2.2);
        end
    
        set(ax1, 'XTick', x_family, 'XTickLabel', cellstr(family_order));
        set(ax1, 'YScale', 'log');
        ylim(ax1, [y_floor, y_upper]);
        ylabel(ax1, 'lambda\_worst', 'Interpreter', 'tex');
        local_apply_title(ax1, opt.title_text.window_family, opt);
    
        % ============================================================
        % right: heading-level
        % ============================================================
        ax2 = subplot(1,2,2); hold(ax2, 'on'); grid(ax2, 'on');
    
        idx_heading = strcmp(string(T.families), "heading");
        Th = T(idx_heading, :);
        offsets = unique(Th.heading_offsets);
        offsets = sort(offsets(~isnan(offsets)));
    
        for i = 1:numel(offsets)
            h = offsets(i);
            idx = (Th.heading_offsets == h);
            y_raw = Th.lambda_worst(idx);
            if isempty(y_raw), continue; end
    
            y_plot = local_clip_for_log(y_raw, y_floor);
    
            if numel(y_plot) == 1
                jitter = 0;
            else
                jitter = linspace(-2.0, 2.0, numel(y_plot)).';
            end
            xj = h + jitter;
    
            scatter(ax2, xj, y_plot, 34, 'filled', ...
                'MarkerFaceAlpha', 0.72, ...
                'MarkerEdgeAlpha', 0.72);
    
            y_med = median(y_raw, 'omitnan');
            y_med_plot = max(y_med, y_floor);
            plot(ax2, h, y_med_plot, 'ko', 'MarkerSize', 7.5, 'LineWidth', 1.6);
            plot(ax2, [h-3, h+3], [y_med_plot, y_med_plot], 'k-', 'LineWidth', 2.0);
        end
    
        set(ax2, 'YScale', 'log');
        ylim(ax2, [y_floor, y_upper]);
        xlabel(ax2, 'heading offset (deg)', 'Interpreter', 'none');
        ylabel(ax2, 'lambda\_worst', 'Interpreter', 'tex');
        xlim(ax2, [min(offsets)-8, max(offsets)+8]);
        local_apply_title(ax2, 'Worst-window spectrum across heading offsets', opt);
    end
    
    %% ========================================================================
    % M1.3 margin figure
    % ========================================================================
    
    function fig = local_plot_window_margin_m1(summary_margin, opt)
    
        fig = figure('Color', 'w', 'Position', [100,100,1180,440]);
    
        % left: family pass ratio
        ax1 = subplot(1,2,1); hold(ax1, 'on'); grid(ax1, 'on');
    
        Tfam = summary_margin.family_summary;
        family_order = ["nominal","heading","critical"];
        pass_vals = nan(size(family_order));
    
        for i = 1:numel(family_order)
            idx = strcmp(string(Tfam.group_value), family_order(i));
            if any(idx)
                pass_vals(i) = Tfam.pass_ratio(find(idx,1,'first'));
            end
        end
    
        bar(ax1, 1:numel(family_order), pass_vals);
        ylim(ax1, [0, 1.0]);
        set(ax1, 'XTick', 1:numel(family_order), 'XTickLabel', cellstr(family_order));
        ylabel(ax1, 'pass ratio', 'Interpreter', 'none');
        local_apply_title(ax1, opt.title_text.margin, opt);
    
        for i = 1:numel(pass_vals)
            if ~isnan(pass_vals(i))
                text(ax1, i, min(pass_vals(i)+0.03, 0.98), sprintf('%.2f', pass_vals(i)), ...
                    'HorizontalAlignment', 'center', 'Interpreter', 'none');
            end
        end
    
        % right: heading pass ratio, discrete bars
        ax2 = subplot(1,2,2); hold(ax2, 'on'); grid(ax2, 'on');
    
        Thead = summary_margin.heading_summary;
        offsets = Thead.group_value;
        pass_ratio = Thead.pass_ratio;
        [offsets_sorted, idx_sort] = sort(offsets(:));
        pass_ratio_sorted = pass_ratio(idx_sort);
    
        x = 1:numel(offsets_sorted);
        bar(ax2, x, pass_ratio_sorted);
        ylim(ax2, [0, 1.0]);
    
        xticklabels_cell = arrayfun(@(v) sprintf('%d', v), offsets_sorted, 'UniformOutput', false);
        set(ax2, 'XTick', x, 'XTickLabel', xticklabels_cell);
    
        xlabel(ax2, 'heading offset (deg)', 'Interpreter', 'none');
        ylabel(ax2, 'pass ratio', 'Interpreter', 'none');
        local_apply_title(ax2, 'Pass ratio across heading offsets', opt);
    
        for i = 1:numel(pass_ratio_sorted)
            text(ax2, x(i), min(pass_ratio_sorted(i)+0.03, 0.98), sprintf('%.2f', pass_ratio_sorted(i)), ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
        end
    end
    
    %% ========================================================================
    % Tables
    % ========================================================================
    
    function T = local_build_case_design_table(casebank)
        all_cases = [casebank.nominal; casebank.heading; casebank.critical];
    
        n = numel(all_cases);
        case_id = strings(n,1);
        family = strings(n,1);
        subfamily = strings(n,1);
        entry_theta_deg = nan(n,1);
        heading_deg = nan(n,1);
        heading_offset_deg = nan(n,1);
        x_entry_km = nan(n,1);
        y_entry_km = nan(n,1);
    
        for k = 1:n
            c = all_cases(k);
            case_id(k) = string(c.case_id);
            family(k) = string(c.family);
            subfamily(k) = string(c.subfamily);
    
            if isfield(c, 'entry_theta_deg');    entry_theta_deg(k) = c.entry_theta_deg; end
            if isfield(c, 'heading_deg');        heading_deg(k) = c.heading_deg; end
            if isfield(c, 'heading_offset_deg'); heading_offset_deg(k) = c.heading_offset_deg; end
            if isfield(c, 'entry_point_xy_km')
                x_entry_km(k) = c.entry_point_xy_km(1);
                y_entry_km(k) = c.entry_point_xy_km(2);
            end
        end
    
        T = table(case_id, family, subfamily, entry_theta_deg, ...
                  heading_deg, heading_offset_deg, x_entry_km, y_entry_km);
    end
    
    function T = local_build_parameter_table(cfg)
        section = strings(0,1);
        name = strings(0,1);
        value = strings(0,1);
        note = strings(0,1);
    
        section(end+1,1) = "stage01"; name(end+1,1) = "R_D_km"; value(end+1,1) = string(cfg.stage01.R_D_km); note(end+1,1) = "protected disk radius";
        section(end+1,1) = "stage01"; name(end+1,1) = "R_in_km"; value(end+1,1) = string(cfg.stage01.R_in_km); note(end+1,1) = "entry boundary radius";
    
        section(end+1,1) = "stage02"; name(end+1,1) = "v0_mps"; value(end+1,1) = string(cfg.stage02.v0_mps); note(end+1,1) = "initial speed";
        section(end+1,1) = "stage02"; name(end+1,1) = "h0_m"; value(end+1,1) = string(cfg.stage02.h0_m); note(end+1,1) = "initial altitude";
        section(end+1,1) = "stage02"; name(end+1,1) = "theta0_deg"; value(end+1,1) = string(cfg.stage02.theta0_deg); note(end+1,1) = "initial flight-path angle";
    
        section(end+1,1) = "stage03"; name(end+1,1) = "walker_h_km"; value(end+1,1) = string(cfg.stage03.h_km); note(end+1,1) = "Walker baseline altitude";
        section(end+1,1) = "stage03"; name(end+1,1) = "walker_i_deg"; value(end+1,1) = string(cfg.stage03.i_deg); note(end+1,1) = "Walker baseline inclination";
        section(end+1,1) = "stage03"; name(end+1,1) = "walker_P"; value(end+1,1) = string(cfg.stage03.P); note(end+1,1) = "number of planes";
        section(end+1,1) = "stage03"; name(end+1,1) = "walker_T"; value(end+1,1) = string(cfg.stage03.T); note(end+1,1) = "satellites per plane";
        section(end+1,1) = "stage03"; name(end+1,1) = "walker_F"; value(end+1,1) = string(cfg.stage03.F); note(end+1,1) = "Walker phasing";
    
        section(end+1,1) = "stage04"; name(end+1,1) = "Tw_s"; value(end+1,1) = string(cfg.stage04.Tw_s); note(end+1,1) = "window length";
        section(end+1,1) = "stage04"; name(end+1,1) = "window_step_s"; value(end+1,1) = string(cfg.stage04.window_step_s); note(end+1,1) = "window scan step";
        section(end+1,1) = "stage04"; name(end+1,1) = "gamma_req"; value(end+1,1) = string(cfg.stage04.gamma_req); note(end+1,1) = "margin threshold";
    
        T = table(section, name, value, note);
    end
    
    function T = local_build_walker_baseline_table(walker, cfg)
        name = [
            "h_km"
            "i_deg"
            "P"
            "T"
            "F"
            "Ns"
            "max_range_km"
            "enable_offnadir_constraint"
            "max_offnadir_deg"
            "Tw_s"
            "gamma_req"
            ];
        value = [
            string(walker.h_km)
            string(walker.i_deg)
            string(walker.P)
            string(walker.T)
            string(walker.F)
            string(walker.Ns)
            string(cfg.stage03.max_range_km)
            string(cfg.stage03.enable_offnadir_constraint)
            string(cfg.stage03.max_offnadir_deg)
            string(cfg.stage04.Tw_s)
            string(cfg.stage04.gamma_req)
            ];
        note = [
            "Walker altitude"
            "Walker inclination"
            "number of planes"
            "satellites per plane"
            "Walker phasing"
            "total satellites"
            "visibility range gate"
            "off-nadir enabled"
            "maximum off-nadir angle"
            "worst-window length"
            "D_G threshold denominator"
            ];
    
        T = table(name, value, note);
    end
    
    %% ========================================================================
    % Notes export
    % ========================================================================
    
    function local_write_notes_m1(notes_file, cfg, out2, out3, out4)
        fid = fopen(notes_file, 'w');
        assert(fid > 0, 'Failed to open notes file: %s', notes_file);
        c = onCleanup(@() fclose(fid)); %#ok<NASGU>
    
        fprintf(fid, '# Milestone M1 baseline summary\n\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    
        fprintf(fid, '## Key settings\n\n');
        fprintf(fid, '- Protected disk radius: %.1f km\n', cfg.stage01.R_D_km);
        fprintf(fid, '- Entry boundary radius: %.1f km\n', cfg.stage01.R_in_km);
        fprintf(fid, '- Walker baseline: h=%.1f km, i=%.1f deg, P=%d, T=%d, F=%d\n', ...
            cfg.stage03.h_km, cfg.stage03.i_deg, cfg.stage03.P, cfg.stage03.T, cfg.stage03.F);
        fprintf(fid, '- Worst-window length: %.1f s\n', cfg.stage04.Tw_s);
        fprintf(fid, '- Margin threshold gamma_req: %.3f\n\n', cfg.stage04.gamma_req);
    
        fprintf(fid, '## Stage02 trajectory-level observations\n\n');
        fprintf(fid, '- Nominal, heading, and critical trajectory families were all generated successfully.\n');
        fprintf(fid, '- Stage02 produced scenario plot, 2D trajectory plot, and 3D explanatory trajectory plot.\n\n');
    
        fprintf(fid, '## Stage03 visibility-level observations\n\n');
        fprintf(fid, '- Single-layer Walker baseline was connected to the Stage02 trajectory bank.\n');
        fprintf(fid, '- Visibility and LOS geometry differences already appeared across nominal / heading / critical cases.\n\n');
    
        fprintf(fid, '## Stage04 worst-window observations\n\n');
        Tm = out4.summary_margin.family_summary;
        for i = 1:height(Tm)
            fprintf(fid, '- Family %s: D_G_mean = %.6g, pass_ratio = %.6g\n', ...
                char(string(Tm.group_value(i))), Tm.D_G_mean(i), Tm.pass_ratio(i));
        end
        fprintf(fid, '\n');
    
        fprintf(fid, '## Interim conclusions\n\n');
        fprintf(fid, '1. The single-layer Walker baseline is not uniformly feasible across the full scenario set.\n');
        fprintf(fid, '2. Nominal scenarios only partially pass the threshold; heading expansion further reduces pass ratio.\n');
        fprintf(fid, '3. Critical scenarios fail under the current threshold, showing strong worst-window fragility.\n');
        fprintf(fid, '4. Worst-window spectrum is more discriminative than average visibility-type indicators.\n\n');
    
        fprintf(fid, '## Next step\n\n');
        fprintf(fid, '- Proceed to Stage05A: h-i slice scanning for single-layer baseline feasibility mapping.\n');
    end