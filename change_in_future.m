function [change_in_future] = change_in_future(data, time_period)
    change_in_future.low = zeros(length(data)-time_period,1);
    change_in_future.high = zeros(length(data)-time_period,1);
    for ii  = 1:(length(data)-time_period)
        indices = ii+1:ii+time_period;
        changes = (data(indices)-data(ii))/data(ii);
        change_in_future.high(ii) = max(changes);
        change_in_future.low(ii) = min(changes);
        %= [max(changes) min(changes)];
    end
end