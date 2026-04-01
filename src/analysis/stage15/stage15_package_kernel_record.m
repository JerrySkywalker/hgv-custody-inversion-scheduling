function rec = stage15_package_kernel_record(box, xi, kernel_type, kernel_struct)
%STAGE15_PACKAGE_KERNEL_RECORD  Package one local-kernel record.

rec = struct();
rec.box = box;
rec.xi = xi;
rec.kernel_type = kernel_type;
rec.kernel = kernel_struct;
end
