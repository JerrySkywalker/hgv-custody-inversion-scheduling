function out = stage06_compare_with_stage05(cfg)
    %STAGE06_COMPARE_WITH_STAGE05
    % Stage06.4:
    %   Compare Stage06 heading-extended physical search results against
    %   Stage05 nominal search results and generate summary tables for paper use.
    %
    % Main outputs:
    %   1) global_summary
    %   2) feasible_mismatch
    %   3) frontier_compare_by_i
    %   4) IP_compare_minNs
    %   5) metric_diff_all
    %
    % Notes:
    %   - This version is intended as a formal comparison-summary stage.
    %   - It keeps the diagnostic capability but emphasizes paper-ready tables.

        startup();
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage06_prepare_cfg(cfg);
        cfg.project_stage = 'stage06_compare_with_stage05';
        run_tag = char(cfg.stage06.run_tag);

        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);

        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_compare_with_stage05_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06.4 compare started.');
    
        % ============================================================
        % Load latest Stage05 cache
        % ============================================================
        d5 = dir(fullfile(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat'));
        assert(~isempty(d5), ...
            'No Stage05 cache found. Please run stage05_nominal_walker_search first.');
    
        [~, idx5] = max([d5.datenum]);
        stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
        S5 = load(stage05_file);
    
        assert(isfield(S5, 'out') && isfield(S5.out, 'grid'), ...
            'Invalid Stage05 cache: missing out.grid');
    
        grid05 = S5.out.grid;
        log_msg(log_fid, 'INFO', 'Loaded Stage05 cache: %s', stage05_file);
    
        % ============================================================
        % Load latest Stage06 cache (by run_tag)
        % ============================================================
        d6 = dir(fullfile(cfg.paths.cache, ...
            sprintf('stage06_heading_walker_search_%s_*.mat', run_tag)));
        assert(~isempty(d6), ...
            'No Stage06 cache found for run_tag: %s. Please run stage06_heading_walker_search first.', run_tag);
    
        [~, idx6] = max([d6.datenum]);
        stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);
        S6 = load(stage06_file);
    
        assert(isfield(S6, 'out') && isfield(S6.out, 'grid'), ...
            'Invalid Stage06 cache: missing out.grid');
    
        grid06 = S6.out.grid;
        log_msg(log_fid, 'INFO', 'Loaded Stage06 cache: %s', stage06_file);
    
        % ============================================================
        % Normalize and join
        % ============================================================
        keyVars = {'i_deg','P','T'};
        vars_needed = {'i_deg','P','T','Ns','D_G_min','pass_ratio','feasible_flag'};
    
        local_assert_vars(grid05, vars_needed, 'Stage05 grid');
        local_assert_vars(grid06, vars_needed, 'Stage06 grid');
    
        T05 = grid05(:, vars_needed);
        T06 = grid06(:, vars_needed);
    
        T05 = renamevars(T05, ...
            {'Ns','D_G_min','pass_ratio','feasible_flag'}, ...
            {'Ns_05','D_G_min_05','pass_ratio_05','feasible_05'});
    
        T06 = renamevars(T06, ...
            {'Ns','D_G_min','pass_ratio','feasible_flag'}, ...
            {'Ns_06','D_G_min_06','pass_ratio_06','feasible_06'});
    
        Tcmp = innerjoin(T05, T06, 'Keys', keyVars);
        assert(~isempty(Tcmp), 'No common grid points found between Stage05 and Stage06.');
    
        Tcmp.delta_Ns = Tcmp.Ns_06 - Tcmp.Ns_05;
        Tcmp.delta_D_G_min = Tcmp.D_G_min_06 - Tcmp.D_G_min_05;
        Tcmp.delta_pass_ratio = Tcmp.pass_ratio_06 - Tcmp.pass_ratio_05;
        Tcmp.feasible_same = (Tcmp.feasible_06 == Tcmp.feasible_05);
    
        nCommon = height(Tcmp);
    
        % ============================================================
        % Table 1: global summary
        % ============================================================
        n_stage05_total = height(grid05);
        n_stage06_total = height(grid06);
    
        n_stage05_feasible = sum(grid05.feasible_flag);
        n_stage06_feasible = sum(grid06.feasible_flag);
    
        feasible_ratio_05 = n_stage05_feasible / n_stage05_total;
        feasible_ratio_06 = n_stage06_feasible / n_stage06_total;
    
        if n_stage05_feasible > 0
            best05 = sortrows(grid05(grid05.feasible_flag,:), {'Ns','D_G_min'}, {'ascend','descend'});
            best05_Ns = best05.Ns(1);
            best05_i = best05.i_deg(1);
            best05_P = best05.P(1);
            best05_T = best05.T(1);
            best05_DG = best05.D_G_min(1);
        else
            best05_Ns = NaN; best05_i = NaN; best05_P = NaN; best05_T = NaN; best05_DG = NaN;
        end
    
        if n_stage06_feasible > 0
            best06 = sortrows(grid06(grid06.feasible_flag,:), {'Ns','D_G_min'}, {'ascend','descend'});
            best06_Ns = best06.Ns(1);
            best06_i = best06.i_deg(1);
            best06_P = best06.P(1);
            best06_T = best06.T(1);
            best06_DG = best06.D_G_min(1);
        else
            best06_Ns = NaN; best06_i = NaN; best06_P = NaN; best06_T = NaN; best06_DG = NaN;
        end
    
        global_summary = table( ...
            n_stage05_total, ...
            n_stage06_total, ...
            n_stage05_feasible, ...
            n_stage06_feasible, ...
            feasible_ratio_05, ...
            feasible_ratio_06, ...
            n_stage06_feasible - n_stage05_feasible, ...
            feasible_ratio_06 - feasible_ratio_05, ...
            best05_Ns, best06_Ns, best06_Ns - best05_Ns, ...
            best05_i, best05_P, best05_T, best05_DG, ...
            best06_i, best06_P, best06_T, best06_DG, ...
            'VariableNames', { ...
            'n_stage05_total', ...
            'n_stage06_total', ...
            'n_stage05_feasible', ...
            'n_stage06_feasible', ...
            'feasible_ratio_stage05', ...
            'feasible_ratio_stage06', ...
            'delta_feasible_count', ...
            'delta_feasible_ratio', ...
            'best_Ns_stage05', ...
            'best_Ns_stage06', ...
            'delta_best_Ns', ...
            'best_i_stage05', ...
            'best_P_stage05', ...
            'best_T_stage05', ...
            'best_D_G_min_stage05', ...
            'best_i_stage06', ...
            'best_P_stage06', ...
            'best_T_stage06', ...
            'best_D_G_min_stage06'});
    
        % ============================================================
        % Table 2: feasible mismatch
        % ============================================================
        feasible_mismatch = Tcmp(~Tcmp.feasible_same, ...
            {'i_deg','P','T','Ns_05','Ns_06', ...
             'feasible_05','feasible_06', ...
             'D_G_min_05','D_G_min_06','delta_D_G_min', ...
             'pass_ratio_05','pass_ratio_06','delta_pass_ratio'});
    
        feasible_mismatch = sortrows(feasible_mismatch, {'i_deg','P','T'}, {'ascend','ascend','ascend'});
    
        % ============================================================
        % Table 3: frontier compare by i
        % ============================================================
        i_list = unique(Tcmp.i_deg);
        frontier_rows = [];
    
        for ii = 1:numel(i_list)
            i_deg = i_list(ii);
    
            sub05 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.feasible_05, :);
            sub06 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.feasible_06, :);
    
            if isempty(sub05)
                minNs05 = NaN; DG05 = NaN; pass05 = NaN; P05 = NaN; T05v = NaN;
            else
                sub05 = sortrows(sub05, {'Ns_05','D_G_min_05'}, {'ascend','descend'});
                minNs05 = sub05.Ns_05(1);
                DG05 = sub05.D_G_min_05(1);
                pass05 = sub05.pass_ratio_05(1);
                P05 = sub05.P(1);
                T05v = sub05.T(1);
            end
    
            if isempty(sub06)
                minNs06 = NaN; DG06 = NaN; pass06 = NaN; P06 = NaN; T06v = NaN;
            else
                sub06 = sortrows(sub06, {'Ns_06','D_G_min_06'}, {'ascend','descend'});
                minNs06 = sub06.Ns_06(1);
                DG06 = sub06.D_G_min_06(1);
                pass06 = sub06.pass_ratio_06(1);
                P06 = sub06.P(1);
                T06v = sub06.T(1);
            end
    
            frontier_rows = [frontier_rows; ...
                {i_deg, ...
                 minNs05, minNs06, minNs06-minNs05, ...
                 P05, T05v, DG05, pass05, ...
                 P06, T06v, DG06, pass06}]; %#ok<AGROW>
        end
    
        frontier_compare_by_i = cell2table(frontier_rows, 'VariableNames', { ...
            'i_deg', ...
            'min_feasible_Ns_stage05', ...
            'min_feasible_Ns_stage06', ...
            'delta_Ns', ...
            'best_P_stage05', ...
            'best_T_stage05', ...
            'D_G_min_stage05', ...
            'pass_ratio_stage05', ...
            'best_P_stage06', ...
            'best_T_stage06', ...
            'D_G_min_stage06', ...
            'pass_ratio_stage06'});
    
        frontier_compare_by_i.frontier_same = ...
            ((isnan(frontier_compare_by_i.min_feasible_Ns_stage05) & isnan(frontier_compare_by_i.min_feasible_Ns_stage06)) | ...
             (frontier_compare_by_i.min_feasible_Ns_stage05 == frontier_compare_by_i.min_feasible_Ns_stage06));
    
        frontier_compare_by_i.frontier_shift = strings(height(frontier_compare_by_i),1);
        for k = 1:height(frontier_compare_by_i)
            d = frontier_compare_by_i.delta_Ns(k);
            if isnan(d)
                frontier_compare_by_i.frontier_shift(k) = "undefined";
            elseif d > 0
                frontier_compare_by_i.frontier_shift(k) = "right_shift";
            elseif d < 0
                frontier_compare_by_i.frontier_shift(k) = "left_shift";
            else
                frontier_compare_by_i.frontier_shift(k) = "unchanged";
            end
        end
    
        % ============================================================
        % Table 4: (i,P) min feasible Ns matrix-form long table
        % ============================================================
        IP = unique(Tcmp(:, {'i_deg','P'}));
        mat_rows = [];
    
        for k = 1:height(IP)
            i_deg = IP.i_deg(k);
            P = IP.P(k);
    
            sub05 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.P == P & Tcmp.feasible_05, :);
            sub06 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.P == P & Tcmp.feasible_06, :);
    
            if isempty(sub05)
                minNs05 = NaN;
            else
                minNs05 = min(sub05.Ns_05);
            end
    
            if isempty(sub06)
                minNs06 = NaN;
            else
                minNs06 = min(sub06.Ns_06);
            end
    
            mat_rows = [mat_rows; {i_deg, P, minNs05, minNs06, minNs06 - minNs05}]; %#ok<AGROW>
        end
    
        IP_compare_minNs = cell2table(mat_rows, 'VariableNames', { ...
            'i_deg','P', ...
            'min_feasible_Ns_stage05', ...
            'min_feasible_Ns_stage06', ...
            'delta_Ns'});
    
        % ============================================================
        % Table 5: full metric diff
        % ============================================================
        metric_diff_all = Tcmp(:, ...
            {'i_deg','P','T','Ns_05','Ns_06', ...
             'D_G_min_05','D_G_min_06','delta_D_G_min', ...
             'pass_ratio_05','pass_ratio_06','delta_pass_ratio', ...
             'feasible_05','feasible_06','feasible_same'});
    
        metric_diff_all = sortrows(metric_diff_all, {'i_deg','P','T'}, {'ascend','ascend','ascend'});
    
        % ============================================================
        % Automated summary
        % ============================================================
        auto_summary = struct();
        auto_summary.n_common = nCommon;
        auto_summary.feasible_same_ratio = mean(Tcmp.feasible_same);
        auto_summary.frontier_same_ratio = mean(frontier_compare_by_i.frontier_same);
        auto_summary.n_feasible_mismatch = height(feasible_mismatch);
        auto_summary.n_frontier_shift = sum(frontier_compare_by_i.delta_Ns ~= 0, 'omitnan');
    
        if auto_summary.n_feasible_mismatch == 0 && auto_summary.n_frontier_shift == 0
            auto_summary.message = ...
                "Stage06 and Stage05 are effectively identical in feasible set and frontier.";
        else
            auto_summary.message = ...
                "Stage06 differs from Stage05 in feasible set and/or frontier, indicating a real heading-uncertainty effect.";
        end
    
        % ============================================================
        % Save csv
        % ============================================================
        global_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_global_%s_%s.csv', run_tag, timestamp));
        feasible_mismatch_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_feasible_mismatch_%s_%s.csv', run_tag, timestamp));
        frontier_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_frontier_%s_%s.csv', run_tag, timestamp));
        ip_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_IP_minNs_%s_%s.csv', run_tag, timestamp));
        metric_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_metric_diff_%s_%s.csv', run_tag, timestamp));
    
        writetable(global_summary, global_csv);
        writetable(feasible_mismatch, feasible_mismatch_csv);
        writetable(frontier_compare_by_i, frontier_csv);
        writetable(IP_compare_minNs, ip_csv);
        writetable(metric_diff_all, metric_csv);
    
        % ============================================================
        % Save cache
        % ============================================================
        out = struct();
        out.global_summary = global_summary;
        out.feasible_mismatch = feasible_mismatch;
        out.frontier_compare_by_i = frontier_compare_by_i;
        out.IP_compare_minNs = IP_compare_minNs;
        out.metric_diff_all = metric_diff_all;
        out.auto_summary = auto_summary;
        out.stage05_file = stage05_file;
        out.stage06_file = stage06_file;
        out.log_file = log_file;
        out.files = struct();
        out.files.global_csv = global_csv;
        out.files.feasible_mismatch_csv = feasible_mismatch_csv;
        out.files.frontier_csv = frontier_csv;
        out.files.ip_csv = ip_csv;
        out.files.metric_csv = metric_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_compare_with_stage05_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logging
        % ============================================================
        log_msg(log_fid, 'INFO', 'n_common = %d', nCommon);
        log_msg(log_fid, 'INFO', 'n_feasible_mismatch = %d', auto_summary.n_feasible_mismatch);
        log_msg(log_fid, 'INFO', 'n_frontier_shift = %d', auto_summary.n_frontier_shift);
        log_msg(log_fid, 'INFO', 'feasible_same_ratio = %.6f', auto_summary.feasible_same_ratio);
        log_msg(log_fid, 'INFO', 'frontier_same_ratio = %.6f', auto_summary.frontier_same_ratio);
        log_msg(log_fid, 'INFO', 'Summary: %s', auto_summary.message);
        log_msg(log_fid, 'INFO', 'Stage06.4 compare finished.');
    
        fprintf('\n');
        fprintf('========== Stage06.4 Summary ==========\n');
        fprintf('Stage05 file           : %s\n', stage05_file);
        fprintf('Stage06 file           : %s\n', stage06_file);
        fprintf('n_common               : %d\n', nCommon);
        fprintf('n_feasible_mismatch    : %d\n', auto_summary.n_feasible_mismatch);
        fprintf('n_frontier_shift       : %d\n', auto_summary.n_frontier_shift);
        fprintf('feasible_same_ratio    : %.6f\n', auto_summary.feasible_same_ratio);
        fprintf('frontier_same_ratio    : %.6f\n', auto_summary.frontier_same_ratio);
        fprintf('Summary                : %s\n', auto_summary.message);
        fprintf('Global CSV             : %s\n', global_csv);
        fprintf('Mismatch CSV           : %s\n', feasible_mismatch_csv);
        fprintf('Frontier CSV           : %s\n', frontier_csv);
        fprintf('IP CSV                 : %s\n', ip_csv);
        fprintf('Metric CSV             : %s\n', metric_csv);
        fprintf('Cache                  : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    % =========================================================================
    % local helper
    % =========================================================================
    function local_assert_vars(T, vars_needed, tag)
        missing = setdiff(vars_needed, T.Properties.VariableNames);
        assert(isempty(missing), '%s missing variables: %s', tag, strjoin(missing, ', '));
    end