function out = plot_dualloop_evidence_timeline(varargin)
%PLOT_DUALLOOP_EVIDENCE_TIMELINE
% P-Back-1 second cut
% Warning-free evidence timeline plotter with tolerant varargin parsing.
%
% Accepted usage patterns (tolerant):
%   plot_dualloop_evidence_timeline(result)
%   plot_dualloop_evidence_timeline(result, save_path)
%   plot_dualloop_evidence_timeline(result, scene_name, save_path)
%
% Any missing fields are skipped gracefully.

result = [];
scene_name = '';
save_path = '';

for i = 1:nargin
    a = varargin{i};
    if isstruct(a)
        result = a;
    elseif ischar(a) || isstring(a)
        s = char(a);
        if endsWith(lower(s), '.png')
            save_path = s;
        else
            scene_name = s;
        end
    end
end

if isempty(result)
    error('plot_dualloop_evidence_timeline:missingResult', 'A result struct is required.');
end

t = local_get_time(result);
mr_hat = local_get_field(result, {'mr_hat','mr_hat_series','risk_hat','phi_series'});
mr_tilde = local_get_field(result, {'mr_tilde','mr_tilde_series','risk_tilde','mr_series'});
omega_max = local_get_field(result, {'omega_max','omega_max_series','omega_series'});
threshold = local_get_scalar(result, {'threshold','phi_threshold','risk_threshold'});

f = figure('Visible', 'off');
hold on
grid on

legend_items = {};

if ~isempty(mr_hat)
    plot(t, mr_hat, 'LineWidth', 1.5);
    legend_items{end+1} = 'phi'; %#ok<AGROW>
end
if ~isempty(mr_tilde)
    plot(t, mr_tilde, 'LineWidth', 1.5);
    legend_items{end+1} = 'M_R'; %#ok<AGROW>
end
if ~isempty(omega_max)
    plot(t, omega_max, 'LineWidth', 1.5);
    legend_items{end+1} = 'omega_max'; %#ok<AGROW>
end
if ~isempty(threshold)
    yline(threshold, '--', 'threshold', 'Interpreter', 'none');
    legend_items{end+1} = 'threshold'; %#ok<AGROW>
end

xlabel('time', 'Interpreter', 'none');
ylabel('evidence value', 'Interpreter', 'none');

if isempty(scene_name)
    ttl = 'Dual-loop evidence timeline';
else
    ttl = ['Dual-loop evidence timeline - ', scene_name];
end
title(ttl, 'Interpreter', 'none');

if ~isempty(legend_items)
    legend(legend_items, 'Location', 'best', 'Interpreter', 'none');
end

if ~isempty(save_path)
    saveas(f, save_path);
end

out = struct();
out.fig = f;
out.save_path = save_path;
out.scene_name = scene_name;

if nargout == 0
    close(f);
end
end

function t = local_get_time(result)
t = local_get_field(result, {'time','t','time_s'});
if isempty(t)
    n = 0;
    probe = local_get_field(result, {'mr_hat','mr_hat_series','risk_hat','phi_series','mr_tilde','mr_tilde_series','omega_max','omega_max_series'});
    if ~isempty(probe)
        n = numel(probe);
    end
    if n == 0
        n = 1;
    end
    t = (1:n).';
else
    t = t(:);
end
end

function v = local_get_field(S, names)
v = [];
for i = 1:numel(names)
    if isfield(S, names{i})
        v = S.(names{i});
        if ~isempty(v)
            v = v(:);
            return
        end
    end
end
end

function s = local_get_scalar(S, names)
s = [];
for i = 1:numel(names)
    if isfield(S, names{i})
        x = S.(names{i});
        if ~isempty(x)
            s = x(1);
            return
        end
    end
end
end
