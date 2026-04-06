function cfg = default_ch5r_r10_params()
%DEFAULT_CH5R_R10_PARAMS
% R10 Phase A:
% - same inner loop shell as R9
% - Li-style interval relay scheduling backend

cfg = default_ch5r_r9_params();

cfg.ch5r.r10 = struct();

% Li-style fixed relay interval
cfg.ch5r.r10.interval_steps = 30;

% coarse selection threshold:
% prefer pairs visible in the whole interval; if none, allow fallback by support ratio
cfg.ch5r.r10.min_support_ratio = 0.5;

% numerical stabilization for logdet
cfg.ch5r.r10.det_eps = 1e-9;

% logging / outputs
cfg.ch5r.r10.log = struct();
cfg.ch5r.r10.log.enable = true;
cfg.ch5r.r10.log.log_every = 1;   % interval-level logging
cfg.ch5r.r10.save_outputs = true;
end
