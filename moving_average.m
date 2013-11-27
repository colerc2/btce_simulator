function [maf] = moving_average(data, order)
    maf = zeros(1,length(data));
    for ii  = 1:length(data)
        indices = max(1,ii-order+1):ii;
        maf(ii) = sum(data(indices))/length(indices);
    end
end