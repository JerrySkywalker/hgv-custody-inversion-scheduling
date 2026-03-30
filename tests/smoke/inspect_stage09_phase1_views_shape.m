function inspect_stage09_phase1_views_shape()
%INSPECT_STAGE09_PHASE1_VIEWS_SHAPE
% Lightweight structural probe for Phase1-B outputs.

    clear functions;
    rehash;
    startup;

    base = manual_smoke_stage09_phase1_metric_views();

    fprintf('\n===== top-level =====\n');
    disp(fieldnames(base));

    fprintf('\n===== views =====\n');
    disp(class(base.views));
    if isstruct(base.views)
        disp(fieldnames(base.views));
    end

    fprintf('\n===== views.DG =====\n');
    disp(class(base.views.DG));
    if isstruct(base.views.DG)
        disp(fieldnames(base.views.DG));
    elseif istable(base.views.DG)
        disp(base.views.DG(1:min(5,height(base.views.DG)), :));
    end

    fprintf('\n===== views.DA =====\n');
    disp(class(base.views.DA));
    if isstruct(base.views.DA)
        disp(fieldnames(base.views.DA));
    elseif istable(base.views.DA)
        disp(base.views.DA(1:min(5,height(base.views.DA)), :));
    end

    fprintf('\n===== views.DT =====\n');
    disp(class(base.views.DT));
    if isstruct(base.views.DT)
        disp(fieldnames(base.views.DT));
    elseif istable(base.views.DT)
        disp(base.views.DT(1:min(5,height(base.views.DT)), :));
    end

    fprintf('\n===== frontiers =====\n');
    disp(class(base.frontiers));
    if isstruct(base.frontiers)
        disp(fieldnames(base.frontiers));
    end

    fprintf('\n===== frontiers.DA =====\n');
    disp(class(base.frontiers.DA));
    if isstruct(base.frontiers.DA)
        disp(fieldnames(base.frontiers.DA));
    elseif istable(base.frontiers.DA)
        disp(base.frontiers.DA(1:min(5,height(base.frontiers.DA)), :));
    end
end
