function rows = manual_make_stage05_fullgrid(varargin)
%MANUAL_MAKE_STAGE05_FULLGRID Build Stage05 full-grid design rows.
%
% Output fields:
%   design_id, h_km, i_deg, P, T, F, Ns

p = inputParser;
addParameter(p, 'i_grid_deg', [30 40 50 60 70 80 90], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'P_grid', [4 6 8 10 12], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'T_grid', [4 6 8 10 12 16], @(x) isnumeric(x) && ~isempty(x));
addParameter(p, 'h_fixed_km', 1000, @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'F_fixed', 1, @(x) isnumeric(x) && isscalar(x));
parse(p, varargin{:});
args = p.Results;

i_grid = args.i_grid_deg(:)';
P_grid = args.P_grid(:)';
T_grid = args.T_grid(:)';
h_km = args.h_fixed_km;
F = args.F_fixed;

n_rows = numel(i_grid) * numel(P_grid) * numel(T_grid);
rows = repmat(struct( ...
    'design_id', "", ...
    'h_km', h_km, ...
    'i_deg', 0, ...
    'P', 0, ...
    'T', 0, ...
    'F', F, ...
    'Ns', 0), n_rows, 1);

idx = 0;
for ii = 1:numel(i_grid)
    for ip = 1:numel(P_grid)
        for it = 1:numel(T_grid)
            idx = idx + 1;

            P = P_grid(ip);
            T = T_grid(it);
            Ns = P * T;

            rows(idx).design_id = sprintf('LEG_i%d_P%d_T%d', i_grid(ii), P, T);
            rows(idx).h_km = h_km;
            rows(idx).i_deg = i_grid(ii);
            rows(idx).P = P;
            rows(idx).T = T;
            rows(idx).F = F;
            rows(idx).Ns = Ns;
        end
    end
end
end
