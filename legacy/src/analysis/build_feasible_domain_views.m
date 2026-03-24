function view_table = build_feasible_domain_views(full_theta_table, feasible_theta_table, anchor_config, slice_type)
%BUILD_FEASIBLE_DOMAIN_VIEWS Construct full-grid slice views for Milestone B.

if nargin < 4
    error('build_feasible_domain_views requires full_theta_table, feasible_theta_table, anchor_config, and slice_type.');
end
if ~istable(full_theta_table) || ~istable(feasible_theta_table)
    error('full_theta_table and feasible_theta_table must be tables.');
end

full_unique = unique_design_rows(full_theta_table);
feasible_unique = unique_design_rows(feasible_theta_table);

view_table = full_unique;
if isempty(view_table)
    return;
end

keys = {'h_km', 'i_deg', 'P', 'T', 'F'};
view_table.is_feasible = false(height(view_table), 1);
view_table.view_type = repmat(string(slice_type), height(view_table), 1);
view_table.anchor_label = repmat(local_anchor_label(anchor_config, slice_type), height(view_table), 1);

if ~isempty(feasible_unique)
    [tf, loc] = ismember(view_table(:, keys), feasible_unique(:, keys), 'rows');
    view_table.is_feasible = tf;
    copy_vars = intersect({'support_sources', 'num_support_sources'}, feasible_unique.Properties.VariableNames, 'stable');
    for k = 1:numel(copy_vars)
        values = view_table.(copy_vars{k});
        values(tf) = feasible_unique.(copy_vars{k})(loc(tf));
        view_table.(copy_vars{k}) = values;
    end
end

if ~ismember('joint_margin', view_table.Properties.VariableNames)
    view_table.joint_margin = nan(height(view_table), 1);
end
if ~ismember('dominant_fail_tag', view_table.Properties.VariableNames)
    view_table.dominant_fail_tag = repmat("unknown", height(view_table), 1);
end

switch lower(char(string(slice_type)))
    case 'hi'
        view_table = sortrows(view_table, {'h_km', 'i_deg'}, {'ascend', 'ascend'});
    case 'pt'
        view_table = sortrows(view_table, {'P', 'T'}, {'ascend', 'ascend'});
    otherwise
        error('Unsupported slice_type: %s', string(slice_type));
end
end

function label = local_anchor_label(anchor_config, slice_type)
anchor = anchor_config;
switch lower(char(string(slice_type)))
    case 'hi'
        label = sprintf('P=%g, T=%g, F=%g', anchor.P, anchor.T, anchor.F);
    case 'pt'
        label = sprintf('h=%g km, i=%g deg, F=%g', anchor.h_km, anchor.i_deg, anchor.F);
    otherwise
        label = "unknown anchor";
end
end
