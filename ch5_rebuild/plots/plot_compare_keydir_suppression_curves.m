function fig = plot_compare_keydir_suppression_curves(t_s, suppA, suppB, nameA, nameB, ylab, ttl, visible)
%PLOT_COMPARE_KEYDIR_SUPPRESSION_CURVES Plot key-direction covariance suppression comparison.

if nargin < 8
    visible = 'off';
end

t_s = t_s(:);
suppA = suppA(:);
suppB = suppB(:);

fig = figure('Visible', visible);
plot(t_s, suppA, 'LineWidth', 1.5);
hold on;
plot(t_s, suppB, 'LineWidth', 1.5);
grid on;
xlabel('time (s)');
ylabel(ylab);
title(ttl);
legend({char(nameA), char(nameB)}, 'Location', 'best');
end
