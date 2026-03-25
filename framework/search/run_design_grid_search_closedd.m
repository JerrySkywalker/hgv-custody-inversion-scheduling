function search_result = run_design_grid_search_closedd(design_grid, task_family, engine_cfg, search_spec)
%RUN_DESIGN_GRID_SEARCH_CLOSEDD Thin wrapper for ClosedD design-grid search.

if nargin < 4
    search_spec = struct();
end

search_result = run_design_grid_search(design_grid, task_family, 'closedd', engine_cfg, search_spec);
end
