function out = stage11_entry(cfg)
%STAGE11_ENTRY Stage11 orchestrator for tightened geometric certificates.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);
    cfg.project_stage = 'stage11_entry';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage11.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage11_entry_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage11 started.');

    input_dataset = stage11_build_input_dataset(cfg);
    out = struct();
    out.cfg = cfg;
    out.input_dataset = input_dataset;
    out.window_table = input_dataset.window_table;
    out.case_table = input_dataset.case_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage11.enable_weak
        contrib_bank = stage11_extract_contributions(input_dataset, cfg);
        weak_table = stage11_build_partition(input_dataset, contrib_bank, cfg);

        out.contrib_bank = contrib_bank;
        out.weak_table = weak_table;
        out.window_table.contrib_recon_error_fro = [contrib_bank.recon_error_fro].';
        out.window_table.contrib_recon_error_max_abs = [contrib_bank.recon_error_max_abs].';
        out.window_table.L_weak = weak_table.L_weak;
        out.window_table.eps_pi = weak_table.eps_pi;
        out.window_table.weak_valid = weak_table.weak_valid;
    end

    if cfg.stage11.enable_sub
        if ~isfield(out, 'weak_table')
            error('Stage11 subspace bound requires weak_table / W_pi.');
        end
        sub_table = stage11_compute_subspace_bound(input_dataset, out.weak_table, cfg);
        out.sub_table = sub_table;
        out.window_table.L_sub = sub_table.L_sub;
        out.window_table.sub_valid = sub_table.sub_valid;
        out.window_table.spectral_gap = sub_table.spectral_gap;
    end

    if cfg.stage11.enable_blk
        if ~isfield(out, 'contrib_bank')
            error('Stage11 block bound requires contribution bank.');
        end
        blk_table = stage11_compute_block_bound(out.contrib_bank, input_dataset, cfg);
        out.blk_table = blk_table;
        out.window_table.L_blk = blk_table.L_blk;
        out.window_table.blk_valid = blk_table.blk_valid;
    end

    if isfield(out, 'weak_table') || isfield(out, 'sub_table') || isfield(out, 'blk_table')
        if ~isfield(out, 'sub_table')
            out.sub_table = table(out.window_table.row_id, nan(height(out.window_table), 1), false(height(out.window_table), 1), ...
                'VariableNames', {'row_id', 'L_sub', 'sub_valid'});
        end
        if ~isfield(out, 'blk_table')
            out.blk_table = table(out.window_table.row_id, nan(height(out.window_table), 1), false(height(out.window_table), 1), ...
                'VariableNames', {'row_id', 'L_blk', 'blk_valid'});
        end
        joint_table = stage11_compute_joint_bound(out.window_table, out.weak_table, out.sub_table, out.blk_table, cfg);
        out.joint_table = joint_table;
        out.window_table.L_new = joint_table.L_new;
        out.window_table.best_bound_source = joint_table.best_bound_source;
        out.window_table.new_valid = joint_table.new_valid;
        out.case_table = stage11_aggregate_cases(out.case_table, out.window_table);
    end

    summary_table = stage11_summarize_input_dataset(out, cfg);

    out.summary_table = summary_table;

    if cfg.stage11.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_summary_%s_%s.csv', run_tag, timestamp));
        window_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_windows_%s_%s.csv', run_tag, timestamp));
        case_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage11_input_cases_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(stage11_make_window_export_table(out.window_table), window_csv);
        writetable(stage11_make_case_export_table(out.case_table), case_csv);

        out.files.summary_csv = summary_csv;
        out.files.window_csv = window_csv;
        out.files.case_csv = case_csv;
    end

    if cfg.stage11.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage11_input_dataset_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
    end

    log_msg(log_fid, 'INFO', 'Stage11 finished.');
end
