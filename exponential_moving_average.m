function [maf] = exponential_moving_average(data, alpha)
    maf = zeros(1,length(data));
    %alpha should be between zero and 1, higher alpha discounts older
    %observations faster
    for ii  = 1:length(data)
        if(ii == 1)
           maf(ii) = data(ii);
        else
           maf(ii) = alpha*data(ii) + (1-alpha)*maf(ii-1);
        end
    end
end