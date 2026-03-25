function search_result = run_design_grid_search_opend(design_grid, task_family, engine_cfg, search_spec)
%RUN_DESIGN_GRID_SEARCH_OPEND Thin wrapper for OpenD design-grid search.

if nargin < 4
    search_spec = struct();
end

search_result = run_design_grid_search(design_grid, task_family, 'opend', engine_cfg, search_spec);
end
