function ensure_dir(dir_path)
%ENSURE_DIR Create a directory when it does not already exist.
% Input:
%   dir_path : target directory path

if ~exist(dir_path, 'dir')
    mkdir(dir_path);
end
end
