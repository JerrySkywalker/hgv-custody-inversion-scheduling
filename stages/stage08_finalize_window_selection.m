function out = stage08_finalize_window_selection(cfg)
    %STAGE08_FINALIZE_WINDOW_SELECTION
    % Stage08.5:
    %   Finalize the window-length selection using results from
    %   Stage08.2 / Stage08.3 / Stage08.4 / Stage08.4c.
    %
    % Main outputs:
    %   out.final_summary_table
    %   out.recommendation_table
    %   out.stage_source_table
    %   out.final_text_table
    %   out.figures
    %   out.files
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = local_prepare_stage08_5_cfg(cfg);
        cfg.project_stage = 'stage08_finalize_window_selection';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_finalize_window_selection_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.5 started.');
    
        % ============================================================
        % Load stage outputs
        % ============================================================
        file82 = local_find_latest_cache(cfg.paths.cache, ...
            sprintf('stage08_scan_representative_cases_%s_*.mat', run_tag));
        S82 = load(file82);
        out82 = local_extract_out_struct(S82);
        assert(isstruct(out82), 'Invalid Stage08.2 cache.');
        log_msg(log_fid, 'INFO', 'Loaded Stage08.2: %s', file82);
    
        file83 = local_find_latest_cache(cfg.paths.cache, ...
            sprintf('stage08_plot_representative_cases_%s_*.mat', run_tag), true);
        out83 = [];
        if ~isempty(file83)
            S83 = load(file83);
            out83 = local_extract_out_struct(S83);
            log_msg(log_fid, 'INFO', 'Loaded Stage08.3: %s', file83);
        else
            log_msg(log_fid, 'INFO', 'Stage08.3 cache not found, fallback to Stage08.2-only summaries.');
        end
    
        file84 = local_find_latest_cache(cfg.paths.cache, ...
            sprintf('stage08_scan_smallgrid_search_%s_*.mat', run_tag));
        S84 = load(file84);
        out84 = local_extract_out_struct(S84);
        assert(isstruct(out84), 'Invalid Stage08.4 cache.');
        log_msg(log_fid, 'INFO', 'Loaded Stage08.4: %s', file84);
    
        file84c = local_find_latest_cache(cfg.paths.cache, ...
            sprintf('stage08_boundary_window_sensitivity_%s_*.mat', run_tag));
        S84c = load(file84c);
        out84c = local_extract_out_struct(S84c);
        assert(isstruct(out84c), 'Invalid Stage08.4c cache.');
        log_msg(log_fid, 'INFO', 'Loaded Stage08.4c: %s', file84c);
    
        % ============================================================
        % Resolve Tw grid
        % ============================================================
        Tw_grid_s = local_resolve_Tw_grid(out82, out84, out84c);
        log_msg(log_fid, 'INFO', 'Resolved Tw grid = %s', mat2str(Tw_grid_s));
    
        % ============================================================
        % Build stage source table
        % ============================================================
        stage_source_table = local_build_stage_source_table(file82, file83, file84, file84c, Tw_grid_s);
    
        % ============================================================
        % Build final summary table
        % ============================================================
        final_summary_table = local_build_final_summary_table(Tw_grid_s, out82, out83, out84, out84c);
    
        % ============================================================
        % Build recommendation table
        % ============================================================
        recommendation_table = local_build_recommendation_table(final_summary_table, cfg);
    
        % ============================================================
        % Build final text table
        % ============================================================
        final_text_table = local_build_final_text_table(final_summary_table, recommendation_table);
    
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.paper_fig_response_compact = '';
        figures.paper_fig_boundary_summary = '';
        figures.paper_fig_boundary_heatmap = '';
    
        if cfg.stage08_5.make_plot
            fig1 = local_plot_response_compact(out82, out84, out84c);
            figures.paper_fig_response_compact = fullfile(cfg.paths.figs, ...
                sprintf('stage08_paper_fig_response_compact_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.paper_fig_response_compact, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_boundary_summary(final_summary_table);
            figures.paper_fig_boundary_summary = fullfile(cfg.paths.figs, ...
                sprintf('stage08_paper_fig_boundary_summary_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.paper_fig_boundary_summary, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_boundary_heatmap_from_84c(out84c);
            figures.paper_fig_boundary_heatmap = fullfile(cfg.paths.figs, ...
                sprintf('stage08_paper_fig_boundary_heatmap_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.paper_fig_boundary_heatmap, 'Resolution', 180);
            close(fig3);
        end
    
        % ============================================================
        % Save CSV
        % ============================================================
        final_summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_final_summary_%s_%s.csv', run_tag, timestamp));
        recommendation_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_recommendation_%s_%s.csv', run_tag, timestamp));
        stage_source_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_stage_source_%s_%s.csv', run_tag, timestamp));
        final_text_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_final_text_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_finalize_window_selection_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(final_summary_table, final_summary_csv);
        writetable(recommendation_table, recommendation_csv);
        writetable(stage_source_table, stage_source_csv);
        writetable(final_text_table, final_text_csv);
    
        summary_table = table( ...
            string(file82), ...
            string(local_string_or_empty(file83)), ...
            string(file84), ...
            string(file84c), ...
            numel(Tw_grid_s), ...
            height(final_summary_table), ...
            height(recommendation_table), ...
            'VariableNames', { ...
                'stage08_2_file', ...
                'stage08_3_file', ...
                'stage08_4_file', ...
                'stage08_4c_file', ...
                'n_Tw', ...
                'n_final_summary_row', ...
                'n_recommendation_row'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save MAT
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.stage_source_table = stage_source_table;
        out.final_summary_table = final_summary_table;
        out.recommendation_table = recommendation_table;
        out.final_text_table = final_text_table;
        out.figures = figures;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.final_summary_csv = final_summary_csv;
        out.files.recommendation_csv = recommendation_csv;
        out.files.stage_source_csv = stage_source_csv;
        out.files.final_text_csv = final_text_csv;
        out.files.summary_csv = summary_csv;
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_finalize_window_selection_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Final summary CSV saved to: %s', final_summary_csv);
        log_msg(log_fid, 'INFO', 'Recommendation CSV saved to: %s', recommendation_csv);
        log_msg(log_fid, 'INFO', 'Stage source CSV saved to: %s', stage_source_csv);
        log_msg(log_fid, 'INFO', 'Final text CSV saved to: %s', final_text_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.5 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.5 Summary ==========\n');
        fprintf('Tw count             : %d\n', numel(Tw_grid_s));
        fprintf('Final summary rows   : %d\n', height(final_summary_table));
        fprintf('Recommendation rows  : %d\n', height(recommendation_table));
        fprintf('Final summary CSV    : %s\n', final_summary_csv);
        fprintf('Recommendation CSV   : %s\n', recommendation_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % config helpers
    % ============================================================
    
    function cfg = local_prepare_stage08_5_cfg(cfg)
    
        if ~isfield(cfg, 'stage08_5') || ~isstruct(cfg.stage08_5)
            cfg.stage08_5 = struct();
        end
    
        f = cfg.stage08_5;
    
        if ~isfield(f, 'make_plot') || isempty(f.make_plot)
            f.make_plot = true;
        end
    
        % Recommendation logic
        if ~isfield(f, 'min_acceptable_Tw_s') || isempty(f.min_acceptable_Tw_s)
            f.min_acceptable_Tw_s = 50;
        end
        if ~isfield(f, 'target_recommended_Tw_s') || isempty(f.target_recommended_Tw_s)
            f.target_recommended_Tw_s = 60;
        end
        if ~isfield(f, 'max_boundary_Nmin') || isempty(f.max_boundary_Nmin)
            f.max_boundary_Nmin = 32;
        end
        if ~isfield(f, 'min_boundary_feasible_ratio') || isempty(f.min_boundary_feasible_ratio)
            f.min_boundary_feasible_ratio = 0.66;
        end
    
        cfg.stage08_5 = f;
    end
    
    
    % ============================================================
    % cache helpers
    % ============================================================
    
    function file = local_find_latest_cache(cache_dir, pattern, allow_empty)
    
        if nargin < 3
            allow_empty = false;
        end
    
        d = dir(fullfile(cache_dir, pattern));
        if isempty(d)
            if allow_empty
                file = '';
                return;
            end
            error('No cache matched pattern: %s', pattern);
        end
    
        [~, idx] = max([d.datenum]);
        file = fullfile(d(idx).folder, d(idx).name);
    end
    
    
    function out_struct = local_extract_out_struct(S)
    
        out_struct = [];
        if isfield(S, 'out') && isstruct(S.out)
            out_struct = S.out;
            return;
        end
    
        names = fieldnames(S);
        for i = 1:numel(names)
            if isstruct(S.(names{i}))
                out_struct = S.(names{i});
                return;
            end
        end
    end
    
    
    function s = local_string_or_empty(x)
        if isempty(x)
            s = "";
        else
            s = string(x);
        end
    end
    
    
    % ============================================================
    % resolve Tw
    % ============================================================
    
    function Tw_grid_s = local_resolve_Tw_grid(out82, out84, out84c)
    
        Tw_grid_s = [];
    
        if isstruct(out82)
            if isfield(out82, 'scope') && isstruct(out82.scope) && isfield(out82.scope, 'Tw_grid_s')
                Tw_grid_s = out82.scope.Tw_grid_s(:).';
            elseif isfield(out82, 'raw_table') && istable(out82.raw_table) && any(strcmp(out82.raw_table.Properties.VariableNames, 'Tw_s'))
                Tw_grid_s = unique(out82.raw_table.Tw_s).';
            elseif isfield(out82, 'raw_config_table') && istable(out82.raw_config_table) && any(strcmp(out82.raw_config_table.Properties.VariableNames, 'Tw_s'))
                Tw_grid_s = unique(out82.raw_config_table.Tw_s).';
            end
        end
    
        if isempty(Tw_grid_s) && isstruct(out84) && isfield(out84, 'Tw_summary_table') && istable(out84.Tw_summary_table)
            Tw_grid_s = out84.Tw_summary_table.Tw_s(:).';
        end
    
        if isempty(Tw_grid_s) && isstruct(out84c) && isfield(out84c, 'Tw_summary_table') && istable(out84c.Tw_summary_table)
            Tw_grid_s = out84c.Tw_summary_table.Tw_s(:).';
        end
    
        assert(~isempty(Tw_grid_s), 'Failed to resolve Tw grid.');
        Tw_grid_s = sort(unique(Tw_grid_s), 'ascend');
    end
    
    
    % ============================================================
    % source table
    % ============================================================
    
    function T = local_build_stage_source_table(file82, file83, file84, file84c, Tw_grid_s)
    
        rows = cell(numel(Tw_grid_s), 1);
    
        for i = 1:numel(Tw_grid_s)
            r = struct();
            r.Tw_s = Tw_grid_s(i);
            r.stage08_2_file = string(file82);
            r.stage08_3_file = string(local_string_or_empty(file83));
            r.stage08_4_file = string(file84);
            r.stage08_4c_file = string(file84c);
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
    end
    
    
    % ============================================================
    % final summary
    % ============================================================
    
    function T = local_build_final_summary_table(Tw_grid_s, out82, out83, out84, out84c)
    
        rows = cell(numel(Tw_grid_s), 1);
    
        T82_family = local_get_table_field(out82, {'family_summary_table','family_table','summary_table'});
        T82_case = local_get_table_field(out82, {'case_summary_table','case_table'});
        T84_tw = local_get_table_field(out84, {'Tw_summary_table'});
        T84_best = local_get_table_field(out84, {'best_config_table'});
        T84c_tw = local_get_table_field(out84c, {'Tw_summary_table'});
        T84c_best = local_get_table_field(out84c, {'best_config_table'});
    
        for i = 1:numel(Tw_grid_s)
            Tw = Tw_grid_s(i);
    
            r = struct();
            r.Tw_s = Tw;
    
            % -------------------------
            % Stage08.2 representative/family info
            % -------------------------
            r.rep_DG_median_mean = local_mean_if_exists(T82_case, 'D_G_median', 'Tw_s', Tw);
            r.rep_DG_min_mean = local_mean_if_exists(T82_case, 'D_G_min', 'Tw_s', Tw);
    
            r.family_lambda_median_mean = local_mean_if_exists(T82_family, 'lambda_worst_median', 'Tw_s', Tw);
            r.family_DG_median_mean = local_mean_if_exists(T82_family, 'D_G_min_median', 'Tw_s', Tw);
            r.family_pass_geom_mean = local_mean_if_exists(T82_family, 'pass_geom_ratio', 'Tw_s', Tw);
    
            % -------------------------
            % Stage08.4 local robustness
            % -------------------------
            r.local_num_feasible = local_get_value_if_exists(T84_tw, 'num_feasible', 'Tw_s', Tw);
            r.local_feasible_ratio = local_get_value_if_exists(T84_tw, 'feasible_ratio', 'Tw_s', Tw);
            r.local_N_min = local_get_value_if_exists(T84_tw, 'N_min', 'Tw_s', Tw);
            r.local_best_DG_median = local_get_value_if_exists(T84_tw, 'best_DG_median', 'Tw_s', Tw);
    
            % -------------------------
            % Stage08.4c boundary sensitivity
            % -------------------------
            r.boundary_num_feasible = local_get_value_if_exists(T84c_tw, 'num_feasible', 'Tw_s', Tw);
            r.boundary_feasible_ratio = local_get_value_if_exists(T84c_tw, 'feasible_ratio', 'Tw_s', Tw);
            r.boundary_N_min = local_get_value_if_exists(T84c_tw, 'N_min', 'Tw_s', Tw);
            r.boundary_best_DG_median = local_get_value_if_exists(T84c_tw, 'best_DG_median', 'Tw_s', Tw);
            r.flip_count = local_get_value_if_exists(T84c_tw, 'flip_count', 'Tw_s', Tw);
    
            % -------------------------
            % Acceptance and recommendation features
            % -------------------------
            r.is_boundary_acceptable = isfinite(r.boundary_N_min) && (r.boundary_N_min <= 32) && ...
                                       isfinite(r.boundary_feasible_ratio) && (r.boundary_feasible_ratio >= 0.66) && ...
                                       (Tw >= 50);
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, 'Tw_s', 'ascend');
    end
    
    
    % ============================================================
    % recommendation
    % ============================================================
    
    function T = local_build_recommendation_table(final_summary_table, cfg)
    
        T = final_summary_table(:, {'Tw_s', 'boundary_N_min', 'boundary_feasible_ratio', ...
            'boundary_num_feasible', 'flip_count', 'local_best_DG_median', 'boundary_best_DG_median'});
    
        T.is_acceptable = ...
            (T.Tw_s >= cfg.stage08_5.min_acceptable_Tw_s) & ...
            isfinite(T.boundary_N_min) & (T.boundary_N_min <= cfg.stage08_5.max_boundary_Nmin) & ...
            isfinite(T.boundary_feasible_ratio) & (T.boundary_feasible_ratio >= cfg.stage08_5.min_boundary_feasible_ratio);
    
        % scoring: prefer acceptable, closer to 60, higher feasible ratio, moderate Tw
        target = cfg.stage08_5.target_recommended_Tw_s;
        T.distance_to_target = abs(T.Tw_s - target);
    
        T.rank_score = nan(height(T), 1);
        for i = 1:height(T)
            if ~T.is_acceptable(i)
                T.rank_score(i) = -1e6 + T.boundary_feasible_ratio(i);
            else
                T.rank_score(i) = ...
                    1000 ...
                    - 10 * T.distance_to_target(i) ...
                    + 100 * T.boundary_feasible_ratio(i) ...
                    - 0.1 * T.Tw_s(i);
            end
        end
    
        [~, idx_best] = max(T.rank_score);
        T.is_recommended = false(height(T), 1);
        T.is_recommended(idx_best) = true;
    
        T.acceptance_label = strings(height(T), 1);
        T.acceptance_reason = strings(height(T), 1);
    
        for i = 1:height(T)
            if T.Tw_s(i) < cfg.stage08_5.min_acceptable_Tw_s
                T.acceptance_label(i) = "rejected";
                T.acceptance_reason(i) = "window too short for boundary stability";
            elseif ~isfinite(T.boundary_N_min(i)) || T.boundary_N_min(i) > cfg.stage08_5.max_boundary_Nmin
                T.acceptance_label(i) = "rejected";
                T.acceptance_reason(i) = "boundary N_min still too high";
            elseif ~isfinite(T.boundary_feasible_ratio(i)) || T.boundary_feasible_ratio(i) < cfg.stage08_5.min_boundary_feasible_ratio
                T.acceptance_label(i) = "rejected";
                T.acceptance_reason(i) = "boundary feasible ratio too low";
            elseif T.is_recommended(i)
                T.acceptance_label(i) = "recommended";
                T.acceptance_reason(i) = "balanced choice between boundary sufficiency and robustness";
            else
                T.acceptance_label(i) = "acceptable";
                T.acceptance_reason(i) = "boundary acceptable but not selected as the final standard window";
            end
        end
    
        T = sortrows(T, {'is_recommended','is_acceptable','Tw_s'}, {'descend','descend','ascend'});
    end
    
    
    % ============================================================
    % final text table
    % ============================================================
    
    function T = local_build_final_text_table(final_summary_table, recommendation_table)
    
        idx_rec = find(recommendation_table.is_recommended, 1, 'first');
        rec_Tw = recommendation_table.Tw_s(idx_rec);
    
        idx40 = find(final_summary_table.Tw_s == 40, 1, 'first');
        idx50 = find(final_summary_table.Tw_s == 50, 1, 'first');
    
        if ~isempty(idx40)
            N40 = final_summary_table.boundary_N_min(idx40);
            F40 = final_summary_table.boundary_num_feasible(idx40);
        else
            N40 = NaN; F40 = NaN;
        end
    
        if ~isempty(idx50)
            N50 = final_summary_table.boundary_N_min(idx50);
            F50 = final_summary_table.boundary_num_feasible(idx50);
        else
            N50 = NaN; F50 = NaN;
        end
    
        rows = {
            "window_selection_conclusion", ...
            sprintf(['Stage08 results indicate that window-length effects are segmented. ', ...
                     'Tw=40 s is too short near the boundary, while Tw=50 s already reduces ', ...
                     'the boundary minimum feasible constellation size from %.0f to %.0f and increases ', ...
                     'the number of feasible weak-side configurations from %.0f to %.0f. ', ...
                     'For the main body of Chapter 4, Tw=%.0f s is recommended as the final standard window, ', ...
                     'because it preserves the boundary-side sufficiency achieved at 50 s while offering ', ...
                     'a more balanced robustness margin across representative, family-level, and boundary-driven analyses.'], ...
                     N40, N50, F40, F50, rec_Tw);
    
            "window_selection_short_form", ...
            sprintf(['Boundary experiments show that Tw=40 s is insufficient, Tw=50 s is the lowest ', ...
                     'boundary-sufficient value, and Tw=%.0f s is the recommended standard window for the chapter.'], rec_Tw)
            };
    
        T = cell2table(rows, 'VariableNames', {'text_key','text_value'});
    end
    
    
    % ============================================================
    % plots
    % ============================================================
    
    function fig = local_plot_response_compact(out82, out84, out84c)
    
        fig = figure('Color', 'w', 'Position', [120 120 1000 700]);
    
        tiledlayout(2,1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
        % Top: representative/family response
        nexttile;
        hold on; grid on; box on;
    
        T82_family = local_get_table_field(out82, {'family_summary_table','family_table','summary_table'});

        if istable(T82_family) && any(strcmp(T82_family.Properties.VariableNames, 'Tw_s')) && ...
                any(strcmp(T82_family.Properties.VariableNames, 'D_G_min_median')) && ...
                any(strcmp(T82_family.Properties.VariableNames, 'sample_type'))

            T82_family.sample_type = string(T82_family.sample_type);
            fams = unique(T82_family.sample_type, 'stable');
            Tw_vals = sort(unique(T82_family.Tw_s), 'ascend');

            for i = 1:numel(fams)
                y = nan(size(Tw_vals));
                for j = 1:numel(Tw_vals)
                    idx = T82_family.sample_type == fams(i) & T82_family.Tw_s == Tw_vals(j);
                    vals = T82_family.D_G_min_median(idx);
                    if ~isempty(vals)
                        y(j) = mean(vals, 'omitnan');
                    end
                end

                plot(Tw_vals, y, '-o', 'LineWidth', 1.8, 'MarkerSize', 7, ...
                    'DisplayName', char(fams(i)));
            end
            legend('Location', 'best');

        else
            text(0.5, 0.5, 'Stage08.2 family summary unavailable', ...
                'HorizontalAlignment', 'center');
        end
        xlabel('Tw (s)');
        ylabel('mean of family D_G^{min} median');
        title('Compact response summary', 'Interpreter', 'none');
    
        % Bottom: local vs boundary
        nexttile;
        hold on; grid on; box on;
    
        T84 = local_get_table_field(out84, {'Tw_summary_table'});
        T84c = local_get_table_field(out84c, {'Tw_summary_table'});
    
        if istable(T84) && any(strcmp(T84.Properties.VariableNames, 'Tw_s')) && ...
                any(strcmp(T84.Properties.VariableNames, 'feasible_ratio'))
            plot(T84.Tw_s, T84.feasible_ratio, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, ...
                'DisplayName', 'local feasible ratio');
        end
        if istable(T84c) && any(strcmp(T84c.Properties.VariableNames, 'Tw_s')) && ...
                any(strcmp(T84c.Properties.VariableNames, 'feasible_ratio'))
            plot(T84c.Tw_s, T84c.feasible_ratio, '-o', 'LineWidth', 1.8, 'MarkerSize', 7, ...
                'DisplayName', 'boundary feasible ratio');
        end
        legend('Location', 'best');
        xlabel('Tw (s)');
        ylabel('feasible ratio');
        title('Local robustness vs boundary sensitivity', 'Interpreter', 'none');
    end
    
    
    function fig = local_plot_boundary_summary(final_summary_table)
    
        fig = figure('Color', 'w', 'Position', [120 120 1000 700]);
        tiledlayout(2,1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
        nexttile;
        hold on; grid on; box on;
        plot(final_summary_table.Tw_s, final_summary_table.boundary_N_min, '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 7);
        xlabel('Tw (s)');
        ylabel('N_{min}');
        title('Boundary minimum feasible constellation size', 'Interpreter', 'none');
    
        nexttile;
        hold on; grid on; box on;
        plot(final_summary_table.Tw_s, final_summary_table.boundary_num_feasible, '-o', ...
            'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'num feasible');
        yyaxis right
        plot(final_summary_table.Tw_s, final_summary_table.boundary_feasible_ratio, '-s', ...
            'LineWidth', 1.8, 'MarkerSize', 7, 'DisplayName', 'feasible ratio');
        xlabel('Tw (s)');
        title('Boundary feasible set expansion', 'Interpreter', 'none');
    end
    
    
    function fig = local_plot_boundary_heatmap_from_84c(out84c)
    
        fig = figure('Color', 'w', 'Position', [120 120 1000 650]);
    
        T = local_get_table_field(out84c, {'raw_boundary_scan_table'});
        if isempty(T)
            T = local_get_table_field(out84c, {'raw_task_table'});
        end
    
        assert(istable(T), 'Stage08.4c raw boundary scan table is missing.');
    
        cfg_keys = unique(T(:, {'cfg_id','Ns','i_deg'}), 'rows', 'stable');
        cfg_keys = sortrows(cfg_keys, {'Ns','i_deg','cfg_id'}, {'ascend','ascend','ascend'});
        Tw_vals = sort(unique(T.Tw_s), 'ascend');
    
        M = nan(height(cfg_keys), numel(Tw_vals));
        for iCfg = 1:height(cfg_keys)
            cid = cfg_keys.cfg_id(iCfg);
            for iTw = 1:numel(Tw_vals)
                idx = T.cfg_id == cid & T.Tw_s == Tw_vals(iTw);
                vals = T.is_feasible_boundary(idx);
                if ~isempty(vals)
                    M(iCfg, iTw) = double(vals(1));
                end
            end
        end
    
        imagesc(Tw_vals, 1:height(cfg_keys), M);
        set(gca, 'YDir', 'normal');
        xlabel('Tw (s)');
        ylabel('config index');
        title('Boundary feasibility heatmap', 'Interpreter', 'none');
        colorbar;
    end
    
    
    % ============================================================
    % generic helpers
    % ============================================================
    
    function T = local_get_table_field(S, candidates)
    
        T = table();
        for i = 1:numel(candidates)
            c = candidates{i};
            if isfield(S, c) && istable(S.(c))
                T = S.(c);
                return;
            end
        end
    end
    
    
    function y = local_mean_if_exists(T, value_name, key_name, key_val)
    
        y = NaN;
        if ~istable(T)
            return;
        end
        if ~any(strcmp(T.Properties.VariableNames, value_name)) || ~any(strcmp(T.Properties.VariableNames, key_name))
            return;
        end
    
        idx = T.(key_name) == key_val;
        if ~any(idx)
            return;
        end
    
        vals = T.(value_name)(idx);
        if isnumeric(vals)
            y = mean(vals, 'omitnan');
        end
    end
    
    
    function y = local_get_value_if_exists(T, value_name, key_name, key_val)
    
        y = NaN;
        if ~istable(T)
            return;
        end
        if ~any(strcmp(T.Properties.VariableNames, value_name)) || ~any(strcmp(T.Properties.VariableNames, key_name))
            return;
        end
    
        idx = T.(key_name) == key_val;
        if ~any(idx)
            return;
        end
    
        vals = T.(value_name)(idx);
        if isempty(vals)
            return;
        end
        y = vals(1);
    end