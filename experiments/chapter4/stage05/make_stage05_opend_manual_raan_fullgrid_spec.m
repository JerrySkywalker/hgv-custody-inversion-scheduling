function spec = make_stage05_opend_manual_raan_fullgrid_spec(varargin)
%MAKE_STAGE05_OPEND_MANUAL_RAAN_FULLGRID_SPEC Build Stage05/OpenD full-grid manual-RAAN spec.

p = inputParser;
addParameter(p, 'profile', [], @(x) isstruct(x) || isempty(x));
addParameter(p, 'i_grid_deg', [60], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 0, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'raan_range_deg', [0 20], @(x) isnumeric(x) && numel(x)==2);
addParameter(p, 'raan_step_deg', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'plot_visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_manual_raan'), @(x) ischar(x) || isstring(x));
addParameter(p, 'output_suffix', 'fullgrid', @(x) ischar(x) || isstring(x));
addParameter(p, 'save_cache', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'use_parallel', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'show_progress', false, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
args = p.Results;

if isempty(args.profile)
    profile = make_profile_MB_nominal_validation_stage05();
else
    profile = args.profile;
end

rows = local_make_fullgrid_rows(args.h_fixed_km, args.i_grid_deg, args.P_grid, args.T_grid, args.F_fixed);

spec = make_stage05_opend_manual_raan_spec( ...
    'profile', profile, ...
    'base_rows', rows, ...
    'raan_range_deg', args.raan_range_deg, ...
    'raan_step_deg', args.raan_step_deg, ...
    'plot_visible', args.plot_visible, ...
    'artifact_root', args.artifact_root, ...
    'output_suffix', args.output_suffix, ...
    'save_cache', args.save_cache, ...
    'use_parallel', args.use_parallel, ...
    'show_progress', args.show_progress);
end

function rows = local_make_fullgrid_rows(h_fixed_km, i_grid_deg, P_grid, T_grid, F_fixed)
rows_cell = {};
idx = 0;
for ii = 1:numel(i_grid_deg)
    for ip = 1:numel(P_grid)
        for it = 1:numel(T_grid)
            idx = idx + 1;
            row = struct();
            row.design_id = sprintf('FG_i%02d_P%d_T%d', round(i_grid_deg(ii)), P_grid(ip), T_grid(it));
            row.h_km = h_fixed_km;
            row.i_deg = i_grid_deg(ii);
            row.P = P_grid(ip);
            row.T = T_grid(it);
            row.F = F_fixed;
            row.Ns = row.P * row.T;
            rows_cell{idx,1} = row;
        end
    end
end
rows = vertcat(rows_cell{:});
end
