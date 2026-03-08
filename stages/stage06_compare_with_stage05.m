function out = stage06_compare_with_stage05()
    %STAGE06_COMPARE_WITH_STAGE05
    % Check whether current Stage06 results are effectively identical to Stage05.
    %
    % Purpose:
    %   This is a verification-oriented comparison script.
    %   It is NOT the final paper plotting script yet.
    %
    % Main checks:
    %   1) feasible_flag consistency on common (i,P,T)
    %   2) D_G_min difference
    %   3) pass_ratio difference
    %   4) frontier (minimum feasible Ns by i) consistency
    %
    % Interpretation:
    %   If Stage06.2 only duplicated nominal trajectories with heading labels
    %   but did not change trajectory geometry, then Stage06 and Stage05 should
    %   be nearly identical on common grid points.
    
        startup();
        cfg = default_params();
        cfg.project_stage = 'stage06_compare_with_stage05';
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage06_compare_with_stage05_%s.log', timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage06 compare-with-Stage05 started.');
    
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
        % Load latest Stage06 cache
        % ============================================================
        d6 = dir(fullfile(cfg.paths.cache, 'stage06_heading_walker_search_*.mat'));
        assert(~isempty(d6), ...
            'No Stage06 cache found. Please run stage06_heading_walker_search first.');
    
        [~, idx6] = max([d6.datenum]);
        stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);
        S6 = load(stage06_file);
    
        assert(isfield(S6, 'out') && isfield(S6.out, 'grid'), ...
            'Invalid Stage06 cache: missing out.grid');
    
        grid06 = S6.out.grid;
        log_msg(log_fid, 'INFO', 'Loaded Stage06 cache: %s', stage06_file);
    
        % ============================================================
        % Normalize key names
        % ============================================================
        keyVars = {'i_deg','P','T'};
    
        vars_needed = { ...
            'i_deg','P','T','Ns', ...
            'D_G_min','pass_ratio','feasible_flag'};
    
        local_assert_vars(grid05, vars_needed, 'Stage05 grid');
        local_assert_vars(grid06, vars_needed, 'Stage06 grid');
    
        T05 = grid05(:, vars_needed);
        T06 = grid06(:, vars_needed);
    
        % rename for join
        T05 = renamevars(T05, ...
            {'Ns','D_G_min','pass_ratio','feasible_flag'}, ...
            {'Ns_05','D_G_min_05','pass_ratio_05','feasible_05'});
    
        T06 = renamevars(T06, ...
            {'Ns','D_G_min','pass_ratio','feasible_flag'}, ...
            {'Ns_06','D_G_min_06','pass_ratio_06','feasible_06'});
    
        % ============================================================
        % Inner join on common grid
        % ============================================================
        Tcmp = innerjoin(T05, T06, 'Keys', keyVars);
        assert(~isempty(Tcmp), 'No common grid points found between Stage05 and Stage06.');
    
        nCommon = height(Tcmp);
    
        % ============================================================
        % Pointwise differences
        % ============================================================
        Tcmp.delta_Ns = Tcmp.Ns_06 - Tcmp.Ns_05;
        Tcmp.delta_D_G_min = Tcmp.D_G_min_06 - Tcmp.D_G_min_05;
        Tcmp.delta_pass_ratio = Tcmp.pass_ratio_06 - Tcmp.pass_ratio_05;
        Tcmp.feasible_same = (Tcmp.feasible_06 == Tcmp.feasible_05);
    
        abs_tol_DG = 1e-10;
        abs_tol_pass = 1e-10;
    
        Tcmp.D_G_min_same = abs(Tcmp.delta_D_G_min) <= abs_tol_DG;
        Tcmp.pass_ratio_same = abs(Tcmp.delta_pass_ratio) <= abs_tol_pass;
    
        % ============================================================
        % Summary 1: global consistency
        % ============================================================
        summary_global = table();
    
        summary_global.n_common = nCommon;
        summary_global.n_feasible_same = sum(Tcmp.feasible_same);
        summary_global.feasible_same_ratio = mean(Tcmp.feasible_same);
    
        summary_global.max_abs_delta_D_G_min = max(abs(Tcmp.delta_D_G_min), [], 'omitnan');
        summary_global.mean_abs_delta_D_G_min = mean(abs(Tcmp.delta_D_G_min), 'omitnan');
        summary_global.n_D_G_min_same = sum(Tcmp.D_G_min_same);
        summary_global.D_G_min_same_ratio = mean(Tcmp.D_G_min_same);
    
        summary_global.max_abs_delta_pass_ratio = max(abs(Tcmp.delta_pass_ratio), [], 'omitnan');
        summary_global.mean_abs_delta_pass_ratio = mean(abs(Tcmp.delta_pass_ratio), 'omitnan');
        summary_global.n_pass_ratio_same = sum(Tcmp.pass_ratio_same);
        summary_global.pass_ratio_same_ratio = mean(Tcmp.pass_ratio_same);
    
        summary_global.n_stage05_feasible = sum(Tcmp.feasible_05);
        summary_global.n_stage06_feasible = sum(Tcmp.feasible_06);
    
        % ============================================================
        % Summary 2: feasible mismatch table
        % ============================================================
        mismatch_feasible = Tcmp(~Tcmp.feasible_same, ...
            {'i_deg','P','T','Ns_05','Ns_06','feasible_05','feasible_06', ...
             'D_G_min_05','D_G_min_06','pass_ratio_05','pass_ratio_06'});
    
        % ============================================================
        % Summary 3: metric-difference table
        % ============================================================
        metric_diff = Tcmp(:, ...
            {'i_deg','P','T','Ns_05','Ns_06', ...
             'D_G_min_05','D_G_min_06','delta_D_G_min', ...
             'pass_ratio_05','pass_ratio_06','delta_pass_ratio', ...
             'feasible_05','feasible_06','feasible_same'});
    
        % ============================================================
        % Summary 4: frontier by i
        % ============================================================
        i_list = unique(Tcmp.i_deg);
        frontier_rows = [];
    
        for ii = 1:numel(i_list)
            i_deg = i_list(ii);
    
            sub05 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.feasible_05, :);
            sub06 = Tcmp(Tcmp.i_deg == i_deg & Tcmp.feasible_06, :);
    
            if isempty(sub05)
                minNs05 = NaN;
                DG05 = NaN;
                pass05 = NaN;
            else
                sub05 = sortrows(sub05, {'Ns_05','D_G_min_05'}, {'ascend','descend'});
                minNs05 = sub05.Ns_05(1);
                DG05 = sub05.D_G_min_05(1);
                pass05 = sub05.pass_ratio_05(1);
            end
    
            if isempty(sub06)
                minNs06 = NaN;
                DG06 = NaN;
                pass06 = NaN;
            else
                sub06 = sortrows(sub06, {'Ns_06','D_G_min_06'}, {'ascend','descend'});
                minNs06 = sub06.Ns_06(1);
                DG06 = sub06.D_G_min_06(1);
                pass06 = sub06.pass_ratio_06(1);
            end
    
            frontier_rows = [frontier_rows; ...
                {i_deg, minNs05, minNs06, minNs06-minNs05, DG05, DG06, pass05, pass06}]; %#ok<AGROW>
        end
    
        frontier_compare = cell2table(frontier_rows, 'VariableNames', { ...
            'i_deg', ...
            'min_feasible_Ns_stage05', ...
            'min_feasible_Ns_stage06', ...
            'delta_Ns', ...
            'D_G_min_stage05', ...
            'D_G_min_stage06', ...
            'pass_ratio_stage05', ...
            'pass_ratio_stage06'});
    
        frontier_compare.frontier_same = ...
            ((isnan(frontier_compare.min_feasible_Ns_stage05) & isnan(frontier_compare.min_feasible_Ns_stage06)) | ...
             (frontier_compare.min_feasible_Ns_stage05 == frontier_compare.min_feasible_Ns_stage06));
    
        % ============================================================
        % Summary 5: matrix by (i,P)
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
    
        IP_compare = cell2table(mat_rows, 'VariableNames', { ...
            'i_deg','P', ...
            'min_feasible_Ns_stage05', ...
            'min_feasible_Ns_stage06', ...
            'delta_Ns'});
    
        % ============================================================
        % Automated judgement
        % ============================================================
        auto_judgement = struct();
        auto_judgement.feasible_same_ratio = summary_global.feasible_same_ratio;
        auto_judgement.D_G_min_same_ratio = summary_global.D_G_min_same_ratio;
        auto_judgement.pass_ratio_same_ratio = summary_global.pass_ratio_same_ratio;
        auto_judgement.frontier_same_ratio = mean(frontier_compare.frontier_same);
    
        % rule of thumb
        auto_judgement.is_effectively_identical = ...
            (auto_judgement.feasible_same_ratio >= 0.999) && ...
            (auto_judgement.D_G_min_same_ratio >= 0.999) && ...
            (auto_judgement.pass_ratio_same_ratio >= 0.999) && ...
            (auto_judgement.frontier_same_ratio >= 0.999);
    
        if auto_judgement.is_effectively_identical
            auto_judgement.message = [ ...
                "Current Stage06 is effectively identical to Stage05. " + ...
                "This strongly suggests the heading family is only a structural duplication " + ...
                "of nominal trajectories and has not yet introduced true geometric perturbation."];
        else
            auto_judgement.message = [ ...
                "Current Stage06 is NOT fully identical to Stage05. " + ...
                "Please inspect mismatch_feasible and metric_diff tables to determine whether " + ...
                "the differences are due to intended family expansion or implementation differences."];
        end
    
        % ============================================================
        % Save csv files
        % ============================================================
        global_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_global_%s.csv', timestamp));
        metric_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_metric_diff_%s.csv', timestamp));
        mismatch_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_feasible_mismatch_%s.csv', timestamp));
        frontier_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_frontier_%s.csv', timestamp));
        ip_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage06_compare_IP_minNs_%s.csv', timestamp));
    
        writetable(summary_global, global_csv);
        writetable(metric_diff, metric_csv);
        writetable(mismatch_feasible, mismatch_csv);
        writetable(frontier_compare, frontier_csv);
        writetable(IP_compare, ip_csv);
    
        % ============================================================
        % Save cache
        % ============================================================
        out = struct();
        out.summary_global = summary_global;
        out.metric_diff = metric_diff;
        out.mismatch_feasible = mismatch_feasible;
        out.frontier_compare = frontier_compare;
        out.IP_compare = IP_compare;
        out.auto_judgement = auto_judgement;
        out.stage05_file = stage05_file;
        out.stage06_file = stage06_file;
        out.log_file = log_file;
        out.files = struct();
        out.files.global_csv = global_csv;
        out.files.metric_csv = metric_csv;
        out.files.mismatch_csv = mismatch_csv;
        out.files.frontier_csv = frontier_csv;
        out.files.ip_csv = ip_csv;
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage06_compare_with_stage05_%s.mat', timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logging
        % ============================================================
        log_msg(log_fid, 'INFO', 'n_common = %d', nCommon);
        log_msg(log_fid, 'INFO', 'feasible_same_ratio = %.6f', auto_judgement.feasible_same_ratio);
        log_msg(log_fid, 'INFO', 'D_G_min_same_ratio = %.6f', auto_judgement.D_G_min_same_ratio);
        log_msg(log_fid, 'INFO', 'pass_ratio_same_ratio = %.6f', auto_judgement.pass_ratio_same_ratio);
        log_msg(log_fid, 'INFO', 'frontier_same_ratio = %.6f', auto_judgement.frontier_same_ratio);
        log_msg(log_fid, 'INFO', 'Judgement: %s', auto_judgement.message);
        log_msg(log_fid, 'INFO', 'Stage06 compare-with-Stage05 finished.');
    
        fprintf('\n');
        fprintf('========== Stage06 Compare Summary ==========\n');
        fprintf('Stage05 file            : %s\n', stage05_file);
        fprintf('Stage06 file            : %s\n', stage06_file);
        fprintf('n_common                : %d\n', nCommon);
        fprintf('feasible_same_ratio     : %.6f\n', auto_judgement.feasible_same_ratio);
        fprintf('D_G_min_same_ratio      : %.6f\n', auto_judgement.D_G_min_same_ratio);
        fprintf('pass_ratio_same_ratio   : %.6f\n', auto_judgement.pass_ratio_same_ratio);
        fprintf('frontier_same_ratio     : %.6f\n', auto_judgement.frontier_same_ratio);
        fprintf('Judgement               : %s\n', auto_judgement.message);
        fprintf('Global CSV              : %s\n', global_csv);
        fprintf('Metric CSV              : %s\n', metric_csv);
        fprintf('Mismatch CSV            : %s\n', mismatch_csv);
        fprintf('Frontier CSV            : %s\n', frontier_csv);
        fprintf('IP CSV                  : %s\n', ip_csv);
        fprintf('Cache                   : %s\n', cache_file);
        fprintf('============================================\n');
    end
    
    % =========================================================================
    % local helper
    % =========================================================================
    function local_assert_vars(T, vars_needed, tag)
        missing = setdiff(vars_needed, T.Properties.VariableNames);
        assert(isempty(missing), '%s missing variables: %s', tag, strjoin(missing, ', '));
    end