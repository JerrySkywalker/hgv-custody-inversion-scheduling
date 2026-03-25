function envelope_table = build_best_envelope(grid_table, group_key, metric_name, fixed_filters, aggregate_mode)
%BUILD_BEST_ENVELOPE Build an envelope table by grouping on one key and aggregating a metric.

if nargin < 2 || isempty(group_key)
    group_key = 'Ns';
end
if nargin < 3 || isempty(metric_name)
    metric_name = 'pass_ratio';
end
if nargin < 4
    fixed_filters = struct();
end
if nargin < 5 || isempty(aggregate_mode)
    aggregate_mode = 'max';
end

slice_table = slice_truth_table(grid_table, struct('fixed_filters', fixed_filters));
group_values = unique(slice_table.(group_key));
group_values = sort(group_values(:));

rows = repmat(struct(), numel(group_values), 1);
for k = 1:numel(group_values)
    value = group_values(k);
    tmp = slice_table(slice_table.(group_key) == value, :);

    switch lower(string(aggregate_mode))
        case "max"
            [best_metric, idx_best] = max(tmp.(metric_name));
        case "min"
            [best_metric, idx_best] = min(tmp.(metric_name));
        otherwise
            error('build_best_envelope:UnsupportedAggregate', ...
                'Unsupported aggregate mode: %s', aggregate_mode);
    end

    rows(k).(group_key) = value;
    rows(k).best_metric = best_metric;
    rows(k).metric_name = string(metric_name);

    if ismember('joint_margin', tmp.Properties.VariableNames)
        rows(k).best_joint_margin = tmp.joint_margin(idx_best);
    else
        rows(k).best_joint_margin = NaN;
    end

    if ismember('DG_rob', tmp.Properties.VariableNames)
        rows(k).best_geometry_margin = tmp.DG_rob(idx_best);
    else
        rows(k).best_geometry_margin = NaN;
    end

    if ismember('design_id', tmp.Properties.VariableNames)
        rows(k).argmax_design_id = string(tmp.design_id(idx_best));
    else
        rows(k).argmax_design_id = "";
    end

    if ismember('P', tmp.Properties.VariableNames)
        rows(k).argmax_P = tmp.P(idx_best);
    else
        rows(k).argmax_P = NaN;
    end
    if ismember('T', tmp.Properties.VariableNames)
        rows(k).argmax_T = tmp.T(idx_best);
    else
        rows(k).argmax_T = NaN;
    end
end

envelope_table = struct2table(rows);
if ismember('best_metric', envelope_table.Properties.VariableNames)
    envelope_table = renamevars(envelope_table, 'best_metric', metric_name);
end
end
