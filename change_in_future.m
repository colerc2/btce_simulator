function [change_in_future] = change_in_future(data, time_period)
    change_in_future = zeros(length(data)-time_period,2);
    for ii  = 1:(length(data)-time_period)
        indices = ii+1:ii+time_period;
        changes = data(indices)-data(ii);
        change_in_future(ii,:) = [max(changes) min(changes)];
    end
end