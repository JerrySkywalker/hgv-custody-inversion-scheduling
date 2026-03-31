function inner = run_inner_loop_filter(caseData, cfg)
%RUN_INNER_LOOP_FILTER  Minimal inner-loop estimator for phase 2.
%
% This is a lightweight shell implementation for fast CICD:
% - constant-velocity-like pseudo estimator
% - synthetic innovation covariance
% - NIS available for later outer-loop use

t = caseData.time.t;
N = numel(t);
dt = caseData.time.dt;

x_true = zeros(N, 6);
x_est  = zeros(N, 6);

% Build simple truth from phase1 placeholder truth.
x_true(:, 1) = caseData.truth.x;
x_true(:, 2) = caseData.truth.y;
x_true(:, 3) = caseData.truth.z;
x_true(1:end-1, 4) = diff(x_true(:, 1)) / dt;
x_true(1:end-1, 5) = diff(x_true(:, 2)) / dt;
x_true(1:end-1, 6) = diff(x_true(:, 3)) / dt;
x_true(end, 4:6) = x_true(end-1, 4:6);

% Initial estimate with small offset.
x_est(1, :) = x_true(1, :) + [8, -6, 5, 0.2, -0.1, 0.1];

P_series = zeros(6, 6, N);
innovations = zeros(N, 2);
S_series = zeros(2, 2, N);

P = diag([25, 25, 25, 1, 1, 1]);

for k = 1:N
    if k > 1
        % Simple prediction
        x_pred = x_est(k-1, :);
        x_pred(1:3) = x_pred(1:3) + dt * x_pred(4:6);

        % Simple correction toward truth with time-varying gain
        alpha = 0.18 + 0.04 * sin(k / 35);
        x_est(k, :) = x_pred + alpha * (x_true(k, :) - x_pred);
    end

    % Synthetic 2D innovation for NIS demonstration
    innovations(k, 1) = 0.35 * sin(k / 17) + 0.15 * exp(-((k - 320)/35)^2);
    innovations(k, 2) = 0.28 * cos(k / 23) + 0.10 * exp(-((k - 120)/25)^2);

    s11 = 0.18 + 0.03 * abs(sin(k / 41));
    s22 = 0.16 + 0.04 * abs(cos(k / 29));
    S = [s11, 0.01; 0.01, s22];
    S_series(:, :, k) = S;

    % Shrinking covariance shell
    P = 0.985 * P + 0.002 * eye(6);
    P_series(:, :, k) = P;
end

nis = compute_nis_series(innovations, S_series);
inner = package_inner_loop_state(t, x_true, x_est, P_series, innovations, S_series, nis);
end
