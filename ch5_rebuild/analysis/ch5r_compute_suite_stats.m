function stats = ch5r_compute_suite_stats(T, metrics)
%CH5R_COMPUTE_SUITE_STATS
% Compute overall and by-family statistics from multicase suite table.

if nargin < 2 || isempty(metrics)
    metrics = { ...
        'bubble_steps', ...
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

overall_rows = {};
r = 0;

for i = 1:numel(methods)
    m = methods{i};
    idx = strcmpi(string(T.method), m);
    S = T(idx,:);

    r = r + 1;
    row = struct();
    row.method = string(m);
    row.n_cases = height(S);

    fams = unique(cellstr(string(S.family)), 'stable');
    row.families = string(strjoin(fams, ','));

    for j = 1:numel(metrics)
        metric = metrics{j};
        vals = S.(metric);
        vals = vals(isfinite(vals));

        [mn, av, md, q75, mx] = local_stats(vals);

        row.([metric '_min']) = mn;
        row.([metric '_mean']) = av;
        row.([metric '_median']) = md;
        row.([metric '_q75']) = q75;
        row.([metric '_max']) = mx;
    end

    overall_rows{r,1} = row; %#ok<AGROW>
end

overall = local_struct_rows_to_table(overall_rows);

family_rows = {};
r = 0;

for i = 1:numel(methods)
    for j = 1:numel(families)
        m = methods{i};
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

        for k = 1:numel(metrics)
            metric = metrics{k};
            vals = S.(metric);
            vals = vals(isfinite(vals));

            [mn, av, md, q75, mx] = local_stats(vals);

            row.([metric '_min']) = mn;
            row.([metric '_mean']) = av;
            row.([metric '_median']) = md;
            row.([metric '_q75']) = q75;
            row.([metric '_max']) = mx;
        end

        family_rows{r,1} = row; %#ok<AGROW>
    end
end

by_family = local_struct_rows_to_table(family_rows);

stats = struct();
stats.metrics = metrics;
stats.methods = methods;
stats.families = families;
stats.overall = overall;
stats.by_family = by_family;
end

function [mn, av, md, q75, mx] = local_stats(vals)
if isempty(vals)
    mn = NaN; av = NaN; md = NaN; q75 = NaN; mx = NaN;
    return;
end
mn = min(vals);
av = mean(vals);
md = median(vals);
q75 = prctile(vals, 75);
mx = max(vals);
end

function T = local_struct_rows_to_table(rows)
if isempty(rows)
    T = table();
    return;
end
S = vertcat(rows{:});
T = struct2table(S);
end
