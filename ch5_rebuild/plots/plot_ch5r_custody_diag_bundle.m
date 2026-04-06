function files = plot_ch5r_custody_diag_bundle(diag_out, output_dir, visible_mode)
%PLOT_CH5R_CUSTODY_DIAG_BUNDLE

if nargin < 3 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

disp(['[diag][' diag_out.phase_name '] plotting: start'])

t = diag_out.time_s(:);
files = struct();

% ---------- Figure 1: Vr / MG / FSM ----------
disp(['[diag][' diag_out.phase_name '] plotting: figure 1 Vr/MG/FSM'])
fig1 = figure('Visible', visible_mode, 'Color', 'w', 'Position', [100 100 1100 900]);

subplot(3,1,1);
hold on;
if ~isempty(diag_out.vr.value)
    plot(t, diag_out.vr.value, 'LineWidth', 1.2);
    if any(isfinite(diag_out.fsm.V_warn))
        plot(t, diag_out.fsm.V_warn, '--', 'LineWidth', 1.0);
    end
    if any(isfinite(diag_out.fsm.V_req))
        plot(t, diag_out.fsm.V_req, ':', 'LineWidth', 1.0);
    end
end
grid on;
ylabel('$V_r$ proxy', 'Interpreter', 'latex');
title([diag_out.phase_name '  $V_r$ / $M_G$ / FSM diagnostics'], 'Interpreter', 'latex');

subplot(3,1,2);
hold on;
plot(t, diag_out.mg.value, 'LineWidth', 1.2);
plot(t, diag_out.fsm.eps_warn, '--', 'LineWidth', 1.0);
plot(t, diag_out.fsm.eps_req,  ':', 'LineWidth', 1.0);
grid on;
ylabel('$M_G$ proxy', 'Interpreter', 'latex');

subplot(3,1,3);
stairs(t, diag_out.fsm.state, 'LineWidth', 1.2);
ylim([-0.25, 2.25]);
yticks([0 1 2]);
yticklabels({'SC','DC','LoC'});
grid on;
xlabel('time (s)', 'Interpreter', 'latex');
ylabel('custody state', 'Interpreter', 'latex');

files.fig1 = fullfile(output_dir, [lower(diag_out.phase_name) '_diag_vr_mg_fsm.png']);
saveas(fig1, files.fig1);
close(fig1);

% ---------- Figure 2: NIS / RMSE / bubble-state ----------
disp(['[diag][' diag_out.phase_name '] plotting: figure 2 NIS/RMSE/bubble-state'])
fig2 = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 1100 900]);

subplot(3,1,1);
hold on;
if ~isempty(diag_out.nis.value)
    plot(t, diag_out.nis.value, 'LineWidth', 1.2);
end
grid on;
ylabel('NIS proxy', 'Interpreter', 'latex');
title([diag_out.phase_name '  NIS / RMSE / bubble-state'], 'Interpreter', 'latex');

subplot(3,1,2);
hold on;
if any(isfinite(diag_out.rmse))
    plot(t, diag_out.rmse, 'LineWidth', 1.2);
end
grid on;
ylabel('RMSE pos (km)', 'Interpreter', 'latex');

subplot(3,1,3);
hold on;
yyaxis left;
stairs(t, double(diag_out.bubble.is_bubble(:)), 'LineWidth', 1.2);
ylabel('bubble', 'Interpreter', 'latex');
ylim([-0.1 1.1]);

yyaxis right;
stairs(t, diag_out.fsm.state, 'LineWidth', 1.0);
ylim([-0.25 2.25]);
yticks([0 1 2]);
yticklabels({'SC','DC','LoC'});
ylabel('custody state', 'Interpreter', 'latex');
grid on;
xlabel('time (s)', 'Interpreter', 'latex');

files.fig2 = fullfile(output_dir, [lower(diag_out.phase_name) '_diag_nis_rmse_bubble_state.png']);
saveas(fig2, files.fig2);
close(fig2);

disp(['[diag][' diag_out.phase_name '] plotting: done'])
end
