function fig = plot_outerA_vs_phi_alignment(time, phi_series, threshold, risk_state, alignment, out_png)
%PLOT_OUTERA_VS_PHI_ALIGNMENT
% Phase 6B-1 alignment visualization:
%   top: phi and bad windows
%   bottom: alert modes (warn-or-trigger and trigger-only)

t = time(:);
phi = phi_series(:);
state = risk_state(:);

fig = figure('Visible', 'off');

subplot(2,1,1)
plot(t, phi, 'LineWidth', 1.2); hold on
yline(threshold, '--');

for i = 1:numel(alignment.bad_starts)
    bs = alignment.bad_starts(i);
    be = alignment.bad_ends(i);
    patch([t(bs) t(be) t(be) t(bs)], [0 0 1.2 1.2], [0.9 0.9 0.9], ...
        'FaceAlpha', 0.25, 'EdgeColor', 'none');
end

plot(t, phi, 'LineWidth', 1.2);
ylabel('\phi')
title('Phase 6B-1 OuterA vs Bad Phi Windows')
grid on

subplot(2,1,2)
awt = double(state >= 1);
trg = double(state == 2);

stairs(t, awt + 1.2, 'LineWidth', 1.2); hold on
stairs(t, trg, 'LineWidth', 1.2);

for i = 1:numel(alignment.warn_or_trigger.alert_starts)
    xline(t(alignment.warn_or_trigger.alert_starts(i)));
end

yticks([0 1 2.2])
yticklabels({'trigger','safe/warn baseline','warn+trigger'})
ylabel('alert mode')
xlabel('Time (s)')
grid on

if nargin >= 6 && ~isempty(out_png)
    saveas(fig, out_png);
end
end
