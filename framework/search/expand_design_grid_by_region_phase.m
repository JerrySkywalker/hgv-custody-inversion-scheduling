function expanded_rows = expand_design_grid_by_region_phase(base_design_grid, region_phase_spec)
%EXPAND_DESIGN_GRID_BY_REGION_PHASE Expand a base design grid with manual region-phase scenarios.
%
% First version only supports:
%   region_phase_spec.enable = true
%   region_phase_spec.mode = 'manual'
%   region_phase_spec.parameter = 'raan_deg' (default)
%   region_phase_spec.output_mode = 'expand_rows' (default)
%
% Added fields to each expanded row:
%   base_design_id
%   region_phase_enabled
%   region_phase_mode
%   region_phase_parameter
%   region_phase_index
%   raan_deg
%
% Also rewrites design_id to include the RAAN suffix.

if nargin < 2 || isempty(region_phase_spec)
    expanded_rows = local_extract_rows(base_design_grid);
    return;
end

if ~isfield(region_phase_spec, 'enable') || ~logical(region_phase_spec.enable)
    expanded_rows = local_extract_rows(base_design_grid);
    return;
end

mode = "manual";
if isfield(region_phase_spec, 'mode') && ~isempty(region_phase_spec.mode)
    mode = lower(string(region_phase_spec.mode));
end

parameter = "raan_deg";
if isfield(region_phase_spec, 'parameter') && ~isempty(region_phase_spec.parameter)
    parameter = lower(string(region_phase_spec.parameter));
end

output_mode = "expand_rows";
if isfield(region_phase_spec, 'output_mode') && ~isempty(region_phase_spec.output_mode)
    output_mode = lower(string(region_phase_spec.output_mode));
end

if output_mode ~= "expand_rows"
    error('expand_design_grid_by_region_phase:UnsupportedOutputMode', ...
        'Unsupported output_mode: %s', output_mode);
end

if parameter ~= "raan_deg"
    error('expand_design_grid_by_region_phase:UnsupportedParameter', ...
        'Unsupported region-phase parameter: %s', parameter);
end

switch mode
    case "manual"
        scenario_values = build_manual_raan_values(region_phase_spec);
    otherwise
        error('expand_design_grid_by_region_phase:UnsupportedMode', ...
            'Unsupported region_phase mode: %s', mode);
end

base_rows = local_extract_rows(base_design_grid);
n_base = numel(base_rows);
n_phase = numel(scenario_values);

expanded_cells = cell(n_base * n_phase, 1);
idx = 0;

for i = 1:n_base
    row = base_rows(i);

    if isfield(row, 'design_id')
        base_id = string(row.design_id);
    else
        base_id = "row_" + string(i);
    end

    for j = 1:n_phase
        idx = idx + 1;
        r = row;

        r.base_design_id = base_id;
        r.region_phase_enabled = true;
        r.region_phase_mode = char(mode);
        r.region_phase_parameter = char(parameter);
        r.region_phase_index = j;
        r.raan_deg = scenario_values(j);

        r.design_id = char(base_id + "_raan_" + string(sprintf('%03g', scenario_values(j))));

        expanded_cells{idx} = r;
    end
end

expanded_rows = vertcat(expanded_cells{:});
end

function rows = local_extract_rows(base_design_grid)
if istable(base_design_grid)
    rows = table2struct(base_design_grid);
elseif isstruct(base_design_grid)
    if isfield(base_design_grid, 'rows')
        rows = base_design_grid.rows;
    elseif isfield(base_design_grid, 'design_table')
        rows = base_design_grid.design_table;
    else
        rows = base_design_grid;
    end
else
    error('expand_design_grid_by_region_phase:UnsupportedDesignGridType', ...
        'Unsupported base_design_grid type: %s', class(base_design_grid));
end

if istable(rows)
    rows = table2struct(rows);
end
end
