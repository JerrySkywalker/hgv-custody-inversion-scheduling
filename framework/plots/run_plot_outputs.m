function plot_outputs = run_plot_outputs(outputs, plot_requests)
%RUN_PLOT_OUTPUTS Generate plots from derived outputs.
%
% Supported plot request types:
%   - envelope_curve
%   - heatmap_matrix

if nargin < 2 || isempty(plot_requests)
    plot_outputs = struct();
    return;
end

if iscell(plot_requests)
    req_list = plot_requests;
elseif isstruct(plot_requests)
    req_list = arrayfun(@(x) x, plot_requests, 'UniformOutput', false);
else
    error('run_plot_outputs:UnsupportedRequestType', ...
        'plot_requests must be a cell array or struct array.');
end

plot_outputs = struct();

for k = 1:numel(req_list)
    req = req_list{k};

    if ~isfield(req, 'type') || isempty(req.type)
        error('run_plot_outputs:MissingType', ...
            'Each plot request must contain field "type".');
    end
    if ~isfield(req, 'source') || isempty(req.source)
        error('run_plot_outputs:MissingSource', ...
            'Each plot request must contain field "source".');
    end

    req_type = lower(string(req.type));
    source_name = char(string(req.source));

    if ~isfield(outputs, source_name)
        error('run_plot_outputs:MissingSourceOutput', ...
            'Missing source output: %s', source_name);
    end

    src = outputs.(source_name);
    out_name = local_get_name(req, sprintf('plot_%d', k));

    switch req_type
        case "envelope_curve"
            x_field = local_get_field(req, 'x_field', 'Ns');
            y_field = local_get_field(req, 'y_field', 'pass_ratio');

            plot_spec = local_get_field(req, 'plot_spec', struct());
            fig = plot_envelope_curve(src.(x_field), src.(y_field), plot_spec);

            save_spec = local_get_field(req, 'save_spec', struct());
            file_path = save_figure_artifact(fig, save_spec);

            plot_outputs.(out_name) = struct( ...
                'figure_handle', fig, ...
                'file_path', string(file_path), ...
                'source', string(source_name), ...
                'type', "envelope_curve");

        case "heatmap_matrix"
            plot_spec = local_get_field(req, 'plot_spec', struct());
            fig = plot_heatmap_matrix(src.row_values, src.col_values, src.value_matrix, plot_spec);

            save_spec = local_get_field(req, 'save_spec', struct());
            file_path = save_figure_artifact(fig, save_spec);

            plot_outputs.(out_name) = struct( ...
                'figure_handle', fig, ...
                'file_path', string(file_path), ...
                'source', string(source_name), ...
                'type', "heatmap_matrix");

        otherwise
            error('run_plot_outputs:UnsupportedType', ...
                'Unsupported plot request type: %s', req_type);
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
