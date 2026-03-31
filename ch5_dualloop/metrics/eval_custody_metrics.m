function custody = eval_custody_metrics(result)
%EVAL_CUSTODY_METRICS  Evaluate minimal custody metrics for chapter 5 shell.

assert(isfield(result, 'time'), 'Result must contain field: time');
assert(isfield(result, 'phi_series'), 'Result must contain field: phi_series');

t = result.time(:);
phi = result.phi_series(:);

threshold = 1.0;
is_out = (phi < threshold);

custody = struct();
custody.time = t;
custody.phi_series = phi;
custody.threshold = threshold;

custody.q_worst = min(phi);
custody.phi_mean = mean(phi);
custody.outage_ratio = mean(is_out);

% Longest consecutive outage length in samples.
max_run = 0;
run_len = 0;
for k = 1:numel(is_out)
    if is_out(k)
        run_len = run_len + 1;
        if run_len > max_run
            max_run = run_len;
        end
    else
        run_len = 0;
    end
end
custody.longest_outage_steps = max_run;

% Minimal SC/DC/LoC occupancy by threshold partition.
state_sc = phi >= 1.0;
state_dc = (phi >= 0.5) & (phi < 1.0);
state_loc = phi < 0.5;

custody.sc_ratio = mean(state_sc);
custody.dc_ratio = mean(state_dc);
custody.loc_ratio = mean(state_loc);
end
