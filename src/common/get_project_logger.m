function logger = get_project_logger()
%GET_PROJECT_LOGGER Return the global project logger if initialized.

    if isappdata(0, 'PROJECT_LOGGER')
        logger = getappdata(0, 'PROJECT_LOGGER');
    else
        logger = [];
    end
end
