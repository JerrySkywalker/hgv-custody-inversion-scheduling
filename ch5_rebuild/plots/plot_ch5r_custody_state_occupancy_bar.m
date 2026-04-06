function out = plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, output_dir, visible_mode)
%PLOT_CH5R_CUSTODY_STATE_OCCUPANCY_BAR
% Plot stacked bar chart for SC/DC/LoC occupancy ratios of R5/R9/R10.
%
% Inputs:
%   out5d, out9d, out10d : diagnostic bundle outputs already available in workspace
%   output_dir           : output folder
%   visible_mode         : 'on' or 'off'
%
% Output:
%   out.fig_file         : saved png path
%   out.table            : occupancy table

if nargin < 5 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

disp('[plot][occupancy] start')

phase_names = {'R5','R9','R10'};

sc_ratio = [ ...
    out5d.diag.fsm.summary.sc_ratio; ...
    out9d.diag.fsm.summary.sc_ratio; ...
    out10d.diag.fsm.summary.sc_ratio];

dc_ratio = [ ...
    out5d.diag.fsm.summary.dc_ratio; ...
    out9d.diag.fsm.summary.dc_ratio; ...
    out10d.diag.fsm.summary.dc_ratio];

loc_ratio = [ ...
    out5d.diag.fsm.summary.loc_ratio; ...
    out9d.diag.fsm.summary.loc_ratio; ...
    out10d.diag.fsm.summary.loc_ratio];

T = table( ...
    string(phase_names(:)), ...
    sc_ratio, dc_ratio, loc_ratio, ...
    'VariableNames', {'phase','SC_ratio','DC_ratio','LoC_ratio'});

fig = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 980 620]);

Y = [sc_ratio, dc_ratio, loc_ratio];
bh = bar(Y, 'stacked', 'LineWidth', 0.8); %#ok<NASGU>
grid on;
ylim([0 1]);
xticks(1:3);
xticklabels(phase_names);
ylabel('occupancy ratio', 'Interpreter', 'latex');
title('SC / DC / LoC occupancy comparison', 'Interpreter', 'latex');
legend({'SC','DC','LoC'}, 'Interpreter', 'latex', 'Location', 'eastoutside');

for i = 1:size(Y,1)
    y_sc = Y(i,1);
    y_dc = Y(i,2);
    y_loc = Y(i,3);

    if y_sc > 0.03
        text(i, y_sc/2, sprintf('%.1f%%', 100*y_sc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    if y_dc > 0.03
        text(i, y_sc + y_dc/2, sprintf('%.1f%%', 100*y_dc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    if y_loc > 0.03
        text(i, y_sc + y_dc + y_loc/2, sprintf('%.1f%%', 100*y_loc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
end

fig_file = fullfile(output_dir, 'ch5r_custody_state_occupancy_bar.png');
saveas(fig, fig_file);
close(fig);

disp('[plot][occupancy] done')
disp(T)

out = struct();
out.fig_file = fig_file;
out.table = T;
end
