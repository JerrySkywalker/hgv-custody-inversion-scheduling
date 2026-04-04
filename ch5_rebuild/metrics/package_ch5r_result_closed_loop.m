function out = package_ch5r_result_closed_loop(name, bubble_metrics, req_metrics, rmse_metrics, cost_metrics)
%PACKAGE_CH5R_RESULT_CLOSED_LOOP Package compare-ready result bundle.

out = struct();
out.name = name;
out.bubble = bubble_metrics;
out.requirement = req_metrics;
out.rmse = rmse_metrics;
out.cost = cost_metrics;
end
