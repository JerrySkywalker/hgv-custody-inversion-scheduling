function inner = package_inner_loop_state(t, x_true, x_est, P_series, innovations, S_series, nis)
%PACKAGE_INNER_LOOP_STATE  Package minimal inner-loop outputs.

inner = struct();
inner.time = t(:);
inner.x_true = x_true;
inner.x_est = x_est;
inner.P_series = P_series;
inner.innovations = innovations;
inner.S_series = S_series;
inner.nis = nis(:);

err = x_est(:, 1:3) - x_true(:, 1:3);
inner.pos_err_norm = sqrt(sum(err.^2, 2));

inner.mean_nis = mean(inner.nis);
inner.max_nis = max(inner.nis);
inner.mean_pos_err = mean(inner.pos_err_norm);
inner.max_pos_err = max(inner.pos_err_norm);
end
