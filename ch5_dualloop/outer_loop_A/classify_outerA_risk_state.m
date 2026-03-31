function [risk_state, risk_quadrant] = classify_outerA_risk_state(mr_tilde_now, omega_now, cfg)
%CLASSIFY_OUTERA_RISK_STATE  Classify outerA risk state and quadrant.
%
% risk_state:
%   0 = safe
%   1 = warn
%   2 = trigger
%
% risk_quadrant:
%   1 = low risk / low growth
%   2 = low risk / high growth
%   3 = high risk / low growth
%   4 = high risk / high growth

warn_th = cfg.ch5.outerA_warn_threshold;
trig_th = cfg.ch5.outerA_trigger_threshold;
omega_warn = cfg.ch5.outerA_omega_warn_threshold;
omega_trig = cfg.ch5.outerA_omega_trigger_threshold;

high_risk = mr_tilde_now >= warn_th;
high_growth = omega_now >= omega_warn;

if ~high_risk && ~high_growth
    risk_quadrant = 1;
elseif ~high_risk && high_growth
    risk_quadrant = 2;
elseif high_risk && ~high_growth
    risk_quadrant = 3;
else
    risk_quadrant = 4;
end

if mr_tilde_now >= trig_th || omega_now >= omega_trig
    risk_state = 2;
elseif mr_tilde_now >= warn_th || omega_now >= omega_warn
    risk_state = 1;
else
    risk_state = 0;
end
end
