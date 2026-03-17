function out = stage07_select_reference_walker(cfg)
    %STAGE07_SELECT_REFERENCE_WALKER
    % Stage07.1:
    %   Select one fixed reference Walker from Stage05 nominal feasible results.
    %
    % Main tasks:
    %   1) load latest Stage04 cache and inherit gamma_req
    %   2) load latest Stage05 nominal Walker search cache
    %   3) choose one reference Walker using Stage07 selection rule
    %   4) save reference Walker spec / summary / cache
    %
    % Outputs:
    %   out.reference_walker
    %   out.selection_table
    %   out.summary_table
    %   out.files
    %
    % Notes:
    %   - This stage does NOT generate C1/C2 yet
    %   - This stage defines the fixed Walker baseline for all later Stage07 steps
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg.project_stage = 'stage07_select_reference_walker';
        cfg = configure_stage_output_paths(cfg);
        run_tag = char(cfg.stage07.run_tag);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage07_select_reference_walker_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage07.1 started.');
    
        % ============================================================
        % Load latest Stage04 cache: inherit gamma_req
        % ============================================================
        d4 = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
        assert(~isempty(d4), ...
            'No Stage04 cache found. Please run stage04_window_worstcase first.');
    
        [~, idx4] = max([d4.datenum]);
        stage04_file = fullfile(d4(idx4).folder, d4(idx4).name);
        S4 = load(stage04_file);
    
        assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
        assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
            'Stage04 cache missing summary.gamma_meta');
    
        gamma_req = S4.out.summary.gamma_meta.gamma_req;
        log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
        log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
    
        % ============================================================
        % Load latest Stage05 cache
        % ============================================================
        d5 = find_stage_cache_files(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat');
        assert(~isempty(d5), ...
            'No Stage05 cache found. Please run stage05_nominal_walker_search first.');
    
        [~, idx5] = max([d5.datenum]);
        stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
        S5 = load(stage05_file);
    
        assert(isfield(S5, 'out'), 'Invalid Stage05 cache: missing out');
        O5 = S5.out;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage05 cache: %s', stage05_file);
    
        % ============================================================
        % Resolve candidate table from Stage05 cache
        % ============================================================
        candidate_table = local_extract_stage05_candidate_table(O5, cfg);
        assert(~isempty(candidate_table), ...
            'Stage05 cache does not contain usable feasible candidates.');
    
        % normalize / enrich table
        candidate_table = local_prepare_candidate_table(candidate_table, cfg, gamma_req);
    
        % ============================================================
        % Select reference Walker
        % ============================================================
        selection_rule = string(cfg.stage07.reference_selection_rule);
    
        switch lower(selection_rule)
            case "frontier_near_feasible"
                [selected_row, ranking_table] = local_select_frontier_near(candidate_table, cfg);
    
            case "best_feasible"
                [selected_row, ranking_table] = local_select_best_feasible(candidate_table, cfg);
    
            otherwise
                error('Unknown cfg.stage07.reference_selection_rule: %s', selection_rule);
        end
    
        reference_walker = struct();
        reference_walker.source_stage = 'stage05_nominal';
        reference_walker.selection_rule = char(selection_rule);
        reference_walker.gamma_req = gamma_req;
    
        reference_walker.h_km = local_get_row_value(selected_row, 'h_km', cfg.stage07.default_h_km);
        reference_walker.i_deg = local_get_row_value(selected_row, 'i_deg');
        reference_walker.P = local_get_row_value(selected_row, 'P');
        reference_walker.T = local_get_row_value(selected_row, 'T');
        reference_walker.F = local_get_row_value(selected_row, 'F', cfg.stage07.default_F);
        reference_walker.Ns = local_get_row_value(selected_row, 'Ns', ...
            reference_walker.P * reference_walker.T);
    
        reference_walker.D_G_min = local_get_row_value(selected_row, 'D_G_min', NaN);
        reference_walker.pass_ratio = local_get_row_value(selected_row, 'pass_ratio', NaN);
        reference_walker.margin_to_DG = local_get_row_value(selected_row, 'margin_to_DG', NaN);
    
        % ============================================================
        % Save summary table
        % ============================================================
        summary_table = table( ...
            string(reference_walker.source_stage), ...
            string(reference_walker.selection_rule), ...
            reference_walker.h_km, ...
            reference_walker.i_deg, ...
            reference_walker.P, ...
            reference_walker.T, ...
            reference_walker.F, ...
            reference_walker.Ns, ...
            reference_walker.D_G_min, ...
            reference_walker.pass_ratio, ...
            reference_walker.margin_to_DG, ...
            reference_walker.gamma_req, ...
            'VariableNames', { ...
                'source_stage', ...
                'selection_rule', ...
                'h_km', ...
                'i_deg', ...
                'P', ...
                'T', ...
                'F', ...
                'Ns', ...
                'D_G_min', ...
                'pass_ratio', ...
                'margin_to_DG', ...
                'gamma_req'});
    
        ranking_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_reference_walker_ranking_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage07_reference_walker_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(ranking_table, ranking_csv);
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save cache
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.reference_walker = reference_walker;
        out.selection_table = ranking_table;
        out.summary_table = summary_table;
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage04_file = stage04_file;
        out.files.stage05_file = stage05_file;
        out.files.ranking_csv = ranking_csv;
        out.files.summary_csv = summary_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logs
        % ============================================================
        log_msg(log_fid, 'INFO', 'Selection rule = %s', selection_rule);
        log_msg(log_fid, 'INFO', ...
            'Reference Walker = h=%.1f km | i=%.1f deg | P=%d | T=%d | F=%d | Ns=%d | D_G_min=%.3f | pass_ratio=%.3f', ...
            reference_walker.h_km, reference_walker.i_deg, ...
            reference_walker.P, reference_walker.T, reference_walker.F, reference_walker.Ns, ...
            reference_walker.D_G_min, reference_walker.pass_ratio);
        log_msg(log_fid, 'INFO', 'Ranking CSV saved to: %s', ranking_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage07.1 finished.');
    
        fprintf('\n');
        fprintf('========== Stage07.1 Summary ==========\n');
        fprintf('Stage04 cache        : %s\n', stage04_file);
        fprintf('Stage05 cache        : %s\n', stage05_file);
        fprintf('Selection rule       : %s\n', char(selection_rule));
        fprintf('Reference Walker     : h=%.1f km | i=%.1f deg | P=%d | T=%d | F=%d | Ns=%d\n', ...
            reference_walker.h_km, reference_walker.i_deg, ...
            reference_walker.P, reference_walker.T, reference_walker.F, reference_walker.Ns);
        fprintf('D_G_min / pass_ratio : %.3f / %.3f\n', ...
            reference_walker.D_G_min, reference_walker.pass_ratio);
        fprintf('gamma_req            : %.6e\n', reference_walker.gamma_req);
        fprintf('Ranking CSV          : %s\n', ranking_csv);
        fprintf('Summary CSV          : %s\n', summary_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    function T = local_extract_stage05_candidate_table(O5, cfg)
    
        T = table();
    
        % Priority 1: feasible_grid
        if isfield(O5, 'feasible_grid') && istable(O5.feasible_grid) && ~isempty(O5.feasible_grid)
            T = O5.feasible_grid;
            return;
        end
    
        % Priority 2: summary.best_feasible (single-row fallback)
        if isfield(O5, 'summary') && isfield(O5.summary, 'best_feasible') && ...
                istable(O5.summary.best_feasible) && ~isempty(O5.summary.best_feasible)
            T = O5.summary.best_feasible;
            return;
        end
    
        % Priority 3: full grid filtered by feasible flag
        if isfield(O5, 'grid') && istable(O5.grid) && ~isempty(O5.grid)
            T0 = O5.grid;
            if any(strcmp(T0.Properties.VariableNames, 'feasible_flag'))
                T = T0(T0.feasible_flag == true, :);
                if ~isempty(T)
                    return;
                end
            end
        end
    
        % Last fallback: empty
        T = table();
    end
    
    
    function T = local_prepare_candidate_table(T, cfg, gamma_req)
    
        assert(istable(T) && ~isempty(T), 'Candidate table is empty.');
    
        % guarantee h_km / F / Ns
        if ~any(strcmp(T.Properties.VariableNames, 'h_km'))
            T.h_km = repmat(cfg.stage07.default_h_km, height(T), 1);
        end
        if ~any(strcmp(T.Properties.VariableNames, 'F'))
            T.F = repmat(cfg.stage07.default_F, height(T), 1);
        end
        if ~any(strcmp(T.Properties.VariableNames, 'Ns'))
            T.Ns = T.P .* T.T;
        end
    
        if ~any(strcmp(T.Properties.VariableNames, 'D_G_min'))
            error('Candidate table missing D_G_min.');
        end
        if ~any(strcmp(T.Properties.VariableNames, 'pass_ratio'))
            error('Candidate table missing pass_ratio.');
        end
    
        T.margin_to_DG = T.D_G_min - cfg.stage07.require_D_G_min;
        T.gamma_req = repmat(gamma_req, height(T), 1);
    
        % hard filter again for safety
        keep = (T.D_G_min >= cfg.stage07.require_D_G_min) & ...
               (T.pass_ratio >= cfg.stage07.require_pass_ratio);
        T = T(keep, :);
    
        assert(~isempty(T), ...
            'No feasible candidate remains after Stage07 threshold filtering.');
    end
    
    
    function [selected_row, ranking_table] = local_select_frontier_near(T, cfg)
    
        % smaller positive margin first; then smaller Ns; then smaller i_deg
        score_margin = T.margin_to_DG;
        score_Ns = T.Ns;
        score_i = T.i_deg;
    
        [~, ord] = sortrows([score_margin, score_Ns, score_i], [1 2 3]);
        ranking_table = T(ord, :);
        selected_row = ranking_table(1, :);
    end
    
    
    function [selected_row, ranking_table] = local_select_best_feasible(T, cfg) %#ok<INUSD>
    
        % larger D_G_min first; then smaller Ns
        score_DG = -T.D_G_min;
        score_Ns = T.Ns;
        score_i = T.i_deg;
    
        [~, ord] = sortrows([score_DG, score_Ns, score_i], [1 2 3]);
        ranking_table = T(ord, :);
        selected_row = ranking_table(1, :);
    end
    
    
    function val = local_get_row_value(row, name, default_val)
        if nargin < 3
            default_val = [];
        end
    
        if istable(row) && any(strcmp(row.Properties.VariableNames, name))
            x = row.(name);
            if ~isempty(x)
                val = x(1);
                return;
            end
        end
    
        if ~isempty(default_val)
            val = default_val;
        else
            error('Missing required row field: %s', name);
        end
    end
