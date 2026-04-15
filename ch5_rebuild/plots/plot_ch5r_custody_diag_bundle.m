function files = plot_ch5r_custody_diag_bundle(diag_out, output_dir, visible_mode, artifact_tag)
%PLOT_CH5R_CUSTODY_DIAG_BUNDLE

if nargin < 3 || isempty(visible_mode)
    visible_mode = 'off';
end
if nargin < 4 || isempty(artifact_tag)
    artifact_tag = lower(diag_out.phase_name);
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

disp(['[diag][' diag_out.phase_name '] plotting: start'])

t = diag_out.time_s(:);
files = struct();

% ---------- Figure 1: NIS / lambda_min(S) / ||nu|| ----------
disp(['[diag][' diag_out.phase_name '] plotting: figure 1 NIS/lambda_min(S)/||nu||'])
fig1 = figure('Visible', visible_mode, 'Color', 'w', 'Position', [80 80 1100 950]);

subplot(3,1,1);
hold on;
if ~isempty(diag_out.nis.value)
    plot(t, diag_out.nis.value, 'LineWidth', 1.2);
end
grid on;
ylabel('NIS proxy', 'Interpreter', 'latex');
title([diag_out.phase_name '  NIS / $\lambda_{\min}(S_k)$ / $\|\nu_k\|_2$'], 'Interpreter', 'latex');

subplot(3,1,2);
hold on;
if isfield(diag_out.nis, 'lambda_min_S') && ~isempty(diag_out.nis.lambda_min_S)
    plot(t, diag_out.nis.lambda_min_S, 'LineWidth', 1.2);
end
grid on;
ylabel('$\lambda_{\min}(S_k)$', 'Interpreter', 'latex');

subplot(3,1,3);
hold on;
if isfield(diag_out.nis, 'innov_norm') && ~isempty(diag_out.nis.innov_norm)
    plot(t, diag_out.nis.innov_norm, 'LineWidth', 1.2);
end
grid on;
ylabel('$\|\nu_k\|_2$', 'Interpreter', 'latex');
xlabel('time (s)', 'Interpreter', 'latex');

files.fig_nis = fullfile(output_dir, [artifact_tag '_diag_nis_detail.png']);
saveas(fig1, files.fig_nis);
close(fig1);

% ---------- Figure 2: RMSE / bubble-state ----------
disp(['[diag][' diag_out.phase_name '] plotting: figure 2 RMSE/bubble-state'])
fig2 = figure('Visible', visible_mode, 'Color', 'w', 'Position', [100 100 1100 800]);

subplot(2,1,1);
hold on;
if any(isfinite(diag_out.rmse))
    plot(t, diag_out.rmse, 'LineWidth', 1.2);
end
grid on;
ylabel('RMSE pos (km)', 'Interpreter', 'latex');
title([diag_out.phase_name '  RMSE / bubble-state'], 'Interpreter', 'latex');

subplot(2,1,2);
hold on;
yyaxis left;
h1 = stairs(t, double(diag_out.bubble.is_bubble(:)), 'LineWidth', 1.2);
ylabel('bubble', 'Interpreter', 'latex');
ylim([-0.1 1.1]);

yyaxis right;
h2 = stairs(t, diag_out.fsm.state, 'LineWidth', 1.0);
ylim([-0.25 2.25]);
yticks([0 1 2]);
yticklabels({'SC','DC','LoC'});
ylabel('custody state', 'Interpreter', 'latex');
grid on;
xlabel('time (s)', 'Interpreter', 'latex');
legend([h1 h2], {'bubble', 'custody state'}, 'Interpreter', 'latex', 'Location', 'best');

files.fig_rmse_bubble = fullfile(output_dir, [artifact_tag '_diag_rmse_bubble_state.png']);
saveas(fig2, files.fig_rmse_bubble);
close(fig2);

% ---------- Figure 3: Vr / MG / FSM ----------
disp(['[diag][' diag_out.phase_name '] plotting: figure 3 Vr/MG/FSM'])
fig3 = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 1100 950]);

subplot(3,1,1);
hold on;
hVr = gobjects(0);
if ~isempty(diag_out.vr.value)
    hVr(end+1) = plot(t, diag_out.vr.value, 'LineWidth', 1.2);
    if any(isfinite(diag_out.fsm.V_warn))
        hVr(end+1) = plot(t, diag_out.fsm.V_warn, '--', 'LineWidth', 1.0);
    end
    if any(isfinite(diag_out.fsm.V_req))
        hVr(end+1) = plot(t, diag_out.fsm.V_req, ':', 'LineWidth', 1.0);
    end
end
grid on;
ylabel('$V_r$ proxy', 'Interpreter', 'latex');
title([diag_out.phase_name '  $V_r$ / $M_G$ / FSM diagnostics'], 'Interpreter', 'latex');
if numel(hVr) >= 3
    legend(hVr, {'$V_r$', '$V_{\mathrm{warn}}$', '$V_{\mathrm{req}}$'}, 'Interpreter', 'latex', 'Location', 'best');
end

subplot(3,1,2);
hold on;
hMg1 = plot(t, diag_out.mg.value, 'LineWidth', 1.2);
hMg2 = plot(t, diag_out.fsm.eps_warn, '--', 'LineWidth', 1.0);
hMg3 = plot(t, diag_out.fsm.eps_req,  ':', 'LineWidth', 1.0);
grid on;
ylabel('$M_G$ proxy', 'Interpreter', 'latex');
legend([hMg1 hMg2 hMg3], {'$M_G$', '$\epsilon_{\mathrm{warn}}$', '$\epsilon_{\mathrm{req}}$'}, 'Interpreter', 'latex', 'Location', 'best');

subplot(3,1,3);
stairs(t, diag_out.fsm.state, 'LineWidth', 1.2);
ylim([-0.25, 2.25]);
yticks([0 1 2]);
yticklabels({'SC','DC','LoC'});
grid on;
xlabel('time (s)', 'Interpreter', 'latex');
ylabel('custody state', 'Interpreter', 'latex');

files.fig_vr_mg_fsm = fullfile(output_dir, [artifact_tag '_diag_vr_mg_fsm.png']);
saveas(fig3, files.fig_vr_mg_fsm);
close(fig3);

disp(['[diag][' diag_out.phase_name '] plotting: done'])
end
