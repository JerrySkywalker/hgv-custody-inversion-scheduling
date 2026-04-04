function out = eval_window_information(ch5case)
%EVAL_WINDOW_INFORMATION  Evaluate rolling-window information matrices.

if nargin < 1 || isempty(ch5case)
    error('ch5case is required.');
end

time_s = ch5case.time_s;
Y_series = ch5case.info_series;
L = ch5case.window.length_steps;

N = numel(time_s);
n = size(Y_series, 1);

Y_window = zeros(n, n, N);
lambda_min = nan(N, 1);
window_start_idx = nan(N, 1);
window_end_idx = nan(N, 1);

for k = 1:N
    s0 = max(1, k - L + 1);
    s1 = k;

    Yw = zeros(n, n);
    for j = s0:s1
        Yw = Yw + Y_series(:,:,j);
    end

    Yw = 0.5 * (Yw + Yw.');
    Y_window(:,:,k) = Yw;
    lambda_min(k) = min(eig(Yw));
    window_start_idx(k) = s0;
    window_end_idx(k) = s1;
end

out = struct();
out.time_s = time_s;
out.Y_window = Y_window;
out.lambda_min = lambda_min;
out.window_start_idx = window_start_idx;
out.window_end_idx = window_end_idx;
out.window_length_steps = L;
out.window_length_s = ch5case.window.length_s;
end
