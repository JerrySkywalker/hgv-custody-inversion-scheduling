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

switch lower(char(string(slice_type)))
    case 'hi'
        mask = view_table.P == anchor_config.P & view_table.T == anchor_config.T & view_table.F == anchor_config.F;
        view_table = view_table(mask, :);
    case 'pt'
        mask = view_table.h_km == anchor_config.h_km & view_table.i_deg == anchor_config.i_deg & view_table.F == anchor_config.F;
        view_table = view_table(mask, :);
    otherwise
        error('Unsupported slice_type: %s', string(slice_type));
end

if isempty(view_table)
    return;
end

keys = {'h_km', 'i_deg', 'P', 'T', 'F'};
view_table.is_feasible = false(height(view_table), 1);
view_table.view_type = repmat(string(slice_type), height(view_table), 1);
view_table.anchor_label = repmat(local_anchor_label(anchor_config, slice_type), height(view_table), 1);

if ismember('joint_feasible', view_table.Properties.VariableNames)
    view_table.is_feasible = logical(view_table.joint_feasible);
elseif ismember('feasible_flag', view_table.Properties.VariableNames)
    view_table.is_feasible = logical(view_table.feasible_flag);
elseif ~isempty(feasible_unique)
    [tf, ~] = ismember(view_table(:, keys), feasible_unique(:, keys), 'rows');
    view_table.is_feasible = tf;
end

if ~ismember('joint_margin', view_table.Properties.VariableNames)
    view_table.joint_margin = nan(height(view_table), 1);
end
if ~ismember('dominant_fail_tag', view_table.Properties.VariableNames)
    view_table.dominant_fail_tag = repmat("unknown", height(view_table), 1);
end
if ~ismember('Ns', view_table.Properties.VariableNames)
    view_table.Ns = view_table.P .* view_table.T;
end
if ~ismember('feasible_flag', view_table.Properties.VariableNames)
    view_table.feasible_flag = view_table.is_feasible;
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
