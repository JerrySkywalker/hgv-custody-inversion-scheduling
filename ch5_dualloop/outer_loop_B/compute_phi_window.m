function phi = compute_phi_window(mg, ttl, switch_indicator, cfg)
%COMPUTE_PHI_WINDOW  Minimal custody performance proxy.
%
% phi = min(mg, normalized_ttl) - switch_penalty * switch_indicator

if nargin < 4 || isempty(cfg)
    cfg = default_ch5_params();
end

W = cfg.ch5.window_steps;
penalty = cfg.ch5.custody_switch_penalty;

ttl_norm = ttl(:) / W;
ttl_norm = max(0, min(1, ttl_norm));

phi = min(mg(:), ttl_norm) - penalty * switch_indicator(:);
phi = max(0, phi);
end
