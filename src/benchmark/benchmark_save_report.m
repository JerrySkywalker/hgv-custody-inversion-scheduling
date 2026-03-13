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
        fprintf(fid, '%s', jsonencode(local_make_json_safe_report(report), 'PrettyPrint', true));
    end
end

function json_report = local_make_json_safe_report(report)
    json_report = report;
    json_report.serial = local_reduce_run_record(report.serial);
    json_report.parallel = local_reduce_run_record(report.parallel);
end

function run_record = local_reduce_run_record(run_record)
    if isfield(run_record, 'result')
        result_value = run_record.result;
        run_record.result_summary = local_result_summary(result_value);
        run_record = rmfield(run_record, 'result');
    end
end

function summary = local_result_summary(result_value)
    summary = struct();
    summary.class = class(result_value);

    if isstruct(result_value)
        summary.fields = fieldnames(result_value);
    else
        summary.size = size(result_value);
    end
end
