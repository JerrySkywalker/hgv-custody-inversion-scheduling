function wininfo = eval_window_information(ch5case, selection_trace)
%EVAL_WINDOW_INFORMATION
% Evaluate rolling-window information using selected real double-satellite pairs.

if nargin < 2 || isempty(selection_trace)
    error('selection_trace is required for real R4 evaluation.');
end

Nt = numel(ch5case.t_s);
L = ch5case.window.length_steps;

J_series = zeros(3,3,Nt);
for k = 1:Nt
    J_series(:,:,k) = selection_trace{k}.J_pair;
end

J_window = zeros(3,3,Nt);
lambda_min = nan(Nt,1);
window_start_idx = nan(Nt,1);
window_end_idx = nan(Nt,1);

for k = 1:Nt
    s0 = max(1, k - L + 1);
    s1 = k;

    Jw = zeros(3,3);
    for j = s0:s1
        Jw = Jw + J_series(:,:,j);
    end

    Jw = 0.5 * (Jw + Jw.');
    J_window(:,:,k) = Jw;
    lambda_min(k) = min(eig(Jw));
    window_start_idx(k) = s0;
    window_end_idx(k) = s1;
end

wininfo = struct();
wininfo.t_s = ch5case.t_s(:);
wininfo.J_series = J_series;
wininfo.J_window = J_window;
wininfo.lambda_min = lambda_min;
wininfo.window_start_idx = window_start_idx;
wininfo.window_end_idx = window_end_idx;
wininfo.window_length_steps = L;
wininfo.window_length_s = ch5case.window.length_s;
end
