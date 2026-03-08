function fig = plot_window_margin_stage04(summary_margin, cfg)
    %PLOT_WINDOW_MARGIN_STAGE04
    % Thesis-friendly Stage04.2 margin visualization.
    %
    % New design:
    %   left  : family-level pass_ratio bar chart
    %   right : heading-offset pass_ratio bar chart (discrete categories)
    %
    % This avoids implying continuity across heading offsets.
    
        fig = figure('Color', 'w', 'Position', [100,100,1180,440]);
    
        % ============================================================
        % subplot 1: family-level pass ratio
        % ============================================================
        subplot(1,2,1); hold on; grid on;
    
        Tfam = summary_margin.family_summary;
        family_order = ["nominal","heading","critical"];
        pass_vals = nan(size(family_order));
    
        for i = 1:numel(family_order)
            idx = strcmp(string(Tfam.group_value), family_order(i));
            if any(idx)
                pass_vals(i) = Tfam.pass_ratio(find(idx,1,'first'));
            end
        end
    
        bar(1:numel(family_order), pass_vals);
        ylim([0, 1.0]);
        set(gca, 'XTick', 1:numel(family_order), 'XTickLabel', cellstr(family_order));
        ylabel('pass ratio', 'Interpreter', 'none');
        title('Stage04.2 family-level pass ratio', 'Interpreter', 'none');
    
        for i = 1:numel(pass_vals)
            if ~isnan(pass_vals(i))
                text(i, min(pass_vals(i)+0.03, 0.98), sprintf('%.2f', pass_vals(i)), ...
                    'HorizontalAlignment', 'center', 'Interpreter', 'none');
            end
        end
    
        % ============================================================
        % subplot 2: heading-offset pass ratio
        % ============================================================
        subplot(1,2,2); hold on; grid on;
    
        Thead = summary_margin.heading_summary;
        if isempty(Thead)
            text(0.5, 0.5, 'No heading summary available', ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
            axis off;
            return;
        end
    
        offsets = Thead.group_value;
        pass_ratio = Thead.pass_ratio;
    
        % ensure numeric sort
        [offsets_sorted, idx_sort] = sort(offsets(:));
        pass_ratio_sorted = pass_ratio(idx_sort);
    
        x = 1:numel(offsets_sorted);
        bar(x, pass_ratio_sorted);
        ylim([0, 1.0]);
    
        xticklabels_cell = arrayfun(@(v) sprintf('%d', v), offsets_sorted, 'UniformOutput', false);
        set(gca, 'XTick', x, 'XTickLabel', xticklabels_cell);
    
        xlabel('heading offset (deg)', 'Interpreter', 'none');
        ylabel('pass ratio', 'Interpreter', 'none');
        title('Stage04.2 heading-offset pass ratio', 'Interpreter', 'none');
    
        for i = 1:numel(pass_ratio_sorted)
            text(x(i), min(pass_ratio_sorted(i)+0.03, 0.98), sprintf('%.2f', pass_ratio_sorted(i)), ...
                'HorizontalAlignment', 'center', 'Interpreter', 'none');
        end
    end