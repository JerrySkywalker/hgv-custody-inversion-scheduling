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
parse(p, varargin{:});
args = p.Results;

spec = struct();
spec.profile = args.profile;
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

spec.legacy_artifact_root = fullfile(spec.artifact_root, 'legacy_reproduction');
spec.opend_artifact_root = fullfile(spec.artifact_root, 'opend_manual_raan');
spec.closedd_artifact_root = fullfile(spec.artifact_root, 'closedd_manual_raan');
end
