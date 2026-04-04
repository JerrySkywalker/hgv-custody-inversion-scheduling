function fs = package_filter_state(x_plus, P_plus)
%PACKAGE_FILTER_STATE Create a filter state container.

x_plus = x_plus(:);
nx = numel(x_plus);

assert(all(size(P_plus) == [nx nx]), 'P_plus size mismatch.');

fs = struct();
fs.x_plus = x_plus;
fs.P_plus = P_plus;
end
