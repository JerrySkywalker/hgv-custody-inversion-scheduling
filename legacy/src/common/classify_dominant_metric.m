function dominant_metric = classify_dominant_metric(DG_worst, DA_worst, DT_worst)
%CLASSIFY_DOMINANT_METRIC Classify dominant metric using standardized closure margins.

values = [DG_worst, DA_worst, DT_worst];
labels = ["DG", "DA", "DT"];

if any(~isfinite(values))
    dominant_metric = "unavailable";
    return;
end

[~, idx] = min(values);
dominant_metric = labels(idx);
end
