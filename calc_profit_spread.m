function [total_profit, slope, count, per_sale] = calc_profit_spread(change_in_future, sell_spread, max_outliers)
    [sell_spread ix] = sort(sell_spread, 'descend');
    change_in_future = change_in_future(ix);
    
    total_profit = 0;
    total_outliers = 0;
    slope = 0;
    count = 0;
    for ii = 1:length(ix)
        if(change_in_future(ii) < -.04)
           total_profit = total_profit + change_in_future(ii);
           count = count + 1;
        else
%             if(total_outliers < max_outliers)
%                 total_outliers = total_outliers + 1;
%                 total_profit = total_profit + change_in_future(ii);
%             else
                if(ii == 1)
                    slope = 0;
                else
                    slope = sell_spread(ii-1);
                end
                break;
%             end
        end
    end
    if(count == 0)
       count = -1; 
    end
    per_sale = total_profit/count;
    %profit per sale
    %total_profit = total_profit/count;
end