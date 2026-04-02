function out = plot_ck_ablation_summary(methods, scene_preset, save_path)
%PLOT_CK_ABLATION_SUMMARY
% NX-1 first round plotting utility

if nargin < 2 || isempty(scene_preset)
    scene_preset = 'unknown';
end
if nargin < 3
    save_path = '';
end

names = {methods.name};
qw = [methods.q_worst_window];
pm = [methods.phi_mean];
outage = [methods.outage_ratio];
longest = [methods.longest_outage_steps];
mean_rmse = [methods.mean_rmse];
max_rmse = [methods.max_rmse];
sw = [methods.switch_count];

f = figure('Visible', 'off');
tiledlayout(2,4);

nexttile; bar(qw); set(gca,'XTickLabel',names); title('q worst window','Interpreter','none'); grid on
nexttile; bar(pm); set(gca,'XTickLabel',names); title('phi mean','Interpreter','none'); grid on
nexttile; bar(outage); set(gca,'XTickLabel',names); title('outage ratio','Interpreter','none'); grid on
nexttile; bar(longest); set(gca,'XTickLabel',names); title('longest outage steps','Interpreter','none'); grid on
nexttile; bar(mean_rmse); set(gca,'XTickLabel',names); title('mean rmse','Interpreter','none'); grid on
nexttile; bar(max_rmse); set(gca,'XTickLabel',names); title('max rmse','Interpreter','none'); grid on
nexttile; bar(sw); set(gca,'XTickLabel',names); title('switch count','Interpreter','none'); grid on
nexttile; axis off

sgtitle(['Phase7B ablation - ', scene_preset], 'Interpreter', 'none');

if ~isempty(save_path)
    saveas(f, save_path);
end

out = struct();
out.fig = f;
out.save_path = save_path;

if nargout == 0
    close(f);
end
end
