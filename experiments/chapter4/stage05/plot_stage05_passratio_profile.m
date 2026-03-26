function fig = plot_stage05_passratio_profile(prod, varargin)
%PLOT_STAGE05_PASSRATIO_PROFILE Plot strict Stage05 pass-ratio family from standardized product.
%
% Input product fields:
%   prod.i_list
%   prod.ns_list
%   prod.value_matrix   (size = numel(i_list) x numel(ns_list))

p = inputParser;
addParameter(p, 'visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'title', 'Stage05 pass-ratio profile versus Ns', @(x) ischar(x) || isstring(x));
addParameter(p, 'x_label', 'Ns', @(x) ischar(x) || isstring(x));
addParameter(p, 'y_label', 'best pass ratio', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});
args = p.Results;

fig = figure('Visible', char(string(args.visible)));
hold on;

i_list = prod.i_list(:)';
ns_list = prod.ns_list(:)';
V = prod.value_matrix;

for ii = 1:numel(i_list)
    plot(ns_list, V(ii, :), '-o', 'DisplayName', sprintf('i=%d°', i_list(ii)));
end

grid on;
xlabel(char(string(args.x_label)));
ylabel(char(string(args.y_label)));
title(char(string(args.title)));
ylim([0, 1.05]);
legend('Location', 'eastoutside');
end
