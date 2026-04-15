function [tracking, replay] = ch5r_compute_true_rmse_replay(phase_name, out_phase, save_outputs, log_enable)
%CH5R_COMPUTE_TRUE_RMSE_REPLAY
% Use Koopman replay to compute true RMSE for phases that do not run an inner loop online.
%
% Output tracking fields align with R9/R10 style:
%   rmse_pos_km_series
%   mean_rmse_pos_km
%   final_rmse_pos_km
%   xhat_hist
%   xpred_hist
%   P_hist
%   replay_mat_file

if nargin < 3 || isempty(save_outputs)
    save_outputs = true;
end
if nargin < 4 || isempty(log_enable)
    log_enable = false;
end

replay = ch5r_run_selection_replay_koopman(phase_name, out_phase, save_outputs, log_enable);

tracking = struct();
tracking.rmse_pos_km_series = replay.rmse_pos_km(:);
tracking.mean_rmse_pos_km = sqrt(mean(replay.rmse_pos_km.^2, 'omitnan'));
tracking.final_rmse_pos_km = replay.rmse_pos_km(end);
tracking.xhat_hist = replay.xhat_hist;
tracking.xpred_hist = replay.xpred_hist;
tracking.P_hist = replay.P_hist;
tracking.replay_mat_file = replay.paths.mat_file;
end
