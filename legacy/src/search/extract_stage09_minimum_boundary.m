function out = extract_stage09_minimum_boundary(feasible_theta_table)
%EXTRACT_STAGE09_MINIMUM_BOUNDARY
% Extract the minimum-size feasible boundary from Stage09 feasible domain.
%
% Input
%   feasible_theta_table : table from Stage09.4
%
% Output fields
%   out.N_min_rob
%   out.theta_min_table
%   out.h_range_at_Nmin
%   out.i_range_at_Nmin
%   out.PT_pairs_at_Nmin
%   out.boundary_table

    if nargin < 1
        error('extract_stage09_minimum_boundary requires feasible_theta_table.');
    end
    if ~istable(feasible_theta_table)
        error('feasible_theta_table must be a table.');
    end

    if isempty(feasible_theta_table) || height(feasible_theta_table) < 1
        out = struct();
        out.N_min_rob = inf;
        out.theta_min_table = feasible_theta_table;
        out.h_range_at_Nmin = [nan, nan];
        out.i_range_at_Nmin = [nan, nan];
        out.PT_pairs_at_Nmin = table();
        out.boundary_table = table( ...
            inf, nan, nan, nan, nan, ...
            'VariableNames', {'N_min_rob','h_min_km','h_max_km','i_min_deg','i_max_deg'});
        return;
    end

    if ~any(strcmp(feasible_theta_table.Properties.VariableNames, 'Ns'))
        error('feasible_theta_table must contain variable Ns.');
    end

    N_min_rob = min(feasible_theta_table.Ns);
    theta_min_table = feasible_theta_table(feasible_theta_table.Ns == N_min_rob, :);

    h_min = min(theta_min_table.h_km);
    h_max = max(theta_min_table.h_km);

    i_min = min(theta_min_table.i_deg);
    i_max = max(theta_min_table.i_deg);

    PT_pairs_at_Nmin = unique(theta_min_table(:, {'P','T'}), 'rows');
    PT_pairs_at_Nmin = sortrows(PT_pairs_at_Nmin, {'P','T'}, {'ascend','ascend'});

    boundary_table = table( ...
        N_min_rob, ...
        h_min, ...
        h_max, ...
        i_min, ...
        i_max, ...
        height(theta_min_table), ...
        height(PT_pairs_at_Nmin), ...
        'VariableNames', { ...
            'N_min_rob', ...
            'h_min_km', ...
            'h_max_km', ...
            'i_min_deg', ...
            'i_max_deg', ...
            'n_theta_at_Nmin', ...
            'n_PT_pairs_at_Nmin'});

    out = struct();
    out.N_min_rob = N_min_rob;
    out.theta_min_table = theta_min_table;
    out.h_range_at_Nmin = [h_min, h_max];
    out.i_range_at_Nmin = [i_min, i_max];
    out.PT_pairs_at_Nmin = PT_pairs_at_Nmin;
    out.boundary_table = boundary_table;
end