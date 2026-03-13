function saved = benchmark_save_report(report, save_opts)
    %BENCHMARK_SAVE_REPORT Persist benchmark report to MAT/JSON sidecar files.

    if nargin < 2 || isempty(save_opts)
        save_opts = struct();
    end

    if ~isfield(save_opts, 'save_mat') || isempty(save_opts.save_mat)
        save_opts.save_mat = true;
    end
    if ~isfield(save_opts, 'save_json') || isempty(save_opts.save_json)
        save_opts.save_json = true;
    end

    ensure_dir(report.paths.output_dir);

    saved = struct('mat_file', '', 'json_file', '');

    if save_opts.save_mat
        saved.mat_file = fullfile(report.paths.output_dir, [report.run_id '.mat']);
        save(saved.mat_file, 'report', '-v7.3');
    end

    if save_opts.save_json
        saved.json_file = fullfile(report.paths.output_dir, [report.run_id '.json']);
        fid = fopen(saved.json_file, 'w');
        if fid < 0
            error('benchmark_save_report:openFailed', 'Failed to open %s for writing.', saved.json_file);
        end
        cleanup_fid = onCleanup(@() fclose(fid));
        fprintf(fid, '%s', jsonencode(report, 'PrettyPrint', true));
    end
end
