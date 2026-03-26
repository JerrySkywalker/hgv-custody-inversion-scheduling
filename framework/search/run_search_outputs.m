function outputs = run_search_outputs(grid_table, output_requests)
%RUN_SEARCH_OUTPUTS Process output requests on a truth table.
%
% Supported request types:
%   - truth_table
%   - best_envelope
%   - heatmap_slice
%   - scenario_aggregate
%   - raan_aware_envelope
%   - raan_aware_heatmap_slice

if nargin < 2 || isempty(output_requests)
    outputs = struct();
    outputs.truth_table = grid_table;
    return;
end

if iscell(output_requests)
    req_list = output_requests;
elseif isstruct(output_requests)
    req_list = arrayfun(@(x) x, output_requests, 'UniformOutput', false);
else
    error('run_search_outputs:UnsupportedRequestType', ...
        'output_requests must be a cell array or struct array.');
end

outputs = struct();

for k = 1:numel(req_list)
    req = req_list{k};

    if ~isstruct(req)
        error('run_search_outputs:InvalidRequest', ...
            'Each output request must be a struct.');
    end

    if ~isfield(req, 'type') || isempty(req.type)
        error('run_search_outputs:MissingType', ...
            'Each output request must contain field "type".');
    end

    req_type = lower(string(req.type));

    switch req_type
        case "truth_table"
            name = local_get_name(req, 'truth_table');
            outputs.(name) = grid_table;

        case "best_envelope"
            name = local_get_name(req, sprintf('best_envelope_%d', k));
            group_key = local_get_field(req, 'group_key', 'Ns');
            metric_name = local_get_field(req, 'metric_name', 'pass_ratio');
            fixed_filters = local_get_field(req, 'fixed_filters', struct());
            aggregate_mode = local_get_field(req, 'aggregate_mode', 'max');
            outputs.(name) = build_best_envelope( ...
                grid_table, group_key, metric_name, fixed_filters, aggregate_mode);

        case "heatmap_slice"
            name = local_get_name(req, sprintf('heatmap_slice_%d', k));
            metric_name = local_get_field(req, 'metric_name', 'pass_ratio');
            fixed_filters = local_get_field(req, 'fixed_filters', struct());
            row_key = local_get_field(req, 'row_key', 'P');
            col_key = local_get_field(req, 'col_key', 'T');
            outputs.(name) = build_heatmap_slice( ...
                grid_table, metric_name, fixed_filters, row_key, col_key);

        case "scenario_aggregate"
            name = local_get_name(req, sprintf('scenario_aggregate_%d', k));
            group_keys = local_get_field(req, 'group_keys', {'base_design_id'});
            metric_names = local_get_field(req, 'metric_names', {'DG_rob','pass_ratio'});
            aggregate_modes = local_get_field(req, 'aggregate_modes', {'min','max','mean'});
            outputs.(name) = aggregate_over_region_phase( ...
                grid_table, group_keys, metric_names, aggregate_modes);

        case "raan_aware_envelope"
            name = local_get_name(req, sprintf('raan_aware_envelope_%d', k));
            group_key = local_get_field(req, 'group_key', 'Ns');
            metric_name = local_get_field(req, 'metric_name', 'DG_rob');
            fixed_filters = local_get_field(req, 'fixed_filters', struct());
            scenario_metric = local_get_field(req, 'scenario_metric', metric_name);
            scenario_mode = local_get_field(req, 'scenario_mode', 'min');
            outputs.(name) = build_raan_aware_envelope( ...
                grid_table, group_key, metric_name, fixed_filters, scenario_metric, scenario_mode);

        case "raan_aware_heatmap_slice"
            name = local_get_name(req, sprintf('raan_aware_heatmap_slice_%d', k));
            metric_name = local_get_field(req, 'metric_name', 'DG_rob');
            fixed_filters = local_get_field(req, 'fixed_filters', struct());
            row_key = local_get_field(req, 'row_key', 'P');
            col_key = local_get_field(req, 'col_key', 'T');
            scenario_metric = local_get_field(req, 'scenario_metric', metric_name);
            scenario_mode = local_get_field(req, 'scenario_mode', 'min');
            outputs.(name) = build_raan_aware_heatmap_slice( ...
                grid_table, metric_name, fixed_filters, row_key, col_key, scenario_metric, scenario_mode);

        otherwise
            error('run_search_outputs:UnsupportedType', ...
                'Unsupported output request type: %s', req_type);
    end
end
end

function value = local_get_field(s, field_name, default_value)
if isfield(s, field_name) && ~isempty(s.(field_name))
    value = s.(field_name);
else
    value = default_value;
end
end

function name = local_get_name(req, default_name)
if isfield(req, 'name') && ~isempty(req.name)
    name = char(string(req.name));
else
    name = char(string(default_name));
end
end
