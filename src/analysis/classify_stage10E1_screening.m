function scan_table_e1 = classify_stage10E1_screening(scan_table, cfg)
%CLASSIFY_STAGE10E1_SCREENING
% Apply refined screening rule to Stage10.E scan table.
%
% New rule:
%   reject    : zero_pass == false
%   safe_pass : zero_pass == true  && bcirc_pass == true
%   warn_pass : zero_pass == true  && bcirc_pass == false
%
% Additional helper flags:
%   pred_accept      = safe_pass OR warn_pass
%   pred_accept_safe = safe_pass only
%   need_refine      = warn_pass

    cfg = stage10E1_prepare_cfg(cfg);

    n = height(scan_table);

    stage_label = strings(n,1);
    pred_accept = false(n,1);
    pred_accept_safe = false(n,1);
    need_refine = false(n,1);

    for i = 1:n
        zp = logical(scan_table.zero_pass(i));
        bp = logical(scan_table.bcirc_pass(i));

        if ~zp
            stage_label(i) = "reject";
            pred_accept(i) = false;
            pred_accept_safe(i) = false;
            need_refine(i) = false;
        else
            if bp
                stage_label(i) = "safe_pass";
                pred_accept(i) = true;
                pred_accept_safe(i) = true;
                need_refine(i) = false;
            else
                stage_label(i) = "warn_pass";
                pred_accept(i) = true;
                pred_accept_safe(i) = false;
                need_refine(i) = true;
            end
        end
    end

    scan_table_e1 = scan_table;
    scan_table_e1.stage_label = stage_label;
    scan_table_e1.pred_accept = pred_accept;
    scan_table_e1.pred_accept_safe = pred_accept_safe;
    scan_table_e1.need_refine = need_refine;
end