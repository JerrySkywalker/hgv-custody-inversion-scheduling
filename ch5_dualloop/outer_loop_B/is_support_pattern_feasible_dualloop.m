function [is_ok, reason] = is_support_pattern_feasible_dualloop(mode, detail, cfg)
%IS_SUPPORT_PATTERN_FEASIBLE_DUALLOOP
% Hard feasibility gate for warn/trigger custody protection.

is_ok = true;
reason = "safe-default";

switch mode
    case 'safe'
        return

    case 'warn'
        if detail.zero_support_ratio > cfg.ch5.ck_gate_warn_max_zero_ratio
            is_ok = false;
            reason = "warn-zero-ratio";
            return
        end
        if detail.longest_zero_support_steps > cfg.ch5.ck_gate_warn_max_longest_zero
            is_ok = false;
            reason = "warn-longest-zero";
            return
        end
        if detail.longest_single_support_steps > cfg.ch5.ck_gate_warn_max_longest_single
            is_ok = false;
            reason = "warn-longest-single";
            return
        end

    otherwise
        if detail.zero_support_ratio > cfg.ch5.ck_gate_trigger_max_zero_ratio
            is_ok = false;
            reason = "trigger-zero-ratio";
            return
        end
        if detail.longest_zero_support_steps > cfg.ch5.ck_gate_trigger_max_longest_zero
            is_ok = false;
            reason = "trigger-longest-zero";
            return
        end
        if detail.longest_single_support_steps > cfg.ch5.ck_gate_trigger_max_longest_single
            is_ok = false;
            reason = "trigger-longest-single";
            return
        end
end
end
