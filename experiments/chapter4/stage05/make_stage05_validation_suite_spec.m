function spec = make_stage05_validation_suite_spec(varargin)
%MAKE_STAGE05_VALIDATION_SUITE_SPEC Build the validation suite spec for strict legacy Stage05 reproduction.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_validation_suite'), @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
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
spec.plot_visible = char(string(args.plot_visible));
spec.artifact_root = char(string(args.artifact_root));
spec.save_cache = logical(args.save_cache);
spec.use_parallel = logical(args.use_parallel);
spec.show_progress = logical(args.show_progress);

spec.parallel_monitor = struct();
spec.parallel_monitor.enable_monitor = true;
spec.parallel_monitor.enable_comm_bytes = true;
spec.parallel_monitor.enable_slow_iter_warn = true;
spec.parallel_monitor.slow_iter_threshold_sec = 2.0;
spec.parallel_monitor.enable_per_point_debug = false;
spec.parallel_monitor.enable_dataqueue = true;
spec.parallel_monitor.per_point_log_level = 'DEBUG';

spec.reproduction_artifact_root = fullfile(spec.artifact_root, 'reproduction');
spec.validation_artifact_root = fullfile(spec.artifact_root, 'validation');
end
