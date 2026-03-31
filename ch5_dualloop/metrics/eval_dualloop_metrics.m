function stats = eval_dualloop_metrics(outerA)
%EVAL_DUALLOOP_METRICS  Evaluate standalone outerA evidence metrics.

t = outerA.time(:);
state = outerA.risk_state(:);
quad = outerA.risk_quadrant(:);
lead = outerA.lead_time_steps(:);

stats = struct();
stats.time = t;

stats.safe_ratio = mean(state == 0);
stats.warn_ratio = mean(state == 1);
stats.trigger_ratio = mean(state == 2);

stats.q1_ratio = mean(quad == 1);
stats.q2_ratio = mean(quad == 2);
stats.q3_ratio = mean(quad == 3);
stats.q4_ratio = mean(quad == 4);

is_trigger = (state == 2);
stats.trigger_count = sum(diff([0; is_trigger]) == 1);

lead_valid = lead(lead > 0);
if isempty(lead_valid)
    stats.mean_lead_time_steps = 0;
    stats.max_lead_time_steps = 0;
else
    stats.mean_lead_time_steps = mean(lead_valid);
    stats.max_lead_time_steps = max(lead_valid);
end
end
