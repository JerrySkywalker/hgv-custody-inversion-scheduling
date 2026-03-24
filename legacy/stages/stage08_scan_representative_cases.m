function out = stage08_scan_representative_cases(cfg)
    %STAGE08_SCAN_REPRESENTATIVE_CASES
    % Stage08.2:
    %   Scan representative cases over Tw grid under one or more reference Walkers.
    %
    % Main tasks:
    %   1) load latest Stage08.1 scope cache
    %   2) load latest Stage02 nominal trajbank
    %   3) rebuild representative cases from selected headings
    %   4) evaluate each representative case under each reference Walker and each Tw
    %   5) export raw table / summary tables / representative plots / cache
    %
    % Outputs:
    %   out.scope
    %   out.raw_table
    %   out.family_summary_table
    %   out.case_summary_table
    %   out.figures
    %   out.files
    %
    % Notes:
    %   - This stage only scans representative cases from Stage08.1
    %   - It does NOT scan the full family casebank yet
    %   - It reuses Stage02 propagation + Stage03 visibility + Stage04 worst-window scan
    
        startup();
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
        cfg = stage08_prepare_cfg(cfg);
        cfg.project_stage = 'stage08_scan_representative_cases';
        cfg = configure_stage_output_paths(cfg);
    
        seed_rng(cfg.random.seed);
        ensure_dir(cfg.paths.logs);
        ensure_dir(cfg.paths.cache);
        ensure_dir(cfg.paths.tables);
        ensure_dir(cfg.paths.figs);
    
        run_tag = char(cfg.stage08.run_tag);
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
        log_file = fullfile(cfg.paths.logs, ...
            sprintf('stage08_scan_representative_cases_%s_%s.log', run_tag, timestamp));
        log_fid = fopen(log_file, 'w');
        if log_fid < 0
            error('Failed to open log file: %s', log_file);
        end
        cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>
    
        log_msg(log_fid, 'INFO', 'Stage08.2 started.');
    
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
        % Resolve representative case table + reference walkers + Tw grid
        % ============================================================
        assert(isfield(scope, 'representative_case_table') && istable(scope.representative_case_table), ...
            'Stage08.1 scope missing representative_case_table.');
        rep_table = scope.representative_case_table;
    
        assert(~isempty(rep_table), 'Stage08.1 representative_case_table is empty.');
        assert(isfield(scope, 'Tw_grid_s') && ~isempty(scope.Tw_grid_s), ...
            'Stage08.1 scope missing Tw_grid_s.');
    
        Tw_grid_s = scope.Tw_grid_s(:).';
        reference_list = local_get_reference_walker_list(scope);
    
        nRep = height(rep_table);
        nRef = numel(reference_list);
        nTw = numel(Tw_grid_s);
    
        log_msg(log_fid, 'INFO', ...
            'Representative cases = %d | reference walkers = %d | Tw count = %d', ...
            nRep, nRef, nTw);
    
        % ============================================================
        % Main scan loop
        % ============================================================
        raw_rows = cell(nRep * nRef * nTw, 1);
        detail_bank = cell(nRep, nRef, nTw);
    
        row_ptr = 0;
    
        for iRef = 1:nRef
            ref_walker = reference_list{iRef};
            ref_label = local_make_reference_label(ref_walker, iRef);
    
            gamma_req = local_resolve_gamma_req(ref_walker, cfg);
    
            for iRep = 1:nRep
                rep_row = rep_table(iRep, :);
    
                case_item = local_build_representative_case_item(rep_row, nominal_bank, cfg);
    
                case_id = local_get_case_id_from_item(case_item);
                family_name = local_get_rep_family(rep_row);
    
                log_msg(log_fid, 'INFO', ...
                    'Ref[%d/%d] %-20s | Rep[%d/%d] %-24s | family=%s', ...
                    iRef, nRef, ref_label, ...
                    iRep, nRep, case_id, family_name);
    
                for iTw = 1:nTw
                    Tw_s = Tw_grid_s(iTw);
    
                    cfg_eval = cfg;
                    cfg_eval.stage04.Tw_s = Tw_s;
    
                    eval_out = evaluate_critical_case_geometry_stage07( ...
                        case_item, ref_walker, gamma_req, cfg_eval);
    
                    row_ptr = row_ptr + 1;
                    raw_rows{row_ptr} = local_build_stage08_raw_row( ...
                        rep_row, ref_walker, iRef, ref_label, Tw_s, eval_out);
    
                    detail_bank{iRep, iRef, iTw} = eval_out;
    
                    log_msg(log_fid, 'INFO', ...
                        '  -> Tw=%6.1f s | lambda_worst=%.3e | D_G_min=%.3f | t0_worst=%.1f', ...
                        Tw_s, ...
                        local_get_struct_value(eval_out.diag_row, 'lambda_worst', NaN), ...
                        local_get_struct_value(eval_out.diag_row, 'D_G_min', NaN), ...
                        local_get_struct_value(eval_out.diag_row, 't0_worst', NaN));
                end
            end
        end
    
        raw_table = struct2table(vertcat(raw_rows{1:row_ptr}));
    
        % ============================================================
        % Summary tables
        % ============================================================
        family_summary_table = local_build_family_summary_table(raw_table);
        case_summary_table = local_build_case_summary_table(raw_table);
    
        % ============================================================
        % Plots
        % ============================================================
        figures = struct();
        figures.lambda_case_vs_Tw = '';
        figures.DG_case_vs_Tw = '';
        figures.t0_case_vs_Tw = '';
        figures.lambda_family_vs_Tw = '';
        figures.DG_family_vs_Tw = '';
    
        if ~isfield(cfg.stage08, 'scan') || ~isfield(cfg.stage08.scan, 'make_plot') || cfg.stage08.scan.make_plot
            fig1 = local_plot_case_metric_vs_Tw(raw_table, 'lambda_worst', 'lambda_worst', scope);
            figures.lambda_case_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_rep_lambda_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig1, figures.lambda_case_vs_Tw, 'Resolution', 180);
            close(fig1);
    
            fig2 = local_plot_case_metric_vs_Tw(raw_table, 'D_G_min', 'D_G_min', scope);
            figures.DG_case_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_rep_DG_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig2, figures.DG_case_vs_Tw, 'Resolution', 180);
            close(fig2);
    
            fig3 = local_plot_case_metric_vs_Tw(raw_table, 't0_worst', 't0_worst (s)', scope);
            figures.t0_case_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_rep_t0_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig3, figures.t0_case_vs_Tw, 'Resolution', 180);
            close(fig3);
    
            fig4 = local_plot_family_metric_vs_Tw(family_summary_table, 'lambda_worst_median', 'lambda_worst (median)');
            figures.lambda_family_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_family_lambda_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig4, figures.lambda_family_vs_Tw, 'Resolution', 180);
            close(fig4);
    
            fig5 = local_plot_family_metric_vs_Tw(family_summary_table, 'D_G_min_median', 'D_G_min (median)');
            figures.DG_family_vs_Tw = fullfile(cfg.paths.figs, ...
                sprintf('stage08_family_DG_vs_Tw_%s_%s.png', run_tag, timestamp));
            exportgraphics(fig5, figures.DG_family_vs_Tw, 'Resolution', 180);
            close(fig5);
        end
    
        % ============================================================
        % Save CSV
        % ============================================================
        raw_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_representative_raw_%s_%s.csv', run_tag, timestamp));
        family_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_representative_family_summary_%s_%s.csv', run_tag, timestamp));
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_representative_case_summary_%s_%s.csv', run_tag, timestamp));
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage08_representative_summary_%s_%s.csv', run_tag, timestamp));
    
        writetable(raw_table, raw_csv);
        writetable(family_summary_table, family_csv);
        writetable(case_summary_table, case_csv);
    
        summary_table = table( ...
            string(stage08_scope_file), ...
            string(stage02_file), ...
            height(rep_table), ...
            nRef, ...
            nTw, ...
            height(raw_table), ...
            height(family_summary_table), ...
            height(case_summary_table), ...
            'VariableNames', { ...
                'stage08_scope_file', ...
                'stage02_file', ...
                'n_representative_case', ...
                'n_reference_walker', ...
                'n_Tw', ...
                'n_raw_row', ...
                'n_family_summary_row', ...
                'n_case_summary_row'});
    
        writetable(summary_table, summary_csv);
    
        % ============================================================
        % Save outputs
        % ============================================================
        out = struct();
        out.cfg = cfg;
        out.scope = scope;
        out.reference_list = reference_list;
        out.raw_table = raw_table;
        out.family_summary_table = family_summary_table;
        out.case_summary_table = case_summary_table;
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
        out.files.summary_csv = summary_csv;
    
        out.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage08_scan_representative_cases_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    
        % ============================================================
        % Logs
        % ============================================================
        log_msg(log_fid, 'INFO', 'Raw CSV saved to: %s', raw_csv);
        log_msg(log_fid, 'INFO', 'Family summary CSV saved to: %s', family_csv);
        log_msg(log_fid, 'INFO', 'Case summary CSV saved to: %s', case_csv);
        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Cache saved to: %s', cache_file);
        log_msg(log_fid, 'INFO', 'Stage08.2 finished.');
    
        fprintf('\n');
        fprintf('========== Stage08.2 Summary ==========\n');
        fprintf('Stage08.1 scope      : %s\n', stage08_scope_file);
        fprintf('Stage02 nominal      : %s\n', stage02_file);
        fprintf('Representative cases : %d\n', height(rep_table));
        fprintf('Reference walkers    : %d\n', nRef);
        fprintf('Tw count             : %d\n', nTw);
        fprintf('Raw row count        : %d\n', height(raw_table));
        fprintf('Family summary rows  : %d\n', height(family_summary_table));
        fprintf('Case summary rows    : %d\n', height(case_summary_table));
        fprintf('Raw CSV              : %s\n', raw_csv);
        fprintf('Family CSV           : %s\n', family_csv);
        fprintf('Case CSV             : %s\n', case_csv);
        fprintf('Cache                : %s\n', cache_file);
        fprintf('=======================================\n');
    end
    
    
    % ============================================================
    % local helpers
    % ============================================================
    
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
    
    
    function case_item = local_build_representative_case_item(rep_row, nominal_bank, cfg)
    
        entry_id = local_get_table_value(rep_row, 'entry_id', NaN);
        heading_deg = local_get_table_value(rep_row, 'heading_deg', NaN);
        sample_type = string(local_get_table_value(rep_row, 'sample_type', "unknown"));
    
        assert(isfinite(entry_id), 'Representative row missing entry_id.');
        assert(isfinite(heading_deg), 'Representative row missing heading_deg.');
    
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
        case_new.family = 'stage08_representative';
        case_new.subfamily = char(sample_type);
        case_new.source_case_id = char(string(base_case.case_id));
        case_new.sample_type = char(sample_type);
        case_new.case_id = sprintf('S08_E%02d_%s_H%03d', round(entry_id), char(sample_type), round(heading_deg));
    
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
    
    
    function row = local_build_stage08_raw_row(rep_row, ref_walker, iRef, ref_label, Tw_s, eval_out)
    
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
    
        row.entry_id = local_get_table_value(rep_row, 'entry_id', local_get_struct_value(diag_row, 'entry_id', NaN));
        row.sample_type = string(local_get_table_value(rep_row, 'sample_type', "unknown"));
        row.family_name = string(local_get_table_value(rep_row, 'family_name', row.sample_type));
        row.heading_deg = local_get_table_value(rep_row, 'heading_deg', local_get_struct_value(diag_row, 'heading_deg', NaN));
        row.heading_offset_deg = local_get_table_value(rep_row, 'heading_offset_deg', local_get_struct_value(diag_row, 'heading_offset_deg', NaN));
    
        row.case_id = string(local_get_struct_value(diag_row, 'case_id', ""));
        row.source_case_id = string(local_get_struct_value(diag_row, 'source_case_id', ""));
        row.critical_mode = string(local_get_struct_value(diag_row, 'critical_mode', ""));
        row.critical_branch = string(local_get_struct_value(diag_row, 'critical_branch', ""));
    
        row.coverage_ratio_2sat = local_get_struct_value(diag_row, 'coverage_ratio_2sat', NaN);
        row.mean_los_intersection_angle_deg = local_get_struct_value(diag_row, 'mean_los_intersection_angle_deg', NaN);
        row.min_los_intersection_angle_deg = local_get_struct_value(diag_row, 'min_los_intersection_angle_deg', NaN);
    
        row.lambda_worst = local_get_struct_value(diag_row, 'lambda_worst', NaN);
        row.D_G_min = local_get_struct_value(diag_row, 'D_G_min', NaN);
        row.t0_worst = local_get_struct_value(diag_row, 't0_worst', NaN);
        row.n_visible_windows = local_get_struct_value(diag_row, 'n_visible_windows', NaN);
    
        row.pass_geom = isfinite(row.D_G_min) && row.D_G_min >= 1;
        row.is_high_coverage = isfinite(row.coverage_ratio_2sat) && row.coverage_ratio_2sat >= 0.5;
        row.is_small_angle = isfinite(row.mean_los_intersection_angle_deg) && row.mean_los_intersection_angle_deg <= 10;
    end
    
    
    function T = local_build_family_summary_table(raw_table)
    
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
    
    
    function T = local_build_case_summary_table(raw_table)
    
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
    
            rows{i} = r;
        end
    
        T = struct2table(vertcat(rows{:}));
        T = sortrows(T, {'ref_id','entry_id','Tw_s','sample_type'}, {'ascend','ascend','ascend','ascend'});
    end
    
    
    function fig = local_plot_case_metric_vs_Tw(raw_table, metric_name, y_label_str, scope)
    
        fig = figure('Color', 'w', 'Position', [100 100 1200 700]);
    
        ref_ids = unique(raw_table.ref_id);
        nRef = numel(ref_ids);
    
        tiledlayout(nRef, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
        for iRef = 1:nRef
            nexttile;
            hold on; grid on; box on;
    
            sub_ref = raw_table(raw_table.ref_id == ref_ids(iRef), :);
            case_keys = unique(sub_ref(:, {'case_id','sample_type','entry_id'}), 'rows', 'stable');
    
            legend_cell = cell(height(case_keys), 1);
    
            for k = 1:height(case_keys)
                cid = case_keys.case_id(k);
                stype = case_keys.sample_type(k);
                eid = case_keys.entry_id(k);
    
                sub = sub_ref(sub_ref.case_id == cid, :);
                sub = sortrows(sub, 'Tw_s', 'ascend');
    
                plot(sub.Tw_s, sub.(metric_name), '-o', 'LineWidth', 1.2, 'MarkerSize', 5);
    
                legend_cell{k} = sprintf('E%d-%s', eid, char(stype));
            end
    
            title(sprintf('Representative cases: %s', char(sub_ref.ref_label(1))), 'Interpreter', 'none');
            xlabel('Tw (s)');
            ylabel(y_label_str);
            legend(legend_cell, 'Location', 'bestoutside');
    
            if isfield(scope, 'Tw_grid_s') && ~isempty(scope.Tw_grid_s)
                xlim([min(scope.Tw_grid_s) max(scope.Tw_grid_s)]);
            end
        end
    end
    
    
    function fig = local_plot_family_metric_vs_Tw(family_summary_table, metric_name, y_label_str)
    
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
    
            title(sprintf('Family summary: %s', char(sub_ref.ref_label(1))), 'Interpreter', 'none');
            xlabel('Tw (s)');
            ylabel(y_label_str);
            legend('Location', 'best');
        end
    end
    
    
    function family_name = local_get_rep_family(rep_row)
    
        if any(strcmp(rep_row.Properties.VariableNames, 'family_name'))
            family_name = char(string(rep_row.family_name(1)));
            return;
        end
        if any(strcmp(rep_row.Properties.VariableNames, 'sample_type'))
            family_name = char(string(rep_row.sample_type(1)));
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

    function gamma_req = local_resolve_gamma_req(ref_walker, cfg)

        % priority 1: reference walker carries gamma_req
        gamma_req = local_get_struct_value(ref_walker, 'gamma_req', NaN);
        if isfinite(gamma_req)
            return;
        end
    
        % priority 2: cfg.stage04.gamma_req if exists
        if isstruct(cfg) && isfield(cfg, 'stage04') && isstruct(cfg.stage04) && ...
                isfield(cfg.stage04, 'gamma_req') && ~isempty(cfg.stage04.gamma_req)
            gamma_req = cfg.stage04.gamma_req;
            if isfinite(gamma_req)
                return;
            end
        end
    
        % priority 3: cfg.stage05.require_D_G_min if exists
        if isstruct(cfg) && isfield(cfg, 'stage05') && isstruct(cfg.stage05) && ...
                isfield(cfg.stage05, 'require_D_G_min') && ~isempty(cfg.stage05.require_D_G_min)
            gamma_req = cfg.stage05.require_D_G_min;
            if isfinite(gamma_req)
                return;
            end
        end
    
        % final fallback
        gamma_req = 1.0;
    end
