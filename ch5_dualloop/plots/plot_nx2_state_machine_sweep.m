function fig_files = plot_nx2_state_machine_sweep(rows, scene_preset, fig_dir)
%PLOT_NX2_STATE_MACHINE_SWEEP
% NX-2 second round plotting utility

if nargin < 2 || isempty(scene_preset)
    scene_preset = 'unknown';
end
if nargin < 3 || isempty(fig_dir)
    fig_dir = pwd;
end

guard_vals = unique([rows.guard_enable]);
dwell_vals = unique([rows.dwell_steps]);
ttl_vals = unique([rows.guard_ttl_steps]);

fig_files = {};

for ig = 1:numel(guard_vals)
    gv = guard_vals(ig);
    sub = rows([rows.guard_enable] == gv);

    qmat = nan(numel(dwell_vals), numel(ttl_vals));
    smat = nan(numel(dwell_vals), numel(ttl_vals));
    omat = nan(numel(dwell_vals), numel(ttl_vals));

    for i = 1:numel(sub)
        r = sub(i);
        id = find(dwell_vals == r.dwell_steps, 1, 'first');
        it = find(ttl_vals == r.guard_ttl_steps, 1, 'first');
        qmat(id,it) = r.q_worst_window;
        smat(id,it) = r.switch_count;
        omat(id,it) = r.outage_ratio;
    end

    tag = sprintf('guard%d', double(gv));

    f1 = figure('Visible', 'off');
    imagesc(ttl_vals, dwell_vals, qmat);
    colorbar
    xlabel('guard ttl steps', 'Interpreter', 'none');
    ylabel('dwell steps', 'Interpreter', 'none');
    title(['q worst window - ', scene_preset, ' - ', tag], 'Interpreter', 'none');
    save_path1 = fullfile(fig_dir, ['nx2_heat_q_worst_window_', scene_preset, '_', tag, '.png']);
    saveas(f1, save_path1);
    close(f1);
    fig_files{end+1} = save_path1; %#ok<AGROW>

    f2 = figure('Visible', 'off');
    imagesc(ttl_vals, dwell_vals, smat);
    colorbar
    xlabel('guard ttl steps', 'Interpreter', 'none');
    ylabel('dwell steps', 'Interpreter', 'none');
    title(['switch count - ', scene_preset, ' - ', tag], 'Interpreter', 'none');
    save_path2 = fullfile(fig_dir, ['nx2_heat_switch_count_', scene_preset, '_', tag, '.png']);
    saveas(f2, save_path2);
    close(f2);
    fig_files{end+1} = save_path2; %#ok<AGROW>

    f3 = figure('Visible', 'off');
    imagesc(ttl_vals, dwell_vals, omat);
    colorbar
    xlabel('guard ttl steps', 'Interpreter', 'none');
    ylabel('dwell steps', 'Interpreter', 'none');
    title(['outage ratio - ', scene_preset, ' - ', tag], 'Interpreter', 'none');
    save_path3 = fullfile(fig_dir, ['nx2_heat_outage_ratio_', scene_preset, '_', tag, '.png']);
    saveas(f3, save_path3);
    close(f3);
    fig_files{end+1} = save_path3; %#ok<AGROW>
end

for ig = 1:numel(guard_vals)
    gv = guard_vals(ig);
    sub = rows([rows.guard_enable] == gv);
    tag = sprintf('guard%d', double(gv));

    f4 = figure('Visible', 'off');
    hold on
    for it = 1:numel(ttl_vals)
        ttl = ttl_vals(it);
        tmp = sub([sub.guard_ttl_steps] == ttl);
        [~, ord] = sort([tmp.dwell_steps]);
        tmp = tmp(ord);
        plot([tmp.dwell_steps], [tmp.q_worst_window], 'LineWidth', 1.2);
    end
    xlabel('dwell steps', 'Interpreter', 'none');
    ylabel('q worst window', 'Interpreter', 'none');
    title(['q worst window vs dwell - ', scene_preset, ' - ', tag], 'Interpreter', 'none');
    legend(arrayfun(@(x) sprintf('ttl=%d', x), ttl_vals, 'UniformOutput', false), 'Interpreter', 'none', 'Location', 'best');
    grid on
    save_path4 = fullfile(fig_dir, ['nx2_line_q_worst_window_', scene_preset, '_', tag, '.png']);
    saveas(f4, save_path4);
    close(f4);
    fig_files{end+1} = save_path4; %#ok<AGROW>
end
end
