function profile_table = build_mb_fixed_h_passratio_profile_stage05replica(full_theta_table, h_km, i_list, family_name)
%BUILD_MB_FIXED_H_PASSRATIO_PROFILE_STAGE05REPLICA Rebuild Stage05 pass-ratio envelopes for MB fixed-h scans.

if nargin < 3 || isempty(i_list)
    if isempty(full_theta_table)
        i_list = [];
    else
        i_list = unique(full_theta_table.i_deg, 'sorted');
    end
end
i_list = unique(i_list, 'sorted');
if nargin < 4 || isempty(family_name)
    family_name = "nominal";
end

profile_table = table();
if isempty(full_theta_table) || ~ismember('pass_ratio', full_theta_table.Properties.VariableNames)
    return;
end

rows = cell(height(full_theta_table), 1);
row_count = 0;
for idx = 1:numel(i_list)
    ii = i_list(idx);
    sub = full_theta_table(full_theta_table.i_deg == ii, :);
    if isempty(sub)
        continue;
    end

    Ns_values = unique(sub.Ns, 'sorted');
    for j = 1:numel(Ns_values)
        tmp = sub(sub.Ns == Ns_values(j), :);
        row_count = row_count + 1;
        rows{row_count} = table( ...
            h_km, ...
            string(family_name), ...
            ii, ...
            Ns_values(j), ...
            max(tmp.pass_ratio), ...
            'VariableNames', {'h_km', 'family_name', 'i_deg', 'Ns', 'best_pass_ratio'});
    end
end

rows = rows(1:row_count);
if ~isempty(rows)
    profile_table = vertcat(rows{:});
    profile_table = sortrows(profile_table, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
end
end
