function out = stage08_define_window_scope(cfg)
    %STAGE08_DEFINE_WINDOW_SCOPE
    % Stage08.1:
    %   Freeze experiment scope for window-length sensitivity analysis.
    %
    % Main tasks:
    %   1) load latest Stage07.1 reference Walker
    %   2) load latest Stage07.4 selected examples
    %   3) optionally load Stage07.6.1 paper scope for representative entries
    %   4) freeze Tw grid / representative cases / family casebank / small-grid configs
    %   5) save standardized Stage08 scope cache for later Stage08.2/08.3/08.4
    %
    % Outputs:
    %   out.scope
    %   out.self_check
    %   out.summary_table
    %   out.files
    %
    % Notes:
    %   - This stage does NOT run Tw sensitivity scan yet
    %   - This stage does NOT compute new geometry metrics
    %   - It only fixes scope/spec and saves standardized cache
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage08_prepare_cfg(cfg);
        cfg.project_stage = 'stage08_define_window_scope';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_define_window_scope_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.1 started.');
    
        % ============================================================
        % Load Stage07.1 reference Walker
        % ============================================================
        d71 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_reference_walker_%s_*.mat', cfg.stage07.run_tag)));
        assert(~isempty(d71), ...
            'No Stage07.1 cache found for run_tag=%s.', cfg.stage07.run_tag);
    
        [~, idx71] = max([d71.datenum]);
        stage07_ref_file = fullfile(d71(idx71).folder, d71(idx71).name);
        S71 = load(stage07_ref_file);
    
        assert(isfield(S71, 'out') && isfield(S71.out, 'reference_walker'), ...
            'Invalid Stage07.1 cache: missing out.reference_walker');
        reference_walker_primary = S71.out.reference_walker;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage07.1 reference Walker: %s', stage07_ref_file);
    
        % ============================================================
        % Load Stage07.4 selected examples
        % ============================================================
        d74 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_select_critical_examples_%s_*.mat', cfg.stage07.run_tag)));
        assert(~isempty(d74), ...
            'No Stage07.4 cache found for run_tag=%s.', cfg.stage07.run_tag);
    
        [~, idx74] = max([d74.datenum]);
        stage07_sel_file = fullfile(d74(idx74).folder, d74(idx74).name);
        S74 = load(stage07_sel_file);
    
        assert(isfield(S74, 'out') && isfield(S74.out, 'selection_table') && ...
               isfield(S74.out, 'entry_selection_table'), ...
            'Invalid Stage07.4 cache: missing selection_table / entry_selection_table');
    
        selection_table = S74.out.selection_table;
        entry_selection_table = S74.out.entry_selection_table;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage07.4 selected examples: %s', stage07_sel_file);
        log_msg(log_fid, 'INFO', 'Selection rows = %d | entry rows = %d', ...
            height(selection_table), height(entry_selection_table));
    
        % ============================================================
        % Optional load Stage07.6.1 paper scope
        % ============================================================
        stage07_paper_file = '';
        representative_entries = [];
    
        d761 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_define_paper_plot_scope_%s_*.mat', cfg.stage07.run_tag)));
        if ~isempty(d761) && cfg.stage08.rep.prefer_stage07_paper_scope
            [~, idx761] = max([d761.datenum]);
            stage07_paper_file = fullfile(d761(idx761).folder, d761(idx761).name);
            S761 = load(stage07_paper_file);
    
            if isfield(S761, 'out') && isfield(S761.out, 'paper_scope') && ...
                    isfield(S761.out.paper_scope, 'representative_entries')
                representative_entries = S761.out.paper_scope.representative_entries(:).';
                log_msg(log_fid, 'INFO', ...
                    'Loaded Stage07.6.1 paper scope: %s', stage07_paper_file);
            end
        end
    
        % Fallback: select representative entries from Stage07.4 entry summary
        if isempty(representative_entries)
            representative_entries = local_pick_representative_entries( ...
                entry_selection_table, cfg.stage08.rep.n_representative_entry);
            log_msg(log_fid, 'INFO', ...
                'Representative entries resolved from Stage07.4 fallback rule.');
        end
        representative_entries = unique(representative_entries(:).', 'stable');
    
        % ============================================================
        % Optional load Stage07.3 risk map (only for source bookkeeping)
        % ============================================================
        stage07_risk_file = '';
        risk_table = table();
        d73 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage07_scan_heading_risk_map_%s_*.mat', cfg.stage07.run_tag)));
        if ~isempty(d73)
            [~, idx73] = max([d73.datenum]);
            stage07_risk_file = fullfile(d73(idx73).folder, d73(idx73).name);
            S73 = load(stage07_risk_file);
    
            if isfield(S73, 'out') && isfield(S73.out, 'risk_table')
                risk_table = S73.out.risk_table;
                log_msg(log_fid, 'INFO', 'Loaded Stage07.3 risk map: %s', stage07_risk_file);
                log_msg(log_fid, 'INFO', 'Risk row count = %d', height(risk_table));
            end
        end
    
        % ============================================================
        % Optional load Stage05 best-feasible candidate as secondary reference
        % ============================================================
        secondary_reference_walker = struct([]);
        stage05_file = '';
    
        if cfg.stage08.reference.include_stage05_best_feasible
            d5 = find_stage_cache_files(cfg.paths.cache, 'stage05_nominal_walker_search_*.mat');
            if ~isempty(d5)
                [~, idx5] = max([d5.datenum]);
                stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);
                S5 = load(stage05_file);
    
                if isfield(S5, 'out')
                    secondary_reference_walker = local_extract_stage05_best_reference( ...
                        S5.out, cfg, reference_walker_primary.gamma_req);
                    if ~isempty(secondary_reference_walker)
                        log_msg(log_fid, 'INFO', ...
                            'Loaded Stage05 secondary reference from: %s', stage05_file);
                    end
                end
            end
        end
    
        % ============================================================
        % Build Tw grid
        % ============================================================
        Tw_grid_s = build_window_grid_stage08(cfg);
        nTw = numel(Tw_grid_s);
    
        % ============================================================
        % Build reference Walker bank
        % ============================================================
        reference_walker_bank = local_build_reference_walker_bank_cell( ...
            reference_walker_primary, secondary_reference_walker);

        ref_table = local_reference_walker_bank_cell_to_table(reference_walker_bank);
    
        % ============================================================
        % Build representative case table
        % ============================================================
        representative_case_table = local_build_representative_case_table( ...
            selection_table, representative_entries, cfg);
    
        % ============================================================
        % Build family casebank tables
        % ============================================================
        casebank = struct();
        casebank.all_selection_table = selection_table;
        casebank.entry_selection_table = entry_selection_table;
    
        casebank.nominal_table = selection_table(selection_table.sample_type == "nominal", :);
        casebank.C1_table      = selection_table(selection_table.sample_type == "C1", :);
        casebank.C2_table      = selection_table(selection_table.sample_type == "C2", :);
    
        family_summary_table = table( ...
            ["nominal"; "C1"; "C2"], ...
            [height(casebank.nominal_table); height(casebank.C1_table); height(casebank.C2_table)], ...
            [sum(casebank.nominal_table.entry_id >= 0); sum(casebank.C1_table.entry_id >= 0); sum(casebank.C2_table.entry_id >= 0)], ...
            'VariableNames', {'family_name', 'n_case', 'n_entry_linked'});
    
        % ============================================================
        % Build small-grid search configs around reference Walker
        % ============================================================
        smallgrid_table = local_build_smallgrid_table(reference_walker_primary, cfg);
    
        % ============================================================
        % Build scope/spec struct
        % ============================================================
        scope = struct();
        scope.stage_name = 'Stage08.1';
        scope.stage_desc = 'Freeze experiment scope for window-length sensitivity analysis';
        scope.run_tag = string(run_tag);
    
        scope.source_files = struct();
        scope.source_files.stage07_ref_file = stage07_ref_file;
        scope.source_files.stage07_sel_file = stage07_sel_file;
        scope.source_files.stage07_paper_file = string(stage07_paper_file);
        scope.source_files.stage07_risk_file = string(stage07_risk_file);
        scope.source_files.stage05_file = string(stage05_file);
    
        scope.Tw_grid_name = string(cfg.stage08.active_tw_grid_name);
        scope.Tw_grid_s = Tw_grid_s(:).';
        scope.n_Tw = nTw;
        scope.current_Tw_s = cfg.stage04.Tw_s;
    
        scope.reference_walker_bank = reference_walker_bank;
        scope.reference_walker_table = ref_table;
    
        scope.representative_entries = representative_entries(:).';
        scope.representative_case_table = representative_case_table;
    
        scope.casebank = casebank;
        scope.family_summary_table = family_summary_table;
    
        scope.smallgrid_table = smallgrid_table;
    
        scope.notes = { ...
            'Stage08.1 only freezes scope and standardized cache.'; ...
            'Representative cases are inherited from Stage07 selected examples.'; ...
            'Family casebank currently uses Stage07 nominal/C1/C2 selected rows.'; ...
            'Small-grid configs are constructed around the primary Stage07 reference Walker.'; ...
            'Tw remains a sensitivity variable, not a new main inversion variable.'};
    
        % ============================================================
        % Self-check
        % ============================================================
        self_check = struct();
    
        self_check.has_Tw_grid = ~isempty(Tw_grid_s) && all(isfinite(Tw_grid_s));
        self_check.n_Tw_ok = nTw >= 3;
        self_check.includes_current_Tw = any(abs(Tw_grid_s - cfg.stage04.Tw_s) < 1e-9);
    
        self_check.has_primary_reference = ~isempty(reference_walker_bank);
        self_check.has_reference_table = ~isempty(ref_table) && height(ref_table) >= 1;
    
        self_check.has_rep_entries = ~isempty(representative_entries);
        self_check.has_rep_cases = ~isempty(representative_case_table) && height(representative_case_table) >= 3;
    
        self_check.has_nominal_family = height(casebank.nominal_table) >= 1;
        self_check.has_C1_family = height(casebank.C1_table) >= 1;
        self_check.has_C2_family = height(casebank.C2_table) >= 1;
    
        self_check.has_smallgrid = ~isempty(smallgrid_table) && height(smallgrid_table) >= 1;
    
        self_check.all_ok = all(struct2array(self_check));
    
        % ============================================================
        % Save CSV tables
        % ============================================================
        tw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_Tw_grid_%s_%s.csv', run_tag, timestamp));
        ref_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_reference_walkers_%s_%s.csv', run_tag, timestamp));
        rep_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_representative_cases_%s_%s.csv', run_tag, timestamp));
        family_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_family_summary_%s_%s.csv', run_tag, timestamp));
        smallgrid_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_smallgrid_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_window_scope_summary_%s_%s.csv', run_tag, timestamp));
    
        tw_table = table(Tw_grid_s(:), 'VariableNames', {'Tw_s'});
        writetable(tw_table, tw_csv);
        writetable(ref_table, ref_csv);
        writetable(representative_case_table, rep_csv);
        writetable(family_summary_table, family_csv);
        writetable(smallgrid_table, smallgrid_csv);
    
        summary_table = table( ...
            string(scope.Tw_grid_name), ...
            nTw, ...
            cfg.stage04.Tw_s, ...
            height(ref_table), ...
            numel(representative_entries), ...
            height(representative_case_table), ...
            height(casebank.nominal_table), ...
            height(casebank.C1_table), ...
            height(casebank.C2_table), ...
            height(smallgrid_table), ...
            self_check.all_ok, ...
            'VariableNames', { ...
                'Tw_grid_name', ...
                'n_Tw', ...
                'current_Tw_s', ...
                'n_reference_walker', ...
                'n_representative_entry', ...
                'n_representative_case', ...
                'n_nominal_casebank', ...
                'n_C1_casebank', ...
                'n_C2_casebank', ...
                'n_smallgrid_config', ...
                'self_check_all_ok'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save cache
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.spec = scope;   % alias, keep style compatibility
        out.self_check = self_check;
        out.summary_table = summary_table;
        out.files = struct();
    
        out.files.log_file = log_file;
        out.files.stage07_ref_file = stage07_ref_file;
        out.files.stage07_sel_file = stage07_sel_file;
        out.files.stage07_paper_file = stage07_paper_file;
        out.files.stage07_risk_file = stage07_risk_file;
        out.files.stage05_file = stage05_file;
    
        out.files.tw_csv = tw_csv;
        out.files.ref_csv = ref_csv;
        out.files.rep_csv = rep_csv;
        out.files.family_csv = family_csv;
        out.files.smallgrid_csv = smallgrid_csv;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_define_window_scope_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logs
        % ============================================================
        log_msg(log_fid, 'INFO', 'Tw grid name      = %s', char(scope.Tw_grid_name));
        log_msg(log_fid, 'INFO', 'Tw grid (s)       = %s', mat2str(scope.Tw_grid_s));
        log_msg(log_fid, 'INFO', 'Reference walkers = %d', height(ref_table));
        log_msg(log_fid, 'INFO', 'Representative entries = %s', mat2str(scope.representative_entries));
        log_msg(log_fid, 'INFO', 'Representative cases    = %d', height(representative_case_table));
        log_msg(log_fid, 'INFO', 'Family counts [N/C1/C2] = [%d %d %d]', ...
            height(casebank.nominal_table), height(casebank.C1_table), height(casebank.C2_table));
        log_msg(log_fid, 'INFO', 'Small-grid config count = %d', height(smallgrid_table));
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.1 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.1 Summary ==========\n');
        fprintf('Stage07.1 ref         : %s\n', stage07_ref_file);
        fprintf('Stage07.4 selected    : %s\n', stage07_sel_file);
        if ~isempty(stage07_paper_file)
            fprintf('Stage07.6.1 paper     : %s\n', stage07_paper_file);
        end
        fprintf('Tw grid name          : %s\n', char(scope.Tw_grid_name));
        fprintf('Tw grid (s)           : %s\n', mat2str(scope.Tw_grid_s));
        fprintf('Representative entries: %s\n', mat2str(scope.representative_entries));
        fprintf('Representative cases  : %d\n', height(representative_case_table));
        fprintf('Family counts [N/C1/C2]: [%d %d %d]\n', ...
            height(casebank.nominal_table), height(casebank.C1_table), height(casebank.C2_table));
        fprintf('Small-grid configs    : %d\n', height(smallgrid_table));
        fprintf('Summary CSV           : %s\n', summary_csv);
        fprintf('Cache                 : %s\n', cache_file);
        fprintf('Self-check all ok     : %d\n', self_check.all_ok);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    
    function representative_entries = local_pick_representative_entries(entry_selection_table, nRep)
    
        representative_entries = [];
    
        if isempty(entry_selection_table)
            return;
        end
    
        T = entry_selection_table(~isnan(entry_selection_table.C2_D_G_min), :);
        if isempty(T)
            T = entry_selection_table;
        end
    
        if any(strcmp(T.Properties.VariableNames, 'C2_D_G_min'))
            [~, ord] = sort(T.C2_D_G_min, 'ascend', 'MissingPlacement', 'last');
            T = T(ord, :);
        end
    
        nRep = min(nRep, height(T));
        representative_entries = T.entry_id(1:nRep);
    end
    
    
    function secondary_ref = local_extract_stage05_best_reference(O5, cfg, gamma_req)
    
        secondary_ref = struct([]);
    
        T = local_extract_stage05_candidate_table(O5);
        if isempty(T)
            return;
        end
    
        T = local_prepare_stage05_candidate_table(T, cfg);
    
        % Prefer existing best_feasible if present; otherwise rank by Ns asc, D_G_min desc
        if any(strcmp(T.Properties.VariableNames, 'Ns'))
            Ns = T.Ns;
        else
            Ns = T.P .* T.T;
        end
    
        if any(strcmp(T.Properties.VariableNames, 'D_G_min'))
            DG = T.D_G_min;
        else
            DG = nan(height(T), 1);
        end
    
        rank_mat = [Ns, -DG];
        [~, ord] = sortrows(rank_mat, [1 2]);
        row = T(ord(1), :);
    
        secondary_ref = struct();
        secondary_ref.source_stage = 'stage05_nominal';
        secondary_ref.selection_rule = 'best_feasible_secondary';
        secondary_ref.gamma_req = gamma_req;
    
        secondary_ref.h_km = local_get_row_value(row, 'h_km', cfg.stage05.h_fixed_km);
        secondary_ref.i_deg = local_get_row_value(row, 'i_deg', NaN);
        secondary_ref.P = local_get_row_value(row, 'P', NaN);
        secondary_ref.T = local_get_row_value(row, 'T', NaN);
        secondary_ref.F = local_get_row_value(row, 'F', cfg.stage05.F_fixed);
        secondary_ref.Ns = local_get_row_value(row, 'Ns', secondary_ref.P * secondary_ref.T);
    
        secondary_ref.D_G_min = local_get_row_value(row, 'D_G_min', NaN);
        secondary_ref.pass_ratio = local_get_row_value(row, 'pass_ratio', NaN);
        secondary_ref.margin_to_DG = local_get_row_value(row, 'margin_to_DG', NaN);
    end
    
    
    function T = local_extract_stage05_candidate_table(O5)
    
        T = table();
    
        if isfield(O5, 'summary') && isfield(O5.summary, 'best_feasible') && ...
                istable(O5.summary.best_feasible) && ~isempty(O5.summary.best_feasible)
            T = O5.summary.best_feasible;
            return;
        end
    
        if isfield(O5, 'feasible_grid') && istable(O5.feasible_grid) && ~isempty(O5.feasible_grid)
            T = O5.feasible_grid;
            return;
        end
    
        if isfield(O5, 'grid') && istable(O5.grid) && ~isempty(O5.grid)
            T0 = O5.grid;
            if any(strcmp(T0.Properties.VariableNames, 'feasible_flag'))
                T = T0(T0.feasible_flag == true, :);
                return;
            end
        end
    end
    
    
    function T = local_prepare_stage05_candidate_table(T, cfg)
    
        if ~any(strcmp(T.Properties.VariableNames, 'h_km'))
            T.h_km = repmat(cfg.stage05.h_fixed_km, height(T), 1);
        end
        if ~any(strcmp(T.Properties.VariableNames, 'F'))
            T.F = repmat(cfg.stage05.F_fixed, height(T), 1);
        end
        if ~any(strcmp(T.Properties.VariableNames, 'Ns')) && ...
                all(ismember({'P','T'}, T.Properties.VariableNames))
            T.Ns = T.P .* T.T;
        end
        if ~any(strcmp(T.Properties.VariableNames, 'margin_to_DG')) && ...
                any(strcmp(T.Properties.VariableNames, 'D_G_min'))
            T.margin_to_DG = T.D_G_min - cfg.stage05.require_D_G_min;
        end
    end
    
    
    function value = local_get_row_value(row, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
        if istable(row) && height(row) >= 1 && any(strcmp(row.Properties.VariableNames, field_name))
            value = row.(field_name)(1);
        end
    end
    
    
    function ref_bank = local_build_reference_walker_bank(primary_ref, secondary_ref)
    
        ref_bank = struct([]);
    
        ref_bank(1) = local_normalize_reference_walker(primary_ref, 1);
    
        if ~isempty(secondary_ref)
            is_same = false;
            if isfield(secondary_ref, 'P') && isfield(primary_ref, 'P') && ...
               isfield(secondary_ref, 'T') && isfield(primary_ref, 'T') && ...
               isfield(secondary_ref, 'i_deg') && isfield(primary_ref, 'i_deg')
                is_same = isequaln(secondary_ref.P, primary_ref.P) && ...
                          isequaln(secondary_ref.T, primary_ref.T) && ...
                          isequaln(secondary_ref.i_deg, primary_ref.i_deg) && ...
                          isequaln(secondary_ref.h_km, primary_ref.h_km);
            end
    
            if ~is_same
                ref_bank(end+1) = local_normalize_reference_walker(secondary_ref, 2); %#ok<AGROW>
            end
        end
    end
    
    
    function ref = local_normalize_reference_walker(ref_in, idx)
    
        ref = ref_in;
        ref.ref_id = idx;
    
        if ~isfield(ref, 'source_stage')
            ref.source_stage = sprintf('reference_%d', idx);
        end
        if ~isfield(ref, 'selection_rule')
            ref.selection_rule = 'unknown';
        end
        if ~isfield(ref, 'F') || isempty(ref.F)
            ref.F = 1;
        end
        if ~isfield(ref, 'Ns') || isempty(ref.Ns)
            ref.Ns = ref.P * ref.T;
        end
        if ~isfield(ref, 'D_G_min')
            ref.D_G_min = NaN;
        end
        if ~isfield(ref, 'pass_ratio')
            ref.pass_ratio = NaN;
        end
        if ~isfield(ref, 'margin_to_DG')
            ref.margin_to_DG = NaN;
        end
    end
    
    
    function T = local_reference_walker_bank_to_table(ref_bank)
    
        n = numel(ref_bank);
    
        ref_id = zeros(n,1);
        source_stage = strings(n,1);
        selection_rule = strings(n,1);
        h_km = nan(n,1);
        i_deg = nan(n,1);
        P = nan(n,1);
        Tplane = nan(n,1);
        F = nan(n,1);
        Ns = nan(n,1);
        D_G_min = nan(n,1);
        pass_ratio = nan(n,1);
        gamma_req = nan(n,1);
    
        for k = 1:n
            ref_id(k) = ref_bank(k).ref_id;
            source_stage(k) = string(ref_bank(k).source_stage);
            selection_rule(k) = string(ref_bank(k).selection_rule);
            h_km(k) = ref_bank(k).h_km;
            i_deg(k) = ref_bank(k).i_deg;
            P(k) = ref_bank(k).P;
            Tplane(k) = ref_bank(k).T;
            F(k) = ref_bank(k).F;
            Ns(k) = ref_bank(k).Ns;
            D_G_min(k) = ref_bank(k).D_G_min;
            pass_ratio(k) = ref_bank(k).pass_ratio;
            if isfield(ref_bank(k), 'gamma_req')
                gamma_req(k) = ref_bank(k).gamma_req;
            end
        end
    
        T = table( ...
            ref_id, source_stage, selection_rule, h_km, i_deg, P, Tplane, F, Ns, ...
            D_G_min, pass_ratio, gamma_req, ...
            'VariableNames', { ...
                'ref_id', 'source_stage', 'selection_rule', 'h_km', 'i_deg', ...
                'P', 'T', 'F', 'Ns', 'D_G_min', 'pass_ratio', 'gamma_req'});
    end
    
    
    function rep_table = local_build_representative_case_table(selection_table, representative_entries, cfg)

        rep_table = selection_table([], :);
    
        if isempty(selection_table) || isempty(representative_entries)
            return;
        end
    
        if ~any(strcmp(selection_table.Properties.VariableNames, 'entry_id'))
            return;
        end
    
        sub = selection_table(ismember(selection_table.entry_id, representative_entries), :);
        if isempty(sub)
            return;
        end
    
        rows_keep = false(height(sub), 1);
    
        family_names = string(cfg.stage08.family_order(:).');
        has_sample_type = any(strcmp(sub.Properties.VariableNames, 'sample_type'));
    
        for iFam = 1:numel(family_names)
            fam = family_names(iFam);
    
            if has_sample_type
                idx = find(string(sub.sample_type) == fam);
            else
                idx = [];
            end
    
            if isempty(idx)
                continue;
            end
    
            switch char(fam)
                case 'nominal'
                    max_count = cfg.stage08.rep.max_nominal_count;
                case 'C1'
                    max_count = cfg.stage08.rep.max_C1_count;
                case 'C2'
                    max_count = cfg.stage08.rep.max_C2_count;
                otherwise
                    max_count = numel(idx);
            end
    
            idx = idx(1:min(max_count, numel(idx)));
            rows_keep(idx) = true;
        end
    
        rep_table = sub(rows_keep, :);
    
        if isempty(rep_table)
            return;
        end
    
        if ~any(strcmp(rep_table.Properties.VariableNames, 'family_name'))
            if any(strcmp(rep_table.Properties.VariableNames, 'sample_type'))
                rep_table.family_name = string(rep_table.sample_type);
            else
                rep_table.family_name = repmat("", height(rep_table), 1);
            end
        end
    
        % reorder columns for readability if possible
        desired_cols = {'entry_id','sample_type','family_name','heading_deg', ...
            'heading_offset_deg','D_G_min','lambda_worst','coverage_ratio_2sat', ...
            'mean_los_intersection_angle_deg'};
        keep_cols = desired_cols(ismember(desired_cols, rep_table.Properties.VariableNames));
        other_cols = setdiff(rep_table.Properties.VariableNames, keep_cols, 'stable');
        rep_table = rep_table(:, [keep_cols, other_cols]);
    end
    
    
    function smallgrid_table = local_build_smallgrid_table(reference_walker, cfg)
    
        h_list = reference_walker.h_km + cfg.stage08.smallgrid.h_offsets_km(:);
        i_list = reference_walker.i_deg + cfg.stage08.smallgrid.i_offsets_deg(:);
        P_list = reference_walker.P + cfg.stage08.smallgrid.P_offsets(:);
        T_list = reference_walker.T + cfg.stage08.smallgrid.T_offsets(:);
    
        h_list = unique(h_list(:).');
        i_list = unique(i_list(:).');
        P_list = unique(P_list(:).');
        T_list = unique(T_list(:).');
    
        if cfg.stage08.smallgrid.round_to_integer
            h_list = round(h_list);
            i_list = round(i_list);
            P_list = round(P_list);
            T_list = round(T_list);
        end
    
        i_list = i_list(i_list >= cfg.stage08.smallgrid.min_i_deg & ...
                        i_list <= cfg.stage08.smallgrid.max_i_deg);
        P_list = P_list(P_list >= cfg.stage08.smallgrid.min_P);
        T_list = T_list(T_list >= cfg.stage08.smallgrid.min_T);
    
        if isempty(h_list), h_list = reference_walker.h_km; end
        if isempty(i_list), i_list = reference_walker.i_deg; end
        if isempty(P_list), P_list = reference_walker.P; end
        if isempty(T_list), T_list = reference_walker.T; end
    
        [H, I, Pm, Tm] = ndgrid(h_list, i_list, P_list, T_list);
    
        smallgrid_table = table( ...
            H(:), I(:), Pm(:), Tm(:), ...
            repmat(cfg.stage08.smallgrid.F_fixed, numel(H), 1), ...
            Pm(:).*Tm(:), ...
            'VariableNames', {'h_km','i_deg','P','T','F','Ns'});
    
        smallgrid_table = sortrows(smallgrid_table, {'Ns','i_deg','P','T'}, {'ascend','ascend','ascend','ascend'});
        smallgrid_table = unique(smallgrid_table, 'rows', 'stable');
    
        if isfinite(cfg.stage08.smallgrid.max_config_count) && ...
                height(smallgrid_table) > cfg.stage08.smallgrid.max_config_count
            smallgrid_table = smallgrid_table(1:cfg.stage08.smallgrid.max_config_count, :);
        end
    end

    function ref_bank = local_build_reference_walker_bank_cell(primary_ref, secondary_ref)

        ref_bank = {};
    
        ref1 = local_normalize_reference_walker_loose(primary_ref, 1);
        ref_bank{end+1} = ref1;
    
        if ~isempty(secondary_ref)
            ref2 = local_normalize_reference_walker_loose(secondary_ref, 2);
    
            is_same = false;
            if isfield(ref1, 'P') && isfield(ref2, 'P') && ...
               isfield(ref1, 'T') && isfield(ref2, 'T') && ...
               isfield(ref1, 'i_deg') && isfield(ref2, 'i_deg') && ...
               isfield(ref1, 'h_km') && isfield(ref2, 'h_km')
                is_same = isequaln(ref1.P, ref2.P) && ...
                          isequaln(ref1.T, ref2.T) && ...
                          isequaln(ref1.i_deg, ref2.i_deg) && ...
                          isequaln(ref1.h_km, ref2.h_km);
            end
    
            if ~is_same
                ref_bank{end+1} = ref2;
            end
        end
    end

    function ref = local_normalize_reference_walker_loose(ref_in, idx)

        if isempty(ref_in)
            ref = struct();
            ref.ref_id = idx;
            ref.source_stage = sprintf('reference_%d', idx);
            ref.selection_rule = 'unknown';
            return;
        end
    
        ref = ref_in;
        ref.ref_id = idx;
    
        if ~isfield(ref, 'source_stage') || isempty(ref.source_stage)
            ref.source_stage = sprintf('reference_%d', idx);
        end
        if ~isfield(ref, 'selection_rule') || isempty(ref.selection_rule)
            ref.selection_rule = 'unknown';
        end
        if ~isfield(ref, 'F') || isempty(ref.F) || ~isfinite(ref.F)
            ref.F = 1;
        end
        if (~isfield(ref, 'Ns') || isempty(ref.Ns) || ~isfinite(ref.Ns)) && ...
                isfield(ref, 'P') && isfield(ref, 'T') && ...
                isfinite(ref.P) && isfinite(ref.T)
            ref.Ns = ref.P * ref.T;
        end
    end

    function T = local_reference_walker_bank_cell_to_table(ref_bank)

        n = numel(ref_bank);
    
        ref_id = nan(n,1);
        source_stage = strings(n,1);
        selection_rule = strings(n,1);
        h_km = nan(n,1);
        i_deg = nan(n,1);
        P = nan(n,1);
        Tplane = nan(n,1);
        F = nan(n,1);
        Ns = nan(n,1);
        D_G_min = nan(n,1);
        pass_ratio = nan(n,1);
        gamma_req = nan(n,1);
        margin_to_DG = nan(n,1);
    
        for k = 1:n
            ref = ref_bank{k};
    
            ref_id(k) = local_get_struct_value(ref, 'ref_id', k);
            source_stage(k) = string(local_get_struct_value(ref, 'source_stage', ""));
            selection_rule(k) = string(local_get_struct_value(ref, 'selection_rule', ""));
            h_km(k) = local_get_struct_value(ref, 'h_km', NaN);
            i_deg(k) = local_get_struct_value(ref, 'i_deg', NaN);
            P(k) = local_get_struct_value(ref, 'P', NaN);
            Tplane(k) = local_get_struct_value(ref, 'T', NaN);
            F(k) = local_get_struct_value(ref, 'F', NaN);
            Ns(k) = local_get_struct_value(ref, 'Ns', NaN);
            D_G_min(k) = local_get_struct_value(ref, 'D_G_min', NaN);
            pass_ratio(k) = local_get_struct_value(ref, 'pass_ratio', NaN);
            gamma_req(k) = local_get_struct_value(ref, 'gamma_req', NaN);
            margin_to_DG(k) = local_get_struct_value(ref, 'margin_to_DG', NaN);
        end
    
        T = table( ...
            ref_id, source_stage, selection_rule, h_km, i_deg, P, Tplane, F, Ns, ...
            D_G_min, pass_ratio, gamma_req, margin_to_DG, ...
            'VariableNames', { ...
                'ref_id', 'source_stage', 'selection_rule', 'h_km', 'i_deg', ...
                'P', 'T', 'F', 'Ns', 'D_G_min', 'pass_ratio', ...
                'gamma_req', 'margin_to_DG'});
    end

    function value = local_get_struct_value(S, field_name, default_value)

        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(S) && isfield(S, field_name)
            tmp = S.(field_name);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
