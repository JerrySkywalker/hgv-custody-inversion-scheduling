function spec = make_stage05_formal_suite_spec(varargin)
%MAKE_STAGE05_FORMAL_SUITE_SPEC Build the formal Stage05 experiment suite spec.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'raan_range_deg', [0 20], @(x) isnumeric(x) && numel(x) == 2);
addParameter(p, 'raan_step_deg', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_formal_suite'), @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'parallel_monitor', struct(), @(x) isstruct(x) || isempty(x));
addParameter(p, 'min_parallel_rows', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
parse(p, varargin{:});
args = p.Results;

profile = args.profile;
if isempty(profile)
    profile = make_profile_MB_nominal_validation_stage05();
end

spec = struct();
spec.profile = profile;
spec.i_grid_deg = args.i_grid_deg;
spec.P_grid = args.P_grid;
spec.T_grid = args.T_grid;
spec.h_fixed_km = args.h_fixed_km;
spec.F_fixed = args.F_fixed;
spec.raan_range_deg = args.raan_range_deg;
spec.raan_step_deg = args.raan_step_deg;
spec.plot_visible = char(string(args.plot_visible));
spec.artifact_root = char(string(args.artifact_root));
spec.save_cache = logical(args.save_cache);
spec.use_parallel = logical(args.use_parallel);
spec.show_progress = logical(args.show_progress);
spec.min_parallel_rows = args.min_parallel_rows;

default_monitor = struct();
default_monitor.enable_monitor = true;
default_monitor.enable_comm_bytes = true;
default_monitor.enable_slow_iter_warn = true;
default_monitor.slow_iter_threshold_sec = 2.0;
default_monitor.enable_per_point_debug = false;
default_monitor.enable_dataqueue = true;
default_monitor.per_point_log_level = 'DEBUG';

spec.parallel_monitor = local_merge_monitor(default_monitor, args.parallel_monitor);

spec.legacy_artifact_root = fullfile(spec.artifact_root, 'legacy_reproduction');
spec.opend_artifact_root = fullfile(spec.artifact_root, 'opend_manual_raan');
spec.closedd_artifact_root = fullfile(spec.artifact_root, 'closedd_manual_raan');
end

function out = local_merge_monitor(default_monitor, user_monitor)
out = default_monitor;
if isempty(user_monitor) || ~isstruct(user_monitor)
    return;
end

fns = fieldnames(user_monitor);
for i = 1:numel(fns)
    f = fns{i};
    out.(f) = user_monitor.(f);
end
end
