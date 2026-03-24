function ensure_dir(dir_path)
%ENSURE_DIR Create directory if it does not exist.

    if ~exist(dir_path, 'dir')
        mkdir(dir_path);
    end
end