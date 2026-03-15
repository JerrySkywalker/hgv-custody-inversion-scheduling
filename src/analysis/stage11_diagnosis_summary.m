function [summary_table, failure_table, lines] = stage11_diagnosis_summary(out, cfg)
%STAGE11_DIAGNOSIS_SUMMARY Build compact Stage11 coverage diagnosis summaries.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = out.window_table;
    CT = out.case_table;

    total_windows = height(WT);
    valid_windows = sum(WT.new_valid);
    valid_ratio = valid_windows / max(total_windows, 1);

    reason_order = ["ok", "reference_gap", "weak_invalid", "sub_invalid", "all_bounds_invalid", "numerical_issue"];
    counts = zeros(numel(reason_order), 1);
    for i = 1:numel(reason_order)
        counts(i) = sum(string(WT.new_failure_reason) == reason_order(i));
    end
    ratios = counts / max(total_windows, 1);
    failure_table = table(reason_order.', counts, ratios, ...
        'VariableNames', {'failure_reason', 'count', 'ratio'});

    total_cases = height(CT);
    all_valid_cases = sum(CT.all_valid_new);
    partial_valid_cases = sum(CT.n_window_valid_new > 0 & ~CT.all_valid_new);
    zero_valid_cases = sum(CT.n_window_valid_new == 0);
    safe_cases = sum(CT.new_case_label == "safe_pass");
    warn_cases = sum(CT.new_case_label == "warn_pass");
    reject_cases = sum(CT.new_case_label == "reject");

    mean_reference_match_ratio = mean(WT.reference_match_ratio, 'omitnan');
    mean_supported_ratio = mean(WT.supported_ratio, 'omitnan');
    summary_table = table(total_windows, valid_windows, valid_ratio, total_cases, ...
        all_valid_cases, partial_valid_cases, zero_valid_cases, ...
        safe_cases, warn_cases, reject_cases, mean_reference_match_ratio, mean_supported_ratio, ...
        'VariableNames', {'total_windows', 'valid_windows', 'valid_ratio', ...
        'total_cases', 'all_valid_cases', 'partial_valid_cases', 'zero_valid_cases', ...
        'safe_cases', 'warn_cases', 'reject_cases', 'mean_reference_match_ratio', 'mean_supported_ratio'});

    lines = strings(0,1);
    lines(end+1,1) = "[Stage11 Diagnosis]"; %#ok<AGROW>
    lines(end+1,1) = sprintf('Total windows: %d', total_windows); %#ok<AGROW>
    lines(end+1,1) = sprintf('Valid new windows: %d (%.1f%%)', valid_windows, 100 * valid_ratio); %#ok<AGROW>
    lines(end+1,1) = sprintf('Mean reference match ratio: %.3f | mean supported ratio: %.3f', ...
        mean_reference_match_ratio, mean_supported_ratio); %#ok<AGROW>
    lines(end+1,1) = sprintf('Total cases: %d | all-valid: %d | partial-valid: %d | zero-valid: %d', ...
        total_cases, all_valid_cases, partial_valid_cases, zero_valid_cases); %#ok<AGROW>
    lines(end+1,1) = sprintf('Case labels: safe=%d warn=%d reject=%d', safe_cases, warn_cases, reject_cases); %#ok<AGROW>
    lines(end+1,1) = "Failure breakdown:"; %#ok<AGROW>
    for i = 2:numel(reason_order)
        lines(end+1,1) = sprintf('  %s: %d (%.1f%%)', reason_order(i), counts(i), 100 * ratios(i)); %#ok<AGROW>
    end
end
