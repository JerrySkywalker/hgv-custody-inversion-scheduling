function run_record = benchmark_make_run_record(mode_name, opts, elapsed_s, result_value)
    %BENCHMARK_MAKE_RUN_RECORD Normalize one benchmark run into a compact struct.

    if nargin < 4
        result_value = [];
    end

    run_record = struct();
    run_record.mode = char(string(mode_name));
    run_record.elapsed_s = elapsed_s;
    run_record.opts = opts;
    run_record.result = result_value;
end
