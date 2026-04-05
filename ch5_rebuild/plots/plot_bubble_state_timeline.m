function fig = plot_bubble_state_timeline(k_idx, is_bubble, visible)
%PLOT_BUBBLE_STATE_TIMELINE Plot bubble state (0/1) over time.
%
% Inputs:
%   k_idx     : [N x 1] step index
%   is_bubble : [N x 1] logical or numeric bubble flag
%   visible   : figure visibility, default 'off'

if nargin < 3
    visible = 'off';
end

k_idx = k_idx(:);
is_bubble = logical(is_bubble(:));

assert(numel(k_idx) == numel(is_bubble), 'k_idx and is_bubble must have the same length.');

fig = figure('Visible', visible);
stairs(k_idx, double(is_bubble), 'LineWidth', 1.5);
grid on;
xlabel('step');
ylabel('bubble state');
title('bubble state timeline');
ylim([-0.1, 1.1]);
yticks([0 1]);
yticklabels({'no','yes'});
end
