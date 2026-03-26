function mon = build_parallel_monitor_options(search_spec)
%BUILD_PARALLEL_MONITOR_OPTIONS Normalize parallel monitor options.

mon = struct();
mon.enable_monitor = false;
mon.enable_comm_bytes = true;
mon.enable_slow_iter_warn = true;
mon.slow_iter_threshold_sec = 2.0;
mon.enable_per_point_debug = false;
mon.enable_dataqueue = false;
mon.per_point_log_level = 'DEBUG';

if nargin < 1 || isempty(search_spec) || ~isstruct(search_spec)
    return;
end

if isfield(search_spec, 'parallel_monitor') && isstruct(search_spec.parallel_monitor)
    src = search_spec.parallel_monitor;

    if isfield(src, 'enable_monitor'), mon.enable_monitor = logical(src.enable_monitor); end
    if isfield(src, 'enable_comm_bytes'), mon.enable_comm_bytes = logical(src.enable_comm_bytes); end
    if isfield(src, 'enable_slow_iter_warn'), mon.enable_slow_iter_warn = logical(src.enable_slow_iter_warn); end
    if isfield(src, 'slow_iter_threshold_sec'), mon.slow_iter_threshold_sec = double(src.slow_iter_threshold_sec); end
    if isfield(src, 'enable_per_point_debug'), mon.enable_per_point_debug = logical(src.enable_per_point_debug); end
    if isfield(src, 'enable_dataqueue'), mon.enable_dataqueue = logical(src.enable_dataqueue); end
    if isfield(src, 'per_point_log_level') && ~isempty(src.per_point_log_level)
        mon.per_point_log_level = upper(char(string(src.per_point_log_level)));
    end
end
end
