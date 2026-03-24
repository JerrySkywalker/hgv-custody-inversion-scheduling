function out = pack_framework_snapshot_head_code()
opts = struct();
opts.snapshot_name = 'framework_snapshot_head_code';
opts.scope = 'head';
opts.code_only = true;
opts.include_outputs = false;
opts.include_chapter5 = false;
opts.include_legacy = false;

out = pack_framework_snapshot_core(opts);
end
