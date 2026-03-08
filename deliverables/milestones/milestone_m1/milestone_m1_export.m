function out = milestone_m1_export(varargin)
    %MILESTONE_M1_EXPORT
    % Rebuild Milestone M1: scenario and trajectory baseline exports.
    %
    % M1 scope:
    %   - geodetic scenario design
    %   - representative ENU trajectories
    %   - representative altitude histories
    %   - representative 3D trajectories
    %   - parameter table / summary table
    %   - markdown notes + manifest
    %
    % Usage:
    %   out = milestone_m1_export();
    %   out = milestone_m1_export(struct('show_title', false));
    
        startup();
        cfg = default_params();
    
        opt = local_parse_options(varargin{:});
    
        root_dir = fileparts(mfilename('fullpath'));
        export_root = fullfile(root_dir, 'exports');
        fig_dir      = fullfile(export_root, 'figs');
        table_dir    = fullfile(export_root, 'tables');
        cache_dir    = fullfile(export_root, 'cache');
        manifest_dir = fullfile(root_dir, 'manifest');
    
        local_ensure_dir(export_root);
        local_ensure_dir(fig_dir);
        local_ensure_dir(table_dir);
        local_ensure_dir(cache_dir);
        local_ensure_dir(manifest_dir);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        % ------------------------------------------------------------
        % Load or run Stage01 / Stage02
        % ------------------------------------------------------------
        stage01_out = local_get_stage01_output(cfg, opt);
        stage02_out = local_get_stage02_output(cfg, opt);
    
        % ------------------------------------------------------------
        % Figure 1: scenario design
        % ------------------------------------------------------------
        fig1 = local_plot_m1_scenario(stage01_out, cfg, opt);
        fig1_file = fullfile(fig_dir, sprintf('fig_m1_scene_design_%s.png', timestamp));
        exportgraphics(fig1, fig1_file, 'Resolution', opt.resolution);
        close(fig1);
    
        % ------------------------------------------------------------
        % Figure 2: representative ENU trajectories + altitude histories
        % ------------------------------------------------------------
        fig2 = local_plot_m1_traj2d_and_alt(stage02_out, cfg, opt);
        fig2_file = fullfile(fig_dir, sprintf('fig_m1_representative_trajectories_%s.png', timestamp));
        exportgraphics(fig2, fig2_file, 'Resolution', opt.resolution);
        close(fig2);
    
        % ------------------------------------------------------------
        % Figure 3: representative 3D trajectories
        % ------------------------------------------------------------
        fig3 = local_plot_m1_traj3d(stage02_out, cfg, opt);
        fig3_file = fullfile(fig_dir, sprintf('fig_m1_representative_3d_%s.png', timestamp));
        exportgraphics(fig3, fig3_file, 'Resolution', opt.resolution);
        close(fig3);
    
        % ------------------------------------------------------------
        % Tables
        % ------------------------------------------------------------
        tab_scene = local_build_scene_parameter_table(stage01_out, cfg);
        tab_cases = local_build_case_summary_table(stage02_out);
    
        tab_scene_file = fullfile(table_dir, sprintf('tab_m1_scene_parameters_%s.csv', timestamp));
        tab_cases_file = fullfile(table_dir, sprintf('tab_m1_case_summary_%s.csv', timestamp));
    
        writetable(tab_scene, tab_scene_file);
        writetable(tab_cases, tab_cases_file);
    
        % ------------------------------------------------------------
        % Output struct
        % ------------------------------------------------------------
        out = struct();
        out.stage01_file = local_get_cache_path(stage01_out);
        out.stage02_file = local_get_cache_path(stage02_out);
    
        out.fig_files = {fig1_file; fig2_file; fig3_file};
        out.table_files = {tab_scene_file; tab_cases_file};
    
        out.scene_parameter_table = tab_scene;
        out.case_summary_table = tab_cases;
        out.options = opt;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cache_dir, sprintf('milestone_m1_export_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
    
        % ------------------------------------------------------------
        % Manifest
        % ------------------------------------------------------------
        manifest = local_build_manifest(out, cfg, opt, stage01_out);
        manifest_file = fullfile(manifest_dir, sprintf('milestone_m1_manifest_%s.json', timestamp));
        local_write_text_file(manifest_file, jsonencode(manifest, 'PrettyPrint', true));
    
        % ------------------------------------------------------------
        % Markdown notes
        % ------------------------------------------------------------
        note_file = fullfile(root_dir, 'milestone_m1_export.md');
        note_text = local_build_markdown_note(fig1_file, fig2_file, fig3_file, ...
            tab_scene_file, tab_cases_file, manifest);
        local_write_text_file(note_file, note_text);
    
        out.cache_file = cache_file;
        out.manifest_file = manifest_file;
        out.note_file = note_file;
    
        fprintf('\n');
        fprintf('========== Milestone M1 Export ==========\n');
        fprintf('Figure 1    : %s\n', fig1_file);
        fprintf('Figure 2    : %s\n', fig2_file);
        fprintf('Figure 3    : %s\n', fig3_file);
        fprintf('Table scene : %s\n', tab_scene_file);
        fprintf('Table cases : %s\n', tab_cases_file);
        fprintf('Manifest    : %s\n', manifest_file);
        fprintf('Cache       : %s\n', cache_file);
        fprintf('Note        : %s\n', note_file);
        fprintf('=========================================\n');
    end
    
    % =====================================================================
    % option parsing
    % =====================================================================
    function opt = local_parse_options(varargin)
    
        opt = struct();
        opt.show_title = false;
        opt.show_legend = true;
        opt.show_annotation = true;
        opt.resolution = 220;
        opt.force_rerun_stage01 = false;
        opt.force_rerun_stage02 = false;
    
        if nargin < 1 || isempty(varargin)
            return;
        end
    
        user_opt = varargin{1};
        if ~isstruct(user_opt)
            error('milestone_m1_export:InvalidInput', ...
                'Optional input must be a struct.');
        end
    
        fn = fieldnames(user_opt);
        for k = 1:numel(fn)
            opt.(fn{k}) = user_opt.(fn{k});
        end
    end
    
    % =====================================================================
    % stage loaders
    % =====================================================================
    function out_stage01 = local_get_stage01_output(cfg, opt)
    
        if opt.force_rerun_stage01
            out_stage01 = stage01_scenario_disk();
            return;
        end
    
        d = dir(fullfile(cfg.paths.cache, 'stage01_scenario_disk_*.mat'));
        if isempty(d)
            out_stage01 = stage01_scenario_disk();
            return;
        end
    
        [~, idx] = max([d.datenum]);
        f = fullfile(d(idx).folder, d(idx).name);
        S = load(f);
    
        if ~isfield(S, 'out')
            out_stage01 = stage01_scenario_disk();
        else
            out_stage01 = S.out;
            out_stage01.loaded_cache_file = f;
        end
    end
    
    function out_stage02 = local_get_stage02_output(cfg, opt)
    
        if opt.force_rerun_stage02
            out_stage02 = stage02_hgv_nominal();
            return;
        end
    
        d = dir(fullfile(cfg.paths.cache, 'stage02_hgv_nominal_*.mat'));
        if isempty(d)
            out_stage02 = stage02_hgv_nominal();
            return;
        end
    
        [~, idx] = max([d.datenum]);
        f = fullfile(d(idx).folder, d(idx).name);
        S = load(f);
    
        if ~isfield(S, 'out')
            out_stage02 = stage02_hgv_nominal();
        else
            out_stage02 = S.out;
            out_stage02.loaded_cache_file = f;
        end
    end
    
    function p = local_get_cache_path(stage_out)
        if isfield(stage_out, 'loaded_cache_file')
            p = stage_out.loaded_cache_file;
        elseif isfield(stage_out, 'cache_file')
            p = stage_out.cache_file;
        else
            p = '';
        end
    end
    
    % =====================================================================
    % stage01 meta
    % =====================================================================
    function meta = local_get_stage01_meta(stage01_out, cfg)
    
        if isfield(stage01_out, 'casebank') && isfield(stage01_out.casebank, 'meta')
            meta = stage01_out.casebank.meta;
            return;
        end
    
        meta = struct();
        meta.R_D_km = cfg.stage01.R_D_km;
        meta.R_in_km = cfg.stage01.R_in_km;
        meta.scene_mode = cfg.meta.scene_mode;
        meta.anchor_lat_deg = cfg.geo.lat0_deg;
        meta.anchor_lon_deg = cfg.geo.lon0_deg;
        meta.anchor_h_m = cfg.geo.h0_m;
        meta.epoch_utc = cfg.time.epoch_utc;
    end
    
    % =====================================================================
    % figure 1: scenario
    % =====================================================================
    function fig = local_plot_m1_scenario(stage01_out, cfg, opt)
    
        casebank = stage01_out.casebank;
        meta = local_get_stage01_meta(stage01_out, cfg);
    
        fig = figure('Color', 'w', 'Position', [100,100,950,900]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on'); axis(ax, 'equal');
    
        R_D = meta.R_D_km;
        R_in = meta.R_in_km;
        th = linspace(0, 2*pi, 361);
    
        h1 = plot(ax, R_D*cos(th), R_D*sin(th), 'LineWidth', 2.0);
        h2 = plot(ax, R_in*cos(th), R_in*sin(th), '--', 'LineWidth', 1.8);
        h3 = scatter(ax, 0, 0, 110, 'filled');
    
        cmap_nom = lines(numel(casebank.nominal));
        for k = 1:numel(casebank.nominal)
            c = casebank.nominal(k);
            p = c.entry_point_enu_km(:);
            u = c.heading_unit_enu(:);
    
            quiver(ax, p(1), p(2), 900*u(1), 900*u(2), 0, ...
                'LineWidth', 1.4, 'Color', cmap_nom(k,:));
            scatter(ax, p(1), p(2), 36, cmap_nom(k,:), 'filled');
        end
    
        h4 = [];
        idx_c1 = local_find_case_index(casebank.critical, 'C1_track_plane_aligned');
        if ~isempty(idx_c1)
            c1 = casebank.critical(idx_c1);
            p1 = c1.entry_point_enu_km(:);
            u1 = c1.heading_unit_enu(:);
            h4 = quiver(ax, p1(1), p1(2), 1100*u1(1), 1100*u1(2), 0, ...
                'LineWidth', 2.0, 'Color', [0.55 0.00 0.85]);
            if opt.show_annotation
                text(p1(1)+150, p1(2)+60, 'C1 track-plane-aligned', ...
                    'FontSize', 11, 'Interpreter', 'none');
            end
        end
    
        idx_c2 = local_find_case_index(casebank.critical, 'C2_small_crossing_angle');
        if ~isempty(idx_c2)
            c2 = casebank.critical(idx_c2);
            p2 = c2.entry_point_enu_km(:);
            u2 = c2.heading_unit_enu(:);
            quiver(ax, p2(1), p2(2), 1100*u2(1), 1100*u2(2), 0, ...
                'LineWidth', 2.0, 'Color', [0.85 0.10 0.55]);
            if opt.show_annotation
                text(p2(1)+120, p2(2)-120, 'C2 small-crossing-angle', ...
                    'FontSize', 11, 'Interpreter', 'none');
            end
        end
    
        xlabel(ax, 'Regional ENU east (km)', 'Interpreter', 'none');
        ylabel(ax, 'Regional ENU north (km)', 'Interpreter', 'none');
    
        if opt.show_title
            title(ax, 'Scenario design (geodetic mode)', 'Interpreter', 'none');
        end
    
        if opt.show_legend
            handles = [h1, h2, h3];
            labels = {'Protected disk', 'Entry boundary', 'Protected center'};
            if ~isempty(h4)
                handles = [handles, h4];
                labels{end+1} = 'Critical families';
            end
            legend(ax, handles, labels, 'Location', 'northeast', 'Interpreter', 'none');
        end
    
        xlim(ax, [-1.45*R_in, 1.45*R_in]);
        ylim(ax, [-1.45*R_in, 1.45*R_in]);
    end
    
    % =====================================================================
    % figure 2: ENU trajectories + altitude
    % =====================================================================
    function fig = local_plot_m1_traj2d_and_alt(stage02_out, cfg, opt)

        fig = figure('Color', 'w', 'Position', [100,100,1500,650]);
    
        target_theta = cfg.stage02.example_entry_theta_deg;
        offsets_to_show = cfg.stage02.example_show_heading_offsets;
        include_critical = cfg.stage02.example_include_critical;
    
        % unified style map
        style_map = local_case_styles();
    
        % -------------------------
        % left: ENU trajectories
        % -------------------------
        ax1 = subplot(1,2,1);
        hold(ax1, 'on'); grid(ax1, 'on'); axis(ax1, 'equal');
    
        th = linspace(0, 2*pi, 361);
        h_disk = plot(ax1, cfg.stage01.R_D_km*cos(th), cfg.stage01.R_D_km*sin(th), ...
            'LineWidth', 2.0, 'Color', style_map.protected_disk.Color);
    
        legend_handles_left = h_disk;
        legend_labels_left = {'Protected disk'};
    
        idx_nom = local_find_nominal_by_theta(stage02_out.trajbank.nominal, target_theta);
        if ~isempty(idx_nom)
            tr = stage02_out.trajbank.nominal(idx_nom).traj;
            st = style_map.nominal;
            h_nom = plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
            legend_handles_left(end+1) = h_nom; %#ok<AGROW>
            legend_labels_left{end+1} = 'Nominal'; %#ok<AGROW>
        end
    
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(stage02_out.trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = stage02_out.trajbank.heading(idx_h).traj;
    
            switch offsets_to_show(k)
                case 0
                    st = style_map.heading0;
                    name_i = 'Heading +0 deg';
                case -30
                    st = style_map.headingm30;
                    name_i = 'Heading -30 deg';
                case 30
                    st = style_map.headingp30;
                    name_i = 'Heading +30 deg';
                case -60
                    st = style_map.headingm60;
                    name_i = 'Heading -60 deg';
                case 60
                    st = style_map.headingp60;
                    name_i = 'Heading +60 deg';
                otherwise
                    st = style_map.nominal;
                    name_i = sprintf('Heading %+g deg', offsets_to_show(k));
            end
    
            h_i = plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
    
            legend_handles_left(end+1) = h_i; %#ok<AGROW>
            legend_labels_left{end+1} = name_i; %#ok<AGROW>
        end
    
        if include_critical
            idx_c1 = local_find_case_in_family(stage02_out.trajbank.critical, 'C1_track_plane_aligned');
            if ~isempty(idx_c1)
                tr = stage02_out.trajbank.critical(idx_c1).traj;
                st = style_map.critical1;
                h_c1 = plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles_left(end+1) = h_c1; %#ok<AGROW>
                legend_labels_left{end+1} = 'track\_plane\_aligned'; %#ok<AGROW>
            end
    
            idx_c2 = local_find_case_in_family(stage02_out.trajbank.critical, 'C2_small_crossing_angle');
            if ~isempty(idx_c2)
                tr = stage02_out.trajbank.critical(idx_c2).traj;
                st = style_map.critical2;
                h_c2 = plot(ax1, tr.xy_km(:,1), tr.xy_km(:,2), ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles_left(end+1) = h_c2; %#ok<AGROW>
                legend_labels_left{end+1} = 'small\_crossing\_angle'; %#ok<AGROW>
            end
        end
    
        xlabel(ax1, 'x (km)', 'Interpreter', 'none');
        ylabel(ax1, 'y (km)', 'Interpreter', 'none');
    
        if opt.show_title
            title(ax1, 'Representative ENU trajectories', 'Interpreter', 'none');
        end
    
        if opt.show_legend
            legend(ax1, legend_handles_left, legend_labels_left, ...
                'Location', 'southwest', 'Interpreter', 'none');
        end
    
        % -------------------------
        % right: altitude history
        % -------------------------
        ax2 = subplot(1,2,2);
        hold(ax2, 'on'); grid(ax2, 'on');
    
        legend_handles_right = gobjects(0);
        legend_labels_right = {};
    
        if ~isempty(idx_nom)
            tr = stage02_out.trajbank.nominal(idx_nom).traj;
            st = style_map.nominal;
            h_nom2 = plot(ax2, tr.t_s, tr.h_km, ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
            legend_handles_right(end+1) = h_nom2; %#ok<AGROW>
            legend_labels_right{end+1} = 'Nominal'; %#ok<AGROW>
        end
    
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(stage02_out.trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = stage02_out.trajbank.heading(idx_h).traj;
    
            switch offsets_to_show(k)
                case 0
                    st = style_map.heading0;
                    name_i = 'Heading +0 deg';
                case -30
                    st = style_map.headingm30;
                    name_i = 'Heading -30 deg';
                case 30
                    st = style_map.headingp30;
                    name_i = 'Heading +30 deg';
                case -60
                    st = style_map.headingm60;
                    name_i = 'Heading -60 deg';
                case 60
                    st = style_map.headingp60;
                    name_i = 'Heading +60 deg';
                otherwise
                    st = style_map.nominal;
                    name_i = sprintf('Heading %+g deg', offsets_to_show(k));
            end
    
            h_i2 = plot(ax2, tr.t_s, tr.h_km, ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
    
            legend_handles_right(end+1) = h_i2; %#ok<AGROW>
            legend_labels_right{end+1} = name_i; %#ok<AGROW>
        end
    
        if include_critical
            idx_c1 = local_find_case_in_family(stage02_out.trajbank.critical, 'C1_track_plane_aligned');
            if ~isempty(idx_c1)
                tr = stage02_out.trajbank.critical(idx_c1).traj;
                st = style_map.critical1;
                h_c12 = plot(ax2, tr.t_s, tr.h_km, ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles_right(end+1) = h_c12; %#ok<AGROW>
                legend_labels_right{end+1} = 'track\_plane\_aligned'; %#ok<AGROW>
            end
    
            idx_c2 = local_find_case_in_family(stage02_out.trajbank.critical, 'C2_small_crossing_angle');
            if ~isempty(idx_c2)
                tr = stage02_out.trajbank.critical(idx_c2).traj;
                st = style_map.critical2;
                h_c22 = plot(ax2, tr.t_s, tr.h_km, ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles_right(end+1) = h_c22; %#ok<AGROW>
                legend_labels_right{end+1} = 'small\_crossing\_angle'; %#ok<AGROW>
            end
        end
    
        xlabel(ax2, 'time (s)', 'Interpreter', 'none');
        ylabel(ax2, 'altitude (km)', 'Interpreter', 'none');
    
        if opt.show_title
            title(ax2, 'Representative altitude histories', 'Interpreter', 'none');
        end
    
        if opt.show_legend
            legend(ax2, legend_handles_right, legend_labels_right, ...
                'Location', 'eastoutside', 'Interpreter', 'none');
        end
    end
    
    % =====================================================================
    % figure 3: 3D trajectories
    % =====================================================================
    function fig = local_plot_m1_traj3d(stage02_out, cfg, opt)

        fig = figure('Color', 'w', 'Position', [100,100,1150,850]);
        ax = axes(fig); hold(ax, 'on'); grid(ax, 'on'); view(ax, 36, 20);
    
        target_theta = cfg.stage02.example_entry_theta_deg;
        offsets_to_show = cfg.stage02.example_show_heading_offsets;
        include_critical = cfg.stage02.example_include_critical;
    
        style_map = local_case_styles();
    
        th = linspace(0, 2*pi, 361);
        h_disk = plot3(ax, ...
            cfg.stage01.R_D_km*cos(th), ...
            cfg.stage01.R_D_km*sin(th), ...
            zeros(size(th)), ...
            'LineWidth', 2.0, ...
            'Color', style_map.protected_disk.Color);
    
        legend_handles = h_disk;
        legend_labels = {'Protected disk'};
    
        idx_nom = local_find_nominal_by_theta(stage02_out.trajbank.nominal, target_theta);
        if ~isempty(idx_nom)
            tr = stage02_out.trajbank.nominal(idx_nom).traj;
            st = style_map.nominal;
            h_nom = plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
            legend_handles(end+1) = h_nom; %#ok<AGROW>
            legend_labels{end+1} = 'Nominal'; %#ok<AGROW>
        end
    
        for k = 1:numel(offsets_to_show)
            idx_h = local_find_heading_by_theta_offset(stage02_out.trajbank.heading, target_theta, offsets_to_show(k));
            if isempty(idx_h), continue; end
            tr = stage02_out.trajbank.heading(idx_h).traj;
    
            switch offsets_to_show(k)
                case 0
                    st = style_map.heading0;
                    name_i = 'Heading +0 deg';
                case -30
                    st = style_map.headingm30;
                    name_i = 'Heading -30 deg';
                case 30
                    st = style_map.headingp30;
                    name_i = 'Heading +30 deg';
                case -60
                    st = style_map.headingm60;
                    name_i = 'Heading -60 deg';
                case 60
                    st = style_map.headingp60;
                    name_i = 'Heading +60 deg';
                otherwise
                    st = style_map.nominal;
                    name_i = sprintf('Heading %+g deg', offsets_to_show(k));
            end
    
            h_i = plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
    
            legend_handles(end+1) = h_i; %#ok<AGROW>
            legend_labels{end+1} = name_i; %#ok<AGROW>
        end
    
        if include_critical
            idx_c1 = local_find_case_in_family(stage02_out.trajbank.critical, 'C1_track_plane_aligned');
            if ~isempty(idx_c1)
                tr = stage02_out.trajbank.critical(idx_c1).traj;
                st = style_map.critical1;
                h_c1 = plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles(end+1) = h_c1; %#ok<AGROW>
                legend_labels{end+1} = 'track\_plane\_aligned'; %#ok<AGROW>
            end
    
            idx_c2 = local_find_case_in_family(stage02_out.trajbank.critical, 'C2_small_crossing_angle');
            if ~isempty(idx_c2)
                tr = stage02_out.trajbank.critical(idx_c2).traj;
                st = style_map.critical2;
                h_c2 = plot3(ax, tr.xy_km(:,1), tr.xy_km(:,2), tr.h_km, ...
                    'LineStyle', st.LineStyle, 'LineWidth', st.LineWidth, 'Color', st.Color);
                legend_handles(end+1) = h_c2; %#ok<AGROW>
                legend_labels{end+1} = 'small\_crossing\_angle'; %#ok<AGROW>
            end
        end
    
        xlabel(ax, 'x (km)', 'Interpreter', 'none');
        ylabel(ax, 'y (km)', 'Interpreter', 'none');
        zlabel(ax, 'altitude (km)', 'Interpreter', 'none');
    
        if opt.show_title
            title(ax, 'Representative 3D trajectories', 'Interpreter', 'none');
        end
    
        if opt.show_legend
            legend(ax, legend_handles, legend_labels, ...
                'Location', 'northeast', 'Interpreter', 'none');
        end
    end
    
    % =====================================================================
    % tables
    % =====================================================================
    function T = local_build_scene_parameter_table(stage01_out, cfg)
    
        meta = local_get_stage01_meta(stage01_out, cfg);
        casebank = stage01_out.casebank;
    
        name = string({
            'scene_mode'
            'anchor_lat_deg'
            'anchor_lon_deg'
            'anchor_h_m'
            'epoch_utc'
            'protected_disk_radius_km'
            'entry_boundary_radius_km'
            'nominal_case_count'
            'heading_case_count'
            'critical_case_count'
            'total_case_count'
            });
    
        value = string({
            char(meta.scene_mode)
            num2str(meta.anchor_lat_deg)
            num2str(meta.anchor_lon_deg)
            num2str(meta.anchor_h_m)
            char(meta.epoch_utc)
            num2str(meta.R_D_km)
            num2str(meta.R_in_km)
            num2str(numel(casebank.nominal))
            num2str(numel(casebank.heading))
            num2str(numel(casebank.critical))
            num2str(numel(casebank.nominal) + numel(casebank.heading) + numel(casebank.critical))
            });
    
        description = string({
            'Scenario mode used by Stage01'
            'Geodetic anchor latitude'
            'Geodetic anchor longitude'
            'Geodetic anchor altitude'
            'Scenario epoch'
            'Protected disk radius'
            'Entry boundary radius'
            'Nominal family size'
            'Heading family size'
            'Critical family size'
            'Total case count'
            });
    
        T = table(name, value, description);
    end
    
    function T = local_build_case_summary_table(stage02_out)
    
        rows = {};
    
        families = {'nominal','heading','critical'};
        for f = 1:numel(families)
            bank = stage02_out.trajbank.(families{f});
            for k = 1:numel(bank)
                c = bank(k).case;
                tr = bank(k).traj;
                rows(end+1,:) = {
                    char(c.case_id), ...
                    char(c.family), ...
                    char(c.subfamily), ...
                    c.entry_theta_deg, ...
                    c.heading_deg, ...
                    local_safe_get(c, 'heading_offset_deg', NaN), ...
                    local_safe_get(c, 'entry_lat_deg', NaN), ...
                    local_safe_get(c, 'entry_lon_deg', NaN), ...
                    tr.t_s(end) - tr.t_s(1), ...
                    min(tr.h_km), ...
                    max(tr.h_km), ...
                    local_compute_rmin_enu(tr)
                    }; %#ok<AGROW>
            end
        end
    
        T = cell2table(rows, 'VariableNames', {
            'case_id'
            'family'
            'subfamily'
            'entry_theta_deg'
            'heading_deg'
            'heading_offset_deg'
            'entry_lat_deg'
            'entry_lon_deg'
            'duration_s'
            'h_min_km'
            'h_max_km'
            'rmin_km'
            });
    end
    
    % =====================================================================
    % helpers for Stage02 bank lookup
    % =====================================================================
    function idx = local_find_nominal_by_theta(family_struct, target_theta)
        idx = [];
        for i = 1:numel(family_struct)
            c = family_struct(i).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6
                idx = i;
                return;
            end
        end
    end
    
    function idx = local_find_heading_by_theta_offset(family_struct, target_theta, target_offset)
        idx = [];
        for i = 1:numel(family_struct)
            c = family_struct(i).case;
            if abs(wrapTo180(c.entry_theta_deg - target_theta)) < 1e-6 && ...
               isfield(c, 'heading_offset_deg') && isfinite(c.heading_offset_deg) && ...
               abs(c.heading_offset_deg - target_offset) < 1e-6
                idx = i;
                return;
            end
        end
    end
    
    function idx = local_find_case_index(bank, case_id)
        idx = [];
        for k = 1:numel(bank)
            if strcmp(bank(k).case_id, case_id)
                idx = k;
                return;
            end
        end
    end
    
    % =====================================================================
    % manifest / markdown
    % =====================================================================
    function manifest = local_build_manifest(out, cfg, opt, stage01_out)
    
        meta = local_get_stage01_meta(stage01_out, cfg);
    
        manifest = struct();
        manifest.name = 'milestone_m1';
        manifest.description = 'Scenario and trajectory baseline exports';
        manifest.generated_at = out.timestamp;
    
        manifest.dependencies = struct();
        manifest.dependencies.stage01_cache = out.stage01_file;
        manifest.dependencies.stage02_cache = out.stage02_file;
    
        manifest.scene = struct();
        manifest.scene.mode = char(meta.scene_mode);
        manifest.scene.anchor_lat_deg = meta.anchor_lat_deg;
        manifest.scene.anchor_lon_deg = meta.anchor_lon_deg;
        manifest.scene.anchor_h_m = meta.anchor_h_m;
        manifest.scene.epoch_utc = char(meta.epoch_utc);
        manifest.scene.R_D_km = meta.R_D_km;
        manifest.scene.R_in_km = meta.R_in_km;
    
        manifest.figures = out.fig_files;
        manifest.tables = out.table_files;
        manifest.options = opt;
    end
    
    function txt = local_build_markdown_note(fig1_file, fig2_file, fig3_file, ...
        tab_scene_file, tab_cases_file, manifest)
    
        txt = sprintf([ ...
            '# Milestone M1: 场景与轨迹基线\n\n' ...
            '## 1. 目标\n' ...
            '本里程碑用于冻结第四章实验对象的基础定义，包括防区圆盘、进入边界、进入族构造、代表性轨迹及地理锚定信息。\n\n' ...
            '## 2. 场景设置\n' ...
            '- 场景模式：`%s`\n' ...
            '- 圆心经纬度：`(%.3f deg, %.3f deg)`\n' ...
            '- 圆心高度：`%.1f m`\n' ...
            '- 参考历元：`%s`\n\n' ...
            '## 3. 导出文件\n' ...
            '### 图\n' ...
            '- 场景图：`%s`\n' ...
            '- 代表性轨迹图：`%s`\n' ...
            '- 代表性三维轨迹图：`%s`\n\n' ...
            '### 表\n' ...
            '- 场景参数表：`%s`\n' ...
            '- case 汇总表：`%s`\n\n' ...
            '## 4. 论文写作用说明\n' ...
            '本里程碑可用于支撑第四章“实验场景与对象设置”小节。\n\n' ...
            '## 5. manifest 摘要\n' ...
            '- Stage01 cache: `%s`\n' ...
            '- Stage02 cache: `%s`\n' ...
            ], ...
            manifest.scene.mode, manifest.scene.anchor_lat_deg, manifest.scene.anchor_lon_deg, ...
            manifest.scene.anchor_h_m, manifest.scene.epoch_utc, ...
            fig1_file, fig2_file, fig3_file, ...
            tab_scene_file, tab_cases_file, ...
            manifest.dependencies.stage01_cache, manifest.dependencies.stage02_cache);
    end
    
    % =====================================================================
    % utilities
    % =====================================================================
    function val = local_safe_get(s, field_name, default_val)
        if isfield(s, field_name)
            val = s.(field_name);
        else
            val = default_val;
        end
    end
    
    function rmin_km = local_compute_rmin_enu(tr)
        rr = sqrt(sum(tr.r_enu_km(:,1:2).^2, 2));
        rmin_km = min(rr);
    end
    
    function local_ensure_dir(d)
        if ~exist(d, 'dir')
            mkdir(d);
        end
    end
    
    function local_write_text_file(file_path, txt)
        fid = fopen(file_path, 'w');
        if fid < 0
            error('Failed to open file for writing: %s', file_path);
        end
        cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
        fprintf(fid, '%s', txt);
    end

    function styles = local_case_styles()
        styles = struct();
    
        styles.protected_disk = struct('Color', [0.00 0.45 0.74], 'LineStyle', '-',  'LineWidth', 2.0);
    
        styles.nominal    = struct('Color', [0.85 0.33 0.10], 'LineStyle', '-',  'LineWidth', 2.2);
        styles.heading0   = struct('Color', [0.93 0.69 0.13], 'LineStyle', '-',  'LineWidth', 1.9);
        styles.headingm30 = struct('Color', [0.49 0.18 0.86], 'LineStyle', '-',  'LineWidth', 1.9);
        styles.headingp30 = struct('Color', [0.30 0.69 0.29], 'LineStyle', '-',  'LineWidth', 1.9);
        styles.headingm60 = struct('Color', [0.20 0.70 0.90], 'LineStyle', '-',  'LineWidth', 1.9);
        styles.headingp60 = struct('Color', [0.89 0.10 0.59], 'LineStyle', '-',  'LineWidth', 1.9);
    
        styles.critical1  = struct('Color', [0.00 0.45 0.74], 'LineStyle', '--', 'LineWidth', 2.0);
        styles.critical2  = struct('Color', [0.85 0.33 0.10], 'LineStyle', '--', 'LineWidth', 2.0);
    end

    function idx = local_find_case_in_family(bank, case_id)
        idx = [];
        for k = 1:numel(bank)
            if isfield(bank(k), 'case') && isstruct(bank(k).case) && isfield(bank(k).case, 'case_id')
                if strcmp(bank(k).case.case_id, case_id)
                    idx = k;
                    return;
                end
            end
            if isfield(bank(k), 'case_id')
                if strcmp(bank(k).case_id, case_id)
                    idx = k;
                    return;
                end
            end
        end
    end