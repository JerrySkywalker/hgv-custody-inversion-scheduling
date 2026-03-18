function out = build_mb_requirement_surface(full_theta_table, xvar, yvar)
%BUILD_MB_REQUIREMENT_SURFACE Aggregate minimum feasible constellation size on a 2D parameter surface.

if nargin < 3
    error('build_mb_requirement_surface requires full_theta_table, xvar, and yvar.');
end
if isempty(full_theta_table)
    out = local_empty_output(xvar, yvar);
    return;
end

required = unique([{xvar, yvar}, {'Ns'}], 'stable');
missing = setdiff(required, full_theta_table.Properties.VariableNames);
if ~isempty(missing)
    error('build_mb_requirement_surface missing variables: %s', strjoin(missing, ', '));
end

feasible_var = local_pick_feasible_var(full_theta_table);
T = sortrows(full_theta_table, {yvar, xvar, 'Ns', 'joint_margin'}, {'ascend', 'ascend', 'ascend', 'descend'});
x_values = unique(T.(xvar), 'sorted');
y_values = unique(T.(yvar), 'sorted');

rows = cell(numel(y_values) * numel(x_values), 1);
row_count = 0;
value_matrix = nan(numel(y_values), numel(x_values));
margin_matrix = nan(numel(y_values), numel(x_values));

for iy = 1:numel(y_values)
    for ix = 1:numel(x_values)
        mask = T.(xvar) == x_values(ix) & T.(yvar) == y_values(iy);
        sub = T(mask, :);
        if isempty(sub)
            continue;
        end
        feasible_sub = sub(logical(sub.(feasible_var)), :);
        row_count = row_count + 1;
        rows{row_count} = local_build_surface_row(sub, feasible_sub, xvar, yvar, x_values(ix), y_values(iy));
        if ~isempty(feasible_sub)
            best = sortrows(feasible_sub, {'Ns', 'joint_margin'}, {'ascend', 'descend'});
            value_matrix(iy, ix) = best.Ns(1);
            if ismember('joint_margin', best.Properties.VariableNames)
                margin_matrix(iy, ix) = best.joint_margin(1);
            end
        end
    end
end

rows = rows(1:row_count);
surface_table = struct2table(vertcat(rows{:}));
surface_table = sortrows(surface_table, {yvar, xvar}, {'ascend', 'ascend'});

out = struct();
out.surface_table = surface_table;
out.xvar = string(xvar);
out.yvar = string(yvar);
out.x_values = x_values(:);
out.y_values = y_values(:);
out.value_matrix = value_matrix;
out.margin_matrix = margin_matrix;
end

function row = local_build_surface_row(sub, feasible_sub, xvar, yvar, x_value, y_value)
row = struct();
row.(xvar) = x_value;
row.(yvar) = y_value;
row.num_total = height(sub);
row.num_feasible = height(feasible_sub);
row.feasible_ratio = local_safe_divide(height(feasible_sub), height(sub));
row.minimum_feasible_Ns = NaN;
row.best_joint_margin_at_min = NaN;
row.minimum_support_sources = "";
if ~isempty(feasible_sub)
    best = sortrows(feasible_sub, {'Ns', 'joint_margin'}, {'ascend', 'descend'});
    row.minimum_feasible_Ns = best.Ns(1);
    if ismember('joint_margin', best.Properties.VariableNames)
        row.best_joint_margin_at_min = best.joint_margin(1);
    end
    if ismember('support_sources', best.Properties.VariableNames)
        row.minimum_support_sources = string(best.support_sources(1));
    end
end
end

function feasible_var = local_pick_feasible_var(T)
if ismember('feasible_flag', T.Properties.VariableNames)
    feasible_var = 'feasible_flag';
elseif ismember('joint_feasible', T.Properties.VariableNames)
    feasible_var = 'joint_feasible';
else
    error('build_mb_requirement_surface requires feasible_flag or joint_feasible.');
end
end

function out = local_empty_output(xvar, yvar)
out = struct();
out.surface_table = table();
out.xvar = string(xvar);
out.yvar = string(yvar);
out.x_values = [];
out.y_values = [];
out.value_matrix = [];
out.margin_matrix = [];
end

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end
