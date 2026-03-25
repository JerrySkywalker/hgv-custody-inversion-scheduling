function curve_table = build_fixed_path_curve(grid_table, path_spec, metric_name, fixed_filters)
%BUILD_FIXED_PATH_CURVE Extract a fixed-path curve such as P=T or fixed P/T.

if nargin < 2 || isempty(path_spec)
    path_spec = struct('mode', 'diag_PT');
end
if nargin < 3 || isempty(metric_name)
    metric_name = 'pass_ratio';
end
if nargin < 4
    fixed_filters = struct();
end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));
mode = "diag_PT";
if isfield(path_spec, 'mode') && ~isempty(path_spec.mode)
    mode = string(path_spec.mode);
end

switch lower(mode)
    case "diag_pt"
        mask = slice_table.P == slice_table.T;
    case "p_equals_t"
        mask = slice_table.P == slice_table.T;
    case "fixed_p"
        mask = slice_table.P == path_spec.fixed_value;
    case "fixed_t"
        mask = slice_table.T == path_spec.fixed_value;
    otherwise
        error('build_fixed_path_curve:UnsupportedMode', ...
            'Unsupported path mode: %s', mode);
end

curve_table = slice_table(mask, :);
curve_table = sortrows(curve_table, {'Ns', 'P', 'T'}, {'ascend', 'ascend', 'ascend'});

if ismember(metric_name, curve_table.Properties.VariableNames)
    curve_table.metric_value = curve_table.(metric_name);
end
end
