function out = stage08_scan_casebank_stats(cfg)
    %STAGE08_SCAN_CASEBANK_STATS
    % Stage08.3:
    %   Scan the full Stage08 casebank over Tw grid and summarize family-level stability.
    %
    % Main tasks:
    %   1) load latest Stage08.1 scope cache
    %   2) load latest Stage02 nominal trajbank
    %   3) rebuild all casebank cases from selected headings
    %   4) evaluate each case under each reference Walker and each Tw
    %   5) export raw table / family summary / case summary / ranking table / plots / cache
    %
    % Outputs:
    %   out.scope
    %   out.raw_table
    %   out.family_summary_table
    %   out.case_summary_table
    %   out.family_ranking_table
    %   out.figures
    %   out.files
    %
    % Notes:
    %   - This stage scans the full casebank frozen by Stage08.1
    %   - It does NOT perform small-grid search yet
    %   - It reuses Stage02 propagation + Stage07 evaluator
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage08_prepare_cfg(cfg);
        cfg.project_stage = 'stage08_scan_casebank_stats';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_scan_casebank_stats_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.3 started.');
    
        % ============================================================
        % Load latest Stage08.1 scope
        % ============================================================
        d81 = find_stage_cache_files(cfg.paths.cache, ...
            sprintf('stage08_define_window_scope_%s_*.mat', run_tag)));
        assert(~isempty(d81), ...
            'No Stage08.1 scope cache found for run_tag=%s.', run_tag);
    
        [~, idx81] = max([d81.datenum]);
        stage08_scope_file = fullfile(d81(idx81).folder, d81(idx81).name);
        S81 = load(stage08_scope_file);
    
        assert(isfield(S81, 'out') && isfield(S81.out, 'scope'), ...
            'Invalid Stage08.1 cache: missing out.scope');
        scope = S81.out.scope;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage08.1 scope: %s', stage08_scope_file);
    
        % ============================================================
        % Load latest Stage02 nominal bank
        % ============================================================
        d2 = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
        assert(~isempty(d2), 'No Stage02 nominal cache found.');
    
        [~, idx2] = max([d2.datenum]);
        stage02_file = fullfile(d2(idx2).folder, d2(idx2).name);
        S2 = load(stage02_file);
    
        assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
            'Invalid Stage02 cache: missing out.trajbank.nominal');
        nominal_bank = S2.out.trajbank.nominal;
    
        log_msg(log_fid, 'INFO', 'Loaded Stage02 nominal cache: %s', stage02_file);
        log_msg(log_fid, 'INFO', 'Nominal family size = %d', numel(nominal_bank));
    
        % ============================================================
        % Resolve casebank / references / Tw
        % ============================================================
        casebank_table = local_build_casebank_master_table(scope);
        assert(~isempty(casebank_table), 'Stage08.1 casebank is empty.');
    
        Tw_grid_s = scope.Tw_grid_s(:).';
        reference_list = local_get_reference_walker_list(scope);
    
        nCase = height(casebank_table);
        nRef = numel(reference_list);
        nTw = numel(Tw_grid_s);
    
        log_msg(log_fid, 'INFO', ...
            'Casebank cases = %d | reference walkers = %d | Tw count = %d', ...
            nCase, nRef, nTw);
    
        % ============================================================
        % Main scan loop
        % ============================================================
        raw_rows = cell(nCase * nRef * nTw, 1);
        detail_bank = cell(nCase, nRef, nTw);
    
        row_ptr = 0;
    
        for iRef = 1:nRef
            ref_walker = reference_list{iRef};
            ref_label = local_make_reference_label(ref_walker, iRef);
            gamma_req = local_resolve_gamma_req(ref_walker, cfg);
    
            for iCase = 1:nCase
                case_row = casebank_table(iCase, :);
    
                case_item = local_build_casebank_case_item(case_row, nominal_bank, cfg);
                case_id = local_get_case_id_from_item(case_item);
                family_name = local_get_casebank_family(case_row);
    
                log_msg(log_fid, 'INFO', ...
                    'Ref[%d/%d] %-20s | Case[%d/%d] %-24s | family=%s', ...
                    iRef, nRef, ref_label, ...
                    iCase, nCase, case_id, family_name);
    
                for iTw = 1:nTw
                    Tw_s = Tw_grid_s(iTw);
    
                    cfg_eval = cfg;
                    cfg_eval.stage04.Tw_s = Tw_s;
    
                    eval_out = evaluate_critical_case_geometry_stage07( ...
                        case_item, ref_walker, gamma_req, cfg_eval);
    
                    row_ptr = row_ptr + 1;
                    raw_rows{row_ptr} = local_build_stage08_casebank_raw_row( ...
                        case_row, ref_walker, iRef, ref_label, Tw_s, eval_out);
    
                    detail_bank{iCase, iRef, iTw} = eval_out;
    
                    log_msg(log_fid, 'INFO', ...
                        '  -> Tw=%6.1f s | lambda_worst=%.3e | D_G_min=%.3f | t0_worst=%.1f', ...
                        Tw_s, ...
                        local_get_diag_value(eval_out.diag_row, 'lambda_worst', NaN), ...
                        local_get_diag_value(eval_out.diag_row, 'D_G_min', NaN), ...
                        local_get_diag_value(eval_out.diag_row, 't0_worst', NaN));
                end
            end
        end
    
        raw_table = struct2table(vertcat(raw_rows{1:row_ptr}));
    
        % ============================================================
        % Summary tables
        % ============================================================
        family_summary_table = local_build_casebank_family_summary_table(raw_table);
        case_summary_table = local_build_casebank_case_summary_table(raw_table);
        family_ranking_table = local_build_family_ranking_table(family_summary_table);
    
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.lambda_family_vs_Tw = '';
        figures.DG_family_vs_Tw = '';
        figures.passratio_family_vs_Tw = '';
        figures.lambda_heatmap = '';
        figures.DG_heatmap = '';
    
        if ~isfield(cfg.stage08, 'casebank') || ~isfield(cfg.stage08.casebank, 'make_plot') || cfg.stage08.casebank.make_plot
            fig1 = local_plot_family_metric_vs_Tw_casebank(family_summary_table, 'lambda_worst_median', 'lambda_worst (median)');
            figures.lambda_family_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_casebank_family_lambda_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.lambda_family_vs_Tw, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_family_metric_vs_Tw_casebank(family_summary_table, 'D_G_min_median', 'D_G_min (median)');
            figures.DG_family_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_casebank_family_DG_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.DG_family_vs_Tw, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_family_metric_vs_Tw_casebank(family_summary_table, 'pass_geom_ratio', 'pass_geom ratio');
            figures.passratio_family_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_casebank_family_passratio_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.passratio_family_vs_Tw, 'Resolution', 180);
            close(fig3);
    
            fig4 = local_plot_casebank_heatmap(raw_table, 'lambda_worst', scope, 'lambda_worst');
            figures.lambda_heatmap = fullfile(cfg.paths.figs, ...
                sprintf('stage08_casebank_lambda_heatmap_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig4, figures.lambda_heatmap, 'Resolution', 180);
            close(fig4);
    
            fig5 = local_plot_casebank_heatmap(raw_table, 'D_G_min', scope, 'D_G_min');
            figures.DG_heatmap = fullfile(cfg.paths.figs, ...
                sprintf('stage08_casebank_DG_heatmap_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig5, figures.DG_heatmap, 'Resolution', 180);
            close(fig5);
        end
    
        % ============================================================
        % Save CSV
        % ============================================================
        raw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_casebank_raw_%s_%s.csv', run_tag, timestamp));
        family_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_casebank_family_summary_%s_%s.csv', run_tag, timestamp));
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_casebank_case_summary_%s_%s.csv', run_tag, timestamp));
        ranking_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_casebank_family_ranking_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_casebank_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(raw_table, raw_csv);
        writetable(family_summary_table, family_csv);
        writetable(case_summary_table, case_csv);
        writetable(family_ranking_table, ranking_csv);
    
        summary_table = table( ...
            string(stage08_scope_file), ...
            string(stage02_file), ...
            nCase, ...
            nRef, ...
            nTw, ...
            height(raw_table), ...
            height(family_summary_table), ...
            height(case_summary_table), ...
            height(family_ranking_table), ...
            'VariableNames', { ...
                'stage08_scope_file', ...
                'stage02_file', ...
                'n_casebank_case', ...
                'n_reference_walker', ...
                'n_Tw', ...
                'n_raw_row', ...
                'n_family_summary_row', ...
                'n_case_summary_row', ...
                'n_family_ranking_row'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save outputs
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.reference_list = reference_list;
        out.casebank_table = casebank_table;
        out.raw_table = raw_table;
        out.family_summary_table = family_summary_table;
        out.case_summary_table = case_summary_table;
        out.family_ranking_table = family_ranking_table;
        out.detail_bank = detail_bank;
        out.figures = figures;
        out.summary_table = summary_table;
    
        out.files = struct();
        out.files.log_file = log_file;
        out.files.stage08_scope_file = stage08_scope_file;
        out.files.stage02_file = stage02_file;
        out.files.raw_csv = raw_csv;
        out.files.family_csv = family_csv;
        out.files.case_csv = case_csv;
        out.files.ranking_csv = ranking_csv;
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_scan_casebank_stats_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        log_msg(log_fid, 'INFO', 'Raw CSV saved to: %s', raw_csv);
        log_msg(log_fid, 'INFO', 'Family summary CSV saved to: %s', family_csv);
        log_msg(log_fid, 'INFO', 'Case summary CSV saved to: %s', case_csv);
        log_msg(log_fid, 'INFO', 'Family ranking CSV saved to: %s', ranking_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.3 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.3 Summary ==========\n');
        fprintf('Stage08.1 scope      : %s\n', stage08_scope_file);
        fprintf('Stage02 nominal      : %s\n', stage02_file);
        fprintf('Casebank cases       : %d\n', nCase);
        fprintf('Reference walkers    : %d\n', nRef);
        fprintf('Tw count             : %d\n', nTw);
        fprintf('Raw row count        : %d\n', height(raw_table));
        fprintf('Family summary rows  : %d\n', height(family_summary_table));
        fprintf('Case summary rows    : %d\n', height(case_summary_table));
        fprintf('Ranking rows         : %d\n', height(family_ranking_table));
        fprintf('Raw CSV              : %s\n', raw_csv);
        fprintf('Family CSV           : %s\n', family_csv);
        fprintf('Case CSV             : %s\n', case_csv);
        fprintf('Ranking CSV          : %s\n', ranking_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    
    function casebank_table = local_build_casebank_master_table(scope)
    
        casebank_table = table();
    
        assert(isfield(scope, 'casebank') && isstruct(scope.casebank), ...
            'Stage08.1 scope missing casebank.');
    
        tables = {};
        family_names = {};
    
        if isfield(scope.casebank, 'nominal_table') && istable(scope.casebank.nominal_table)
            tables{end+1} = scope.casebank.nominal_table; %#ok<AGROW>
            family_names{end+1} = 'nominal'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C1_table') && istable(scope.casebank.C1_table)
            tables{end+1} = scope.casebank.C1_table; %#ok<AGROW>
            family_names{end+1} = 'C1'; %#ok<AGROW>
        end
        if isfield(scope.casebank, 'C2_table') && istable(scope.casebank.C2_table)
            tables{end+1} = scope.casebank.C2_table; %#ok<AGROW>
            family_names{end+1} = 'C2'; %#ok<AGROW>
        end
    
        assert(~isempty(tables), 'No valid family tables found in scope.casebank.');
    
        for i = 1:numel(tables)
            T = tables{i};
            fam = string(family_names{i});
    
            if ~any(strcmp(T.Properties.VariableNames, 'family_name'))
                T.family_name = repmat(fam, height(T), 1);
            else
                T.family_name = string(T.family_name);
            end
    
            if ~any(strcmp(T.Properties.VariableNames, 'sample_type'))
                T.sample_type = repmat(fam, height(T), 1);
            else
                T.sample_type = string(T.sample_type);
            end
    
            if isempty(casebank_table)
                casebank_table = T;
            else
                casebank_table = [casebank_table; T];
            end
        end
    
        if any(strcmp(casebank_table.Properties.VariableNames, 'entry_id')) && ...
                any(strcmp(casebank_table.Properties.VariableNames, 'heading_deg'))
            casebank_table = sortrows(casebank_table, {'sample_type','entry_id','heading_deg'}, ...
                {'ascend','ascend','ascend'});
        end
    end
    
    
    function reference_list = local_get_reference_walker_list(scope)
    
        reference_list = {};
    
        if isfield(scope, 'reference_walker_bank')
            bank = scope.reference_walker_bank;
    
            if iscell(bank)
                reference_list = bank(:).';
                return;
            elseif isstruct(bank)
                reference_list = arrayfun(@(x) x, bank(:), 'UniformOutput', false);
                return;
            end
        end
    
        if isfield(scope, 'reference_walker') && isstruct(scope.reference_walker)
            reference_list = {scope.reference_walker};
            return;
        end
    
        error('No valid reference walker bank found in Stage08.1 scope.');
    end
    
    
    function label = local_make_reference_label(ref_walker, iRef)
    
        source_stage = string(local_get_struct_value(ref_walker, 'source_stage', sprintf('ref%d', iRef)));
        P = local_get_struct_value(ref_walker, 'P', NaN);
        T = local_get_struct_value(ref_walker, 'T', NaN);
        i_deg = local_get_struct_value(ref_walker, 'i_deg', NaN);
        h_km = local_get_struct_value(ref_walker, 'h_km', NaN);
    
        label = sprintf('R%d_%s_h%.0f_i%.0f_P%dT%d', ...
            iRef, char(source_stage), h_km, i_deg, round(P), round(T));
        label = regexprep(label, '[^\w]', '_');
    end
    
    
    function case_item = local_build_casebank_case_item(case_row, nominal_bank, cfg)
    
        entry_id = local_get_table_value(case_row, 'entry_id', NaN);
        heading_deg = local_get_table_value(case_row, 'heading_deg', NaN);
        sample_type = string(local_get_table_value(case_row, 'sample_type', "unknown"));
        family_name = string(local_get_table_value(case_row, 'family_name', sample_type));
    
        assert(isfinite(entry_id), 'Case row missing entry_id.');
        assert(isfinite(heading_deg), 'Case row missing heading_deg.');
    
        base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id);
        assert(~isempty(base_item), 'Failed to find nominal Stage02 item for entry_id=%g.', entry_id);
    
        base_case = base_item.case;
        nominal_heading_deg = local_extract_numeric(base_case, 'heading_deg', NaN);
        assert(isfinite(nominal_heading_deg), 'Base nominal case missing heading_deg.');
    
        case_new = base_case;
        case_new.heading_deg = heading_deg;
        case_new.heading_offset_deg = wrapTo180(heading_deg - nominal_heading_deg);
        case_new.nominal_heading_deg = nominal_heading_deg;
        case_new.entry_id = entry_id;
        case_new.entry_point_id = entry_id;
        case_new.family = 'stage08_casebank';
        case_new.subfamily = char(sample_type);
        case_new.source_case_id = char(string(base_case.case_id));
        case_new.sample_type = char(sample_type);
        case_new.family_name = char(family_name);
        case_new.case_id = sprintf('S08B_E%02d_%s_H%03d', round(entry_id), char(sample_type), round(heading_deg));
    
        traj_new = propagate_hgv_case_stage02(case_new, cfg);
        val_new = validate_hgv_trajectory_stage02(traj_new, cfg);
        sum_new = summarize_hgv_case_stage02(case_new, traj_new, val_new);
    
        case_item = struct();
        case_item.case = case_new;
        case_item.traj = traj_new;
        case_item.validation = val_new;
        case_item.summary = sum_new;
    end
    
    
    function base_item = local_find_nominal_item_by_entry_id(nominal_bank, entry_id)
    
        base_item = [];
    
        for k = 1:numel(nominal_bank)
            item_k = nominal_bank(k);
    
            eid = local_extract_numeric(item_k.case, 'entry_id', NaN);
            if ~isfinite(eid)
                eid = local_parse_entry_id_from_case_id(item_k.case);
            end
    
            if isequaln(eid, entry_id)
                base_item = item_k;
                return;
            end
        end
    end
    
    
    function row = local_build_stage08_casebank_raw_row(case_row, ref_walker, iRef, ref_label, Tw_s, eval_out)
    
        diag_row = eval_out.diag_row;
    
        row = struct();
    
        row.ref_id = iRef;
        row.ref_label = string(ref_label);
        row.ref_source_stage = string(local_get_struct_value(ref_walker, 'source_stage', ""));
        row.ref_selection_rule = string(local_get_struct_value(ref_walker, 'selection_rule', ""));
        row.ref_h_km = local_get_struct_value(ref_walker, 'h_km', NaN);
        row.ref_i_deg = local_get_struct_value(ref_walker, 'i_deg', NaN);
        row.ref_P = local_get_struct_value(ref_walker, 'P', NaN);
        row.ref_T = local_get_struct_value(ref_walker, 'T', NaN);
        row.ref_F = local_get_struct_value(ref_walker, 'F', NaN);
        row.ref_Ns = local_get_struct_value(ref_walker, 'Ns', NaN);
        row.ref_gamma_req = local_get_struct_value(ref_walker, 'gamma_req', NaN);
    
        row.Tw_s = Tw_s;
    
        row.entry_id = local_get_table_value(case_row, 'entry_id', local_get_diag_value(diag_row, 'entry_id', NaN));
        row.sample_type = string(local_get_table_value(case_row, 'sample_type', "unknown"));
        row.family_name = string(local_get_table_value(case_row, 'family_name', row.sample_type));
        row.heading_deg = local_get_table_value(case_row, 'heading_deg', local_get_diag_value(diag_row, 'heading_deg', NaN));
        row.heading_offset_deg = local_get_table_value(case_row, 'heading_offset_deg', local_get_diag_value(diag_row, 'heading_offset_deg', NaN));
    
        row.case_id = string(local_get_diag_value(diag_row, 'case_id', ""));
        row.source_case_id = string(local_get_diag_value(diag_row, 'source_case_id', ""));
        row.critical_mode = string(local_get_diag_value(diag_row, 'critical_mode', ""));
        row.critical_branch = string(local_get_diag_value(diag_row, 'critical_branch', ""));
    
        row.coverage_ratio_2sat = local_get_diag_value(diag_row, 'coverage_ratio_2sat', NaN);
        row.mean_los_intersection_angle_deg = local_get_diag_value(diag_row, 'mean_los_intersection_angle_deg', NaN);
        row.min_los_intersection_angle_deg = local_get_diag_value(diag_row, 'min_los_intersection_angle_deg', NaN);
    
        row.lambda_worst = local_get_diag_value(diag_row, 'lambda_worst', NaN);
        row.D_G_min = local_get_diag_value(diag_row, 'D_G_min', NaN);
        row.t0_worst = local_get_diag_value(diag_row, 't0_worst', NaN);
        row.n_visible_windows = local_get_diag_value(diag_row, 'n_visible_windows', NaN);
    
        row.pass_geom = isfinite(row.D_G_min) && row.D_G_min >= 1;
        row.is_high_coverage = isfinite(row.coverage_ratio_2sat) && row.coverage_ratio_2sat >= 0.5;
        row.is_small_angle = isfinite(row.mean_los_intersection_angle_deg) && row.mean_los_intersection_angle_deg <= 10;
    end
    
    
    function T = local_build_casebank_family_summary_table(raw_table)
    
        group_keys = unique(raw_table(:, {'ref_id','ref_label','sample_type','Tw_s'}), 'rows', 'stable');
        nG = height(group_keys);
        rows = cell(nG, 1);
    
        for i = 1:nG
            key = group_keys(i, :);
    
            mask = raw_table.ref_id == key.ref_id & ...
                   raw_table.sample_type == key.sample_type & ...
                   raw_table.Tw_s == key.Tw_s;
    
            sub = raw_table(mask, :);
    
            r = struct();
            r.ref_id = key.ref_id;
            r.ref_label = key.ref_label;
            r.sample_type = key.sample_type;
            r.Tw_s = key.Tw_s;
    
            r.N = height(sub);
    
            r.lambda_worst_mean = mean(sub.lambda_worst, 'omitnan');
            r.lambda_worst_median = median(sub.lambda_worst, 'omitnan');
            r.lambda_worst_min = min(sub.lambda_worst, [], 'omitnan');
            r.lambda_worst_max = max(sub.lambda_worst, [], 'omitnan');
    
            r.D_G_min_mean = mean(sub.D_G_min, 'omitnan');
            r.D_G_min_median = median(sub.D_G_min, 'omitnan');
            r.D_G_min_min = min(sub.D_G_min, [], 'omitnan');
            r.D_G_min_max = max(sub.D_G_min, [], 'omitnan');
    
            r.t0_worst_mean = mean(sub.t0_worst, 'omitnan');
            r.t0_worst_median = median(sub.t0_worst, 'omitnan');
            r.coverage_ratio_2sat_mean = mean(sub.coverage_ratio_2sat, 'omitnan');
            r.mean_los_intersection_angle_deg_mean = mean(sub.mean_los_intersection_angle_deg, 'omitnan');
    
            r.pass_geom_ratio = mean(double(sub.pass_geom), 'omitnan');
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, {'ref_id','Tw_s','sample_type'}, {'ascend','ascend','ascend'});
    end
    
    
    function T = local_build_casebank_case_summary_table(raw_table)
    
        group_keys = unique(raw_table(:, {'ref_id','ref_label','case_id','sample_type','entry_id','Tw_s'}), ...
            'rows', 'stable');
        nG = height(group_keys);
        rows = cell(nG, 1);
    
        for i = 1:nG
            key = group_keys(i, :);
    
            mask = raw_table.ref_id == key.ref_id & ...
                   raw_table.Tw_s == key.Tw_s & ...
                   raw_table.entry_id == key.entry_id & ...
                   raw_table.case_id == key.case_id;
    
            sub = raw_table(mask, :);
    
            r = struct();
            r.ref_id = key.ref_id;
            r.ref_label = key.ref_label;
            r.case_id = key.case_id;
            r.sample_type = key.sample_type;
            r.entry_id = key.entry_id;
            r.Tw_s = key.Tw_s;
    
            r.N = height(sub);
    
            r.lambda_worst_mean = mean(sub.lambda_worst, 'omitnan');
            r.lambda_worst_median = median(sub.lambda_worst, 'omitnan');
            r.D_G_min_mean = mean(sub.D_G_min, 'omitnan');
            r.D_G_min_median = median(sub.D_G_min, 'omitnan');
            r.t0_worst_mean = mean(sub.t0_worst, 'omitnan');
            r.coverage_ratio_2sat_mean = mean(sub.coverage_ratio_2sat, 'omitnan');
            r.mean_los_intersection_angle_deg_mean = mean(sub.mean_los_intersection_angle_deg, 'omitnan');
            r.pass_geom_ratio = mean(double(sub.pass_geom), 'omitnan');
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, {'ref_id','sample_type','entry_id','Tw_s'}, {'ascend','ascend','ascend','ascend'});
    end
    
    
    function T = local_build_family_ranking_table(family_summary_table)
    
        ref_ids = unique(family_summary_table.ref_id);
        Tw_vals = unique(family_summary_table.Tw_s);
        rows = {};
    
        ptr = 0;
        for iRef = 1:numel(ref_ids)
            for iTw = 1:numel(Tw_vals)
                sub = family_summary_table( ...
                    family_summary_table.ref_id == ref_ids(iRef) & ...
                    family_summary_table.Tw_s == Tw_vals(iTw), :);
    
                if isempty(sub)
                    continue;
                end
    
                [~, ord_lambda] = sort(sub.lambda_worst_median, 'descend', 'MissingPlacement', 'last');
                [~, ord_DG] = sort(sub.D_G_min_median, 'descend', 'MissingPlacement', 'last');
                [~, ord_pass] = sort(sub.pass_geom_ratio, 'descend', 'MissingPlacement', 'last');
    
                ptr = ptr + 1;
                r = struct();
                r.ref_id = ref_ids(iRef);
                r.ref_label = sub.ref_label(1);
                r.Tw_s = Tw_vals(iTw);
    
                r.rank_lambda_1 = local_rank_name(sub.sample_type, ord_lambda, 1);
                r.rank_lambda_2 = local_rank_name(sub.sample_type, ord_lambda, 2);
                r.rank_lambda_3 = local_rank_name(sub.sample_type, ord_lambda, 3);
    
                r.rank_DG_1 = local_rank_name(sub.sample_type, ord_DG, 1);
                r.rank_DG_2 = local_rank_name(sub.sample_type, ord_DG, 2);
                r.rank_DG_3 = local_rank_name(sub.sample_type, ord_DG, 3);
    
                r.rank_pass_1 = local_rank_name(sub.sample_type, ord_pass, 1);
                r.rank_pass_2 = local_rank_name(sub.sample_type, ord_pass, 2);
                r.rank_pass_3 = local_rank_name(sub.sample_type, ord_pass, 3);
    
                rows{ptr,1} = r; %#ok<AGROW>
            end
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, {'ref_id','Tw_s'}, {'ascend','ascend'});
    end
    
    
    function name = local_rank_name(names, ord, k)
    
        name = "";
        if numel(ord) >= k
            name = string(names(ord(k)));
        end
    end
    
    
    function fig = local_plot_family_metric_vs_Tw_casebank(family_summary_table, metric_name, y_label_str)
    
        fig = figure('Color', 'w', 'Position', [120 120 1100 600]);
    
        ref_ids = unique(family_summary_table.ref_id);
        nRef = numel(ref_ids);
    
        tiledlayout(nRef, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
        sample_order = ["nominal","C1","C2"];
    
        for iRef = 1:nRef
            nexttile;
            hold on; grid on; box on;
    
            sub_ref = family_summary_table(family_summary_table.ref_id == ref_ids(iRef), :);
    
            for iS = 1:numel(sample_order)
                stype = sample_order(iS);
                sub = sub_ref(sub_ref.sample_type == stype, :);
                if isempty(sub), continue; end
    
                sub = sortrows(sub, 'Tw_s', 'ascend');
                plot(sub.Tw_s, sub.(metric_name), '-o', 'LineWidth', 1.5, 'MarkerSize', 5, ...
                    'DisplayName', char(stype));
            end
    
            title(sprintf('Casebank family summary: %s', char(sub_ref.ref_label(1))), 'Interpreter', 'none');
            xlabel('Tw (s)');
            ylabel(y_label_str);
            legend('Location', 'best');
        end
    end
    
    
    function fig = local_plot_casebank_heatmap(raw_table, metric_name, scope, cbar_label)
    
        fig = figure('Color', 'w', 'Position', [120 120 1200 700]);
    
        ref_ids = unique(raw_table.ref_id);
        nRef = numel(ref_ids);
    
        tiledlayout(nRef, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
        for iRef = 1:nRef
            nexttile;
            sub_ref = raw_table(raw_table.ref_id == ref_ids(iRef), :);
    
            case_keys = unique(sub_ref(:, {'sample_type','entry_id','heading_deg','case_id'}), 'rows', 'stable');
            case_keys = sortrows(case_keys, {'sample_type','entry_id','heading_deg'}, {'ascend','ascend','ascend'});
            Tw_vals = sort(unique(sub_ref.Tw_s), 'ascend');
    
            M = nan(height(case_keys), numel(Tw_vals));
    
            for iCase = 1:height(case_keys)
                cid = case_keys.case_id(iCase);
                for iTw = 1:numel(Tw_vals)
                    idx = sub_ref.case_id == cid & sub_ref.Tw_s == Tw_vals(iTw);
                    vals = sub_ref.(metric_name)(idx);
                    if ~isempty(vals)
                        M(iCase, iTw) = vals(1);
                    end
                end
            end
    
            imagesc(Tw_vals, 1:height(case_keys), M);
            set(gca, 'YDir', 'normal');
            colorbar;
            ylabel('case index');
            xlabel('Tw (s)');
            title(sprintf('Heatmap: %s | %s', char(sub_ref.ref_label(1)), cbar_label), 'Interpreter', 'none');
    
            if height(case_keys) <= 20
                yticklabels = strings(height(case_keys), 1);
                for iCase = 1:height(case_keys)
                    yticklabels(iCase) = sprintf('E%d-%s-H%.0f', ...
                        case_keys.entry_id(iCase), char(case_keys.sample_type(iCase)), case_keys.heading_deg(iCase));
                end
                set(gca, 'YTick', 1:height(case_keys), 'YTickLabel', yticklabels);
            end
    
            if isfield(scope, 'Tw_grid_s') && ~isempty(scope.Tw_grid_s)
                xlim([min(scope.Tw_grid_s) max(scope.Tw_grid_s)]);
            end
        end
    end
    
    
    function family_name = local_get_casebank_family(case_row)
    
        if any(strcmp(case_row.Properties.VariableNames, 'family_name'))
            family_name = char(string(case_row.family_name(1)));
            return;
        end
        if any(strcmp(case_row.Properties.VariableNames, 'sample_type'))
            family_name = char(string(case_row.sample_type(1)));
            return;
        end
        family_name = 'unknown';
    end
    
    
    function case_id = local_get_case_id_from_item(case_item)
    
        case_id = "";
        if isstruct(case_item) && isfield(case_item, 'case') && isfield(case_item.case, 'case_id')
            case_id = string(case_item.case.case_id);
        end
    end
    
    
    function gamma_req = local_resolve_gamma_req(ref_walker, cfg)
    
        gamma_req = local_get_struct_value(ref_walker, 'gamma_req', NaN);
        if isfinite(gamma_req)
            return;
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage04') && isstruct(cfg.stage04) && ...
                isfield(cfg.stage04, 'gamma_req') && ~isempty(cfg.stage04.gamma_req)
            gamma_req = cfg.stage04.gamma_req;
            if isfinite(gamma_req)
                return;
            end
        end
    
        if isstruct(cfg) && isfield(cfg, 'stage05') && isstruct(cfg.stage05) && ...
                isfield(cfg.stage05, 'require_D_G_min') && ~isempty(cfg.stage05.require_D_G_min)
            gamma_req = cfg.stage05.require_D_G_min;
            if isfinite(gamma_req)
                return;
            end
        end
    
        gamma_req = 1.0;
    end
    
    
    function value = local_get_table_value(Trow, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if istable(Trow) && height(Trow) >= 1 && any(strcmp(Trow.Properties.VariableNames, field_name))
            tmp = Trow.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
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
    
    
    function value = local_get_diag_value(diag_row, field_name, default_value)
    
        if nargin < 3
            default_value = NaN;
        end
    
        value = default_value;
    
        if isstruct(diag_row)
            value = local_get_struct_value(diag_row, field_name, default_value);
            return;
        end
    
        if istable(diag_row) && height(diag_row) >= 1 && any(strcmp(diag_row.Properties.VariableNames, field_name))
            tmp = diag_row.(field_name)(1);
            if ~isempty(tmp)
                value = tmp;
            end
        end
    end
    
    
    function x = local_extract_numeric(S, field_name, fallback)
        x = fallback;
        if isstruct(S) && isfield(S, field_name)
            val = S.(field_name);
            if isnumeric(val) && ~isempty(val) && isfinite(val(1))
                x = double(val(1));
            end
        end
    end
    
    
    function entry_id = local_parse_entry_id_from_case_id(base_case)
        entry_id = NaN;
        if isstruct(base_case) && isfield(base_case, 'case_id') && ~isempty(base_case.case_id)
            cid = char(string(base_case.case_id));
            tok = regexp(cid, '^N(\d+)$', 'tokens', 'once');
            if ~isempty(tok)
                entry_id = str2double(tok{1});
            end
        end
    end
