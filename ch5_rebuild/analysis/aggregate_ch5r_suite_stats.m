function stats = aggregate_ch5r_suite_stats(T, metrics)
%AGGREGATE_CH5R_SUITE_STATS
% Aggregate suite table into summary_all and summary_by_family.

if nargin < 2 || isempty(metrics)
    metrics = { ...
        'LoC_ratio', ...
        'DC_ratio', ...
        'SC_ratio', ...
        'bubble_time_s', ...
        'bubble_fraction', ...
        'longest_bubble_time_s', ...
        'max_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_pos_km', ...
        'final_rmse_pos_km'};
end

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(T.method)), 'stable');
methods = method_order(ismember(method_order, methods_present));
for i = 1:numel(methods_present)
    if ~ismember(methods_present{i}, methods)
        methods{end+1} = methods_present{i}; %#ok<AGROW>
    end
end

families_present = unique(cellstr(string(T.family)), 'stable');
family_order = {'nominal','heading','critical'};
families = family_order(ismember(family_order, families_present));
for i = 1:numel(families_present)
    if ~ismember(families_present{i}, families)
        families{end+1} = families_present{i}; %#ok<AGROW>
    end
end

summary_all = local_build_summary(T, methods, metrics, false);
summary_by_family = local_build_summary(T, methods, metrics, true, families);

stats = struct();
stats.metrics = metrics;
stats.methods = methods;
stats.families = families;
stats.summary_all = summary_all;
stats.summary_by_family = summary_by_family;
end

function Tout = local_build_summary(T, methods, metrics, by_family, families)
if nargin < 5
    families = {};
end

rows = {};
r = 0;

if ~by_family
    for i = 1:numel(methods)
        m = methods{i};
        idx = strcmpi(string(T.method), m);
        S = T(idx,:);
        if height(S) == 0
            continue;
        end

        r = r + 1;
        row = struct();
        row.method = string(m);
        row.n_cases = height(S);
        row.families = string(strjoin(unique(cellstr(string(S.family)), 'stable'), ','));

        row = local_attach_metric_summaries(row, S, metrics);
        rows{r,1} = row; %#ok<AGROW>
    end
else
    for i = 1:numel(methods)
        m = methods{i};
        for j = 1:numel(families)
            f = families{j};
            idx = strcmpi(string(T.method), m) & strcmpi(string(T.family), f);
            S = T(idx,:);
            if height(S) == 0
                continue;
            end

            r = r + 1;
            row = struct();
            row.method = string(m);
            row.family = string(f);
            row.n_cases = height(S);

            row = local_attach_metric_summaries(row, S, metrics);
            rows{r,1} = row; %#ok<AGROW>
        end
    end
end

if isempty(rows)
    Tout = table();
else
    Tout = struct2table(vertcat(rows{:}));
end
end

function row = local_attach_metric_summaries(row, S, metrics)
for k = 1:numel(metrics)
    metric = metrics{k};
    x = S.(metric);
    M = compute_ch5r_metric_summary(x);

    row.([metric '_min']) = M.min;
    row.([metric '_q1']) = M.q1;
    row.([metric '_median']) = M.median;
    row.([metric '_mean']) = M.mean;
    row.([metric '_q3']) = M.q3;
    row.([metric '_max']) = M.max;
    row.([metric '_std']) = M.std;
    row.([metric '_upper_quartile_mean']) = M.upper_quartile_mean;
end
end
