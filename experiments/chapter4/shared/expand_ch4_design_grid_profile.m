function rows = expand_ch4_design_grid_profile(grid_spec, prefix)
if nargin < 1 || ~isstruct(grid_spec)
    error('expand_ch4_design_grid_profile:InvalidInput', ...
        'grid_spec struct is required.');
end

if nargin < 2 || isempty(prefix)
    prefix = 'G';
end

required = {'P_set','T_set','h_set_km','i_set_deg','F_set'};
for k = 1:numel(required)
    f = required{k};
    assert(isfield(grid_spec, f), ...
        'expand_ch4_design_grid_profile:MissingField', ...
        'Missing grid_spec field: %s', f);
end

P_set = grid_spec.P_set(:)';
T_set = grid_spec.T_set(:)';
h_set = grid_spec.h_set_km(:)';
i_set = grid_spec.i_set_deg(:)';
F_set = grid_spec.F_set(:)';

rows = struct('design_id', {}, 'P', {}, 'T', {}, 'h_km', {}, 'i_deg', {}, 'F', {}, 'Ns', {});
idx = 0;

for ih = 1:numel(h_set)
    for ii = 1:numel(i_set)
        for iP = 1:numel(P_set)
            for iT = 1:numel(T_set)
                for iF = 1:numel(F_set)
                    idx = idx + 1;
                    rows(idx).design_id = sprintf('%s%04d', prefix, idx);
                    rows(idx).P = P_set(iP);
                    rows(idx).T = T_set(iT);
                    rows(idx).h_km = h_set(ih);
                    rows(idx).i_deg = i_set(ii);
                    rows(idx).F = F_set(iF);
                    rows(idx).Ns = P_set(iP) * T_set(iT);
                end
            end
        end
    end
end
end
