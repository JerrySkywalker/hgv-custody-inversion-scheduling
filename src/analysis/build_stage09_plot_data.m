function pdata = build_stage09_plot_data(out9_4, out9_5)
%BUILD_STAGE09_PLOT_DATA
% Prepare compact plotting data for Stage09.6.
%
% Inputs:
%   out9_4 : output struct from stage09_build_feasible_domain
%   out9_5 : output struct from stage09_extract_minimum_boundary
%
% Outputs:
%   pdata.full_theta_table
%   pdata.feasible_theta_table
%   pdata.infeasible_theta_table
%   pdata.theta_min_table
%   pdata.N_min_rob

    if nargin < 2
        error('build_stage09_plot_data requires out9_4 and out9_5.');
    end

    pdata = struct();
    pdata.full_theta_table = out9_4.full_theta_table;
    pdata.feasible_theta_table = out9_4.feasible_theta_table;
    pdata.infeasible_theta_table = out9_4.infeasible_theta_table;
    pdata.fail_partition_table = out9_4.fail_partition_table;

    pdata.theta_min_table = out9_5.theta_min_table_sorted;
    pdata.boundary_table = out9_5.boundary_table;
    pdata.parameter_range_table = out9_5.parameter_range_table;
    pdata.PT_pairs_at_Nmin = out9_5.PT_pairs_at_Nmin;

    if isfield(out9_5, 'N_min_rob')
        pdata.N_min_rob = out9_5.N_min_rob;
    else
        pdata.N_min_rob = inf;
    end
end