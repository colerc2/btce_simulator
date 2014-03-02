function [total_profit, slope] = calc_profit(change_in_future, sell_delta, max_outliers)
    [sell_delta ix] = sort(sell_delta, 'descend');
    change_in_future = change_in_future(ix);
    
    total_profit = 0;
    total_outliers = 0;
    slope = 0;
    count = 0;
    for ii = 1:length(ix)
        if(change_in_future(ii) < -.01)
           total_profit = total_profit + change_in_future(ii);
           count = count + 1;
        else
            if(total_outliers < max_outliers)
                total_outliers = total_outliers + 1;
                total_profit = total_profit + change_in_future(ii);
            else
                slope = sell_delta(ii-1);
                break;
            end
        end
    end
    %profit per sale
    %total_profit = total_profit/count;
end