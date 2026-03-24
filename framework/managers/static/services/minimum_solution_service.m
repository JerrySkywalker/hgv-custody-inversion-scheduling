function minimum_solution_result = minimum_solution_service(truth_result)
if nargin < 1 || ~isstruct(truth_result) || ~isfield(truth_result, 'table')
    error('minimum_solution_service:InvalidInput', ...
        'truth_result with table field is required.');
end

tbl = truth_result.table;

if isempty(tbl)
    minimum_solution_result = struct();
    minimum_solution_result.feasible_table = tbl;
    minimum_solution_result.solution_table = tbl;
    minimum_solution_result.min_Ns = NaN;
    minimum_solution_result.solution_count = 0;
    minimum_solution_result.meta = struct('status', 'empty_table');
    return;
end

feasible_mask = tbl.is_feasible == true;
feasible_table = tbl(feasible_mask, :);

if isempty(feasible_table)
    minimum_solution_result = struct();
    minimum_solution_result.feasible_table = feasible_table;
    minimum_solution_result.solution_table = feasible_table;
    minimum_solution_result.min_Ns = NaN;
    minimum_solution_result.solution_count = 0;
    minimum_solution_result.meta = struct('status', 'no_feasible_solution');
    return;
end

min_Ns = min(feasible_table.Ns);
solution_mask = feasible_table.Ns == min_Ns;
solution_table = feasible_table(solution_mask, :);

minimum_solution_result = struct();
minimum_solution_result.feasible_table = feasible_table;
minimum_solution_result.solution_table = solution_table;
minimum_solution_result.min_Ns = min_Ns;
minimum_solution_result.solution_count = height(solution_table);
minimum_solution_result.meta = struct('status', 'ok');
end
