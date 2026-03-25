function curve_result = ch4_fixed_path_curve_service(grid_table, path_spec)
%CH4_FIXED_PATH_CURVE_SERVICE Extract a fixed-path curve from a design grid table.
% path_spec examples:
%   struct('mode', 'P_equals_T')
%   struct('mode', 'fixed_P', 'P', 8)
%   struct('mode', 'fixed_T', 'T', 8)

if nargin < 2 || isempty(path_spec)
    path_spec = struct('mode', 'P_equals_T');
end

[curve_table, path_label] = local_build_curve(grid_table, path_spec);

curve_result = struct();
curve_result.path_spec = path_spec;
curve_result.path_label = path_label;
curve_result.curve_table = curve_table;
curve_result.point_count = height(curve_table);
end

function [curve_table, path_label] = local_build_curve(grid_table, path_spec)
mode = "p_equals_t";
if isfield(path_spec, 'mode') && ~isempty(path_spec.mode)
    mode = string(path_spec.mode);
end

switch lower(mode)
    case "p_equals_t"
        curve_table = build_fixed_path_curve(grid_table, struct('mode', 'diag_PT'));
        path_label = "P_equals_T";
    case "fixed_p"
        curve_table = build_fixed_path_curve(grid_table, ...
            struct('mode', 'fixed_P', 'fixed_value', path_spec.P));
        path_label = sprintf('fixed_P_%d', path_spec.P);
    case "fixed_t"
        curve_table = build_fixed_path_curve(grid_table, ...
            struct('mode', 'fixed_T', 'fixed_value', path_spec.T));
        path_label = sprintf('fixed_T_%d', path_spec.T);
    otherwise
        error('ch4_fixed_path_curve_service:UnsupportedMode', ...
            'Unsupported path mode: %s', mode);
end
end
