function [maf] = weighted_moving_average(data, order)
    maf = zeros(1,length(data));
    for ii  = 1:length(data)
        indices = max(1,ii-order+1):ii;
        weights = 1:length(indices);
        
        maf(ii) = sum(data(indices).*weights)/(sum(weights));
    end
end