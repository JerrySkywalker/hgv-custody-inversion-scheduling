function save_struct_safe(file_path, S)
    %SAVE_STRUCT_SAFE Save struct safely to .mat file.
    %
    % Usage:
    %   save_struct_safe('xxx.mat', result_struct)
    
        if ~isstruct(S)
            error('Input S must be a struct.');
        end
    
        [save_dir, ~, ~] = fileparts(file_path);
        ensure_dir(save_dir);
    
        save(file_path, '-struct', 'S', '-v7.3');
    end