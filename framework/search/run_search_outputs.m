function outputs = run_search_outputs(grid_table, output_requests)
%RUN_SEARCH_OUTPUTS Process output requests on a truth table.
%
% Supported request types:
%   - truth_table
%   - best_envelope
%   - heatmap_slice
%
% output_requests can be:
%   {} / empty
%   struct array with field .type
%   cell array of structs

if nargin < 2 || isempty(output_requests)
    outputs = struct();
    outputs.truth_table = grid_table;
    return;
end

if iscell(output_requests)
    reqs = [output_requests{:}];
else
    reqs = output_requests;
end

outputs = struct();

for k = 1:numel(reqs)
    req = reqs(k);

    if ~isfield(req, 'type') || isempty(req.type)
        error('run_search_outputs:MissingType', 'Each output request must contain field "type".');
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
