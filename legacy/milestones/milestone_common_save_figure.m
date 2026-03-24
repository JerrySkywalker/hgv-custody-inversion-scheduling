function file_path = milestone_common_save_figure(fig, file_path)
%MILESTONE_COMMON_SAVE_FIGURE Save milestone figure if handle is valid.

if isempty(fig) || ~ishandle(fig)
    file_path = "";
    return;
end

exportgraphics(fig, file_path, 'Resolution', 180);
end
