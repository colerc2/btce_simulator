function [macd, macd_line, signal_line] = moving_average_convergence_divergence(data,short, long, signal, delta_t)
    short_emaf = exponential_moving_average(data,(2/((short+1)*delta_t)));
    long_emaf = exponential_moving_average(data,(2/((long+1)*delta_t)));
    macd_line = short_emaf - long_emaf;
    signal_line = exponential_moving_average(macd_line,(2/((signal+1)*delta_t)));
    macd = macd_line - signal_line;
end