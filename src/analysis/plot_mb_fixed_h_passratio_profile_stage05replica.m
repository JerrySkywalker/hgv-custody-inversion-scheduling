function fig = plot_mb_fixed_h_passratio_profile_stage05replica(full_theta_table, h_km, i_list)
%PLOT_MB_FIXED_H_PASSRATIO_PROFILE_STAGE05REPLICA Replicate the Stage05 pass-ratio profile figure for MB comparison.

if nargin < 3 || isempty(i_list)
    if isempty(full_theta_table)
        i_list = [];
    else
        i_list = unique(full_theta_table.i_deg, 'sorted');
    end
end
i_list = unique(i_list, 'sorted');

fig = figure('Color', 'w', 'Position', [100, 100, 980, 560], 'Visible', 'off');
hold on;
grid(gca, 'on');
box on;

if isempty(full_theta_table)
    text(0.5, 0.5, 'Empty grid', 'HorizontalAlignment', 'center');
    axis off;
    return;
end

for k = 1:numel(i_list)
    ii = i_list(k);
    sub = full_theta_table(full_theta_table.i_deg == ii, :);
    if isempty(sub)
        continue;
    end

    Ns_u = unique(sub.Ns);
    best_pass = nan(size(Ns_u));
    for j = 1:numel(Ns_u)
        tmp = sub(sub.Ns == Ns_u(j), :);
        best_pass(j) = max(tmp.pass_ratio);
    end

    plot(Ns_u, best_pass, '-o', 'LineWidth', 1.2, 'MarkerSize', 5, ...
        'DisplayName', sprintf('i=%.0f deg', ii));
end

xlabel('total satellites N_s');
ylabel('max pass ratio under fixed i');
ylim([0, 1.05]);
title(sprintf('Stage05-Style Pass-Ratio Profile versus N_s at h = %.0f km', h_km));
legend('Location', 'eastoutside');
end
