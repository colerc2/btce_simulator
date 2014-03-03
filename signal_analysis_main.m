%signal analysis, gotta look for some correlations between indicator values
%and change in prices

clear all; close all; clc;

%runtime params
data_file_path = 'data\';
data_file_name = 'btc_usd_depth';
data_file_name = 'btc_usd_depth_nov_24_dec_18';
data_file_extension = '.csv';
load_from_mat = 1; %if you've loaded this file before, set this to 1
pair = 'btc_usd';
sliding_window_width = 5000;%seconds
plot_every_n_seconds = 100;
simulation_speed = 0;%1 is as fast as possible(gg cpu), 0 is real time(lame):TODO
btc_fee = .002;
window_length = 1; %minute(TODO, see above), for financial analysis stuff, maf, emaf, macd, etc.

%constants defined that help access certain parameters in data
high = 1; low = 2; avg = 3; vol = 4; vol_cur = 5; last = 6; buy = 7;
sell = 8; updated = 9; server_time = 10;

%read in data from csv file, save as .mat so it's faster next time, it
%takes a reaaaalllly long time the first time, mostly due to processing the
%damn dates, TODO:try to speed date conversion up
fprintf('Loading...');
if(load_from_mat)
    load([data_file_name '.mat']);
else
    btce_data_cell = read_btce_csv([data_file_path data_file_name data_file_extension], 0.35);
    btce_data.high = [btce_data_cell{:,high}];
    btce_data.low = [btce_data_cell{:,low}];
    btce_data.avg = [btce_data_cell{:,avg}];
    btce_data.vol = [btce_data_cell{:,vol}];
    btce_data.vol_cur = [btce_data_cell{:,vol_cur}];
    btce_data.last = [btce_data_cell{:,last}];
    btce_data.buy = [btce_data_cell{:,buy}];
    btce_data.sell = [btce_data_cell{:,sell}];
    btce_data.updated = [btce_data_cell{:,updated}];
    btce_data.server_time = [btce_data_cell{:,server_time}];
    clear btce_data_cell;
    
    save([data_file_name '.mat'], 'btce_data');
end
fprintf('done!\n');

%plot time updated vs sample
% figure;
% plot(btce_data.updated);
% change_in_future_360 = change_in_future(btce_data.last,360);
% change_in_future_720 = change_in_future(btce_data.last,720);
% change_in_future_1440 = change_in_future(btce_data.last,1440);
change_in_future_2880 = change_in_future(btce_data.last,2880);
% change_360_colors = change_color(change_in_future_360, -.005);
% change_720_colors = change_color(change_in_future_720, -.005);
% change_1440_colors = change_color(change_in_future_1440, -.005);
change_2880_colors = change_color(change_in_future_2880, -.005);
count = 0;
gain = {};

% short = 4:1:15;
% long = 16:1:32;
% sig = 5:1:18;
% period = 5:5:200;
% macd_window = 10:10:100;

short = 12;
long = 26;
sig = 9;
period = 25:25:250;
macd_window = 30;

 %matlabpool(4);
 %parfor ii = 1:length(short)
for ii = 1:length(short)
    for jj = 1:length(long)
        for kk = 1:length(sig)
            for ll = 1:length(period)
                for oo = 1:length(macd_window)
                    [macd, macd_line, signal_line] = ...
                        moving_average_convergence_divergence(btce_data.last,...
                        short(ii), long(jj), sig(kk), period(ll));%12 26
                    delta_macd = [0 (macd(2:end)-macd(1:end-1))];
                    
                    threshold = 0;
                    positive = 1;
                    count_since_switch = 0;
                    sell_price = [];
                    sell_time = [];
                    sell_delta = [];
                    sell_change = [];
                    sell_index = [];
                    buy_price = [];
                    buy_time = [];
                    max_since_switch = [];
                    min_since_switch = [];
                    sell_spread = [];
                    sell_ongoing = 0;
                    buy_holdout_timer = 0;
                    for mm = 1:length(macd)
                        if(positive)
                            if(macd(mm) > 0)
                                count_since_switch = count_since_switch + 1;
                            else
                                if(sell_ongoing)
                                    buy_price(end+1) = btce_data.last(mm);
                                    buy_time(end+1) = btce_data.updated(mm);
                                    sell_ongoing = 0;
                                end
                                count_since_switch = 0;
                                positive = 0;
                                max_since_switch = 0;
                                min_since_switch = 0;
                            end
                        else
                            if(macd(mm) < 0)
                                min_since_switch = min(min_since_switch,macd(mm));
                                count_since_switch = count_since_switch + 1;
                            else
                                if((count_since_switch > threshold))% &&...
%                                         (min(macd(max(1,mm-macd_window(oo)):mm))<-.2859))
                                    sell_price(end+1) = btce_data.last(mm);
                                    sell_time(end+1) = btce_data.updated(mm);
                                    if(mm > length(change_in_future_2880.low))
                                        sell_change(end+1) = 0;
                                    else
                                        sell_change(end+1) = change_in_future_2880.low(mm);
                                    end
                                    sell_delta(end+1) = delta_macd(mm);
                                    sell_index(end+1) = mm;
                                    sell_spread(end+1) = min(macd(max(1,mm-macd_window(oo)):mm));
                                    sell_ongoing = 1;
                                end
                                positive = 1;
                                count_since_switch = 0;
                                max_since_switch = 0;
                                min_since_switch = 0;
                            end
                        end
                    end
                    %%%%%%Scatter plot of delta_macd vs. change_in_future
                    fprintf('MACD(%d, %d, %d)x%d: %f\n',short(ii), long(jj), sig(kk),...
                        period(ll), (sell_price(1:length(buy_price))/buy_price));
                    figure(1);
                    scatter(sell_spread, sell_change); hold on;
                    %                 xlim([0 .15]); ylim([-.05 .005]);
                    %                 cutoff = -0.005+zeros(length(0:.005:.15),1);
                    %                 scatter(0:.005:.15,cutoff, 'r');
                    pause; hold off;
                    close all;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%Plot of price vs. time with sell points
%                     for nn = 1:length(sell_time)
%                         figure(2);
%                         subplot(2,1,1); hold on;
%                         plot(btce_data.updated,btce_data.last);
%                         scatter(sell_time(nn), sell_price(nn), 'g');
%                         [min_ ix_]= min(btce_data.last(sell_index(nn):sell_index(nn)+2880));
%                         scatter(btce_data.updated(ix_+sell_index(nn)),min_,'c');
%                         %scatter(buy_time, buy_price, 'r');
%                         legend('Price','Sells','Buys');
%                         
%                         subplot(2,1,2); hold on;
%                         plot(btce_data.updated,zeros(1,length(btce_data.updated)),'k');
%                         plot(btce_data.updated,macd,'k','LineWidth',2);
%                         plot(btce_data.updated,macd_line,'r','LineWidth',2);
%                         plot(btce_data.updated,signal_line,'c','LineWidth',2);
%                         legend('Zero','Difference','MACD','Signal');
%                         pause; hold off;
%                         close all;
%                     end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %[profit_number slope] = calc_profit(sell_change, sell_delta, 1);
                    [profit_number, spread_thresh, sell_count, per_sale] = ...
                        calc_profit_spread(sell_change, sell_spread, 1);
                    %gain_index = (ii-1)*length(short)*length(long)*length(sig)+...
                    gain_index = ((jj-1)*length(sig)*length(period)*length(macd_window))+...
                        ((kk-1)*length(period)*length(macd_window)) + ...
                        ((ll-1)*length(macd_window)) + oo;
                    gain{ii}{gain_index,1} = (sell_price(1:length(buy_price)))/buy_price;
                    gain{ii}{gain_index,2} = sprintf('MACD(%d, %d, %d)x%d,window: %d, %f\n',short(ii), long(jj), sig(kk),...
                        period(ll), macd_window(oo),(sell_price(1:length(buy_price))/buy_price));
                    gain{ii}{gain_index,3} = profit_number;
                    gain{ii}{gain_index,4} = spread_thresh;
                    gain{ii}{gain_index,5} = sell_count;
                    gain{ii}{gain_index,6} = per_sale;
                    count = count + 1;
                end
            end
        end
    end
end
%matlabpool close
%gain = [gain{1};gain{2};gain{3};gain{4};gain{5};gain{6}];
[sorted_, ix_] = sort([gain{:,3}]);
[gain{ix_(1:10),3}]
[gain{ix_(1:10),2}]
[gain{ix_(1:10),4}]

% subplot(2,1,1); hold on;
% plot(btce_data.updated,btce_data.last);
% scatter(sell_time, sell_price, 'r');
% scatter(buy_time, buy_p
% rice, 'g');
% legend('Price','Sells','Buys');
%
% subplot(2,1,2); hold on;
% plot(btce_data.updated,zeros(1,length(btce_data.updated)),'k');
% plot(btce_data.updated,macd,'k','LineWidth',2);
% plot(btce_data.updated,macd_line,'r','LineWidth',2);
% plot(btce_data.updated,signal_line,'c','LineWidth',2);
% legend('Zero','Difference','MACD','Signal');
% hold off;

% for period = 20:10:120
%    [macd, macd_line, signal_line] = ...
%        moving_average_convergence_divergence(btce_data.last,12,26,9,period);
%
%    subplot(2,1,1);
%    plot(btce_data.updated,btce_data.last);
%    subplot(2,1,2); hold on;
%    plot(btce_data.updated,zeros(1,length(btce_data.updated)),'k');
%    plot(btce_data.updated,macd,'k','LineWidth',2);
%    plot(btce_data.updated,macd_line,'r','LineWidth',2);
%    plot(btce_data.updated,signal_line,'c','LineWidth',2);
%    hold off;
%    pause;
% end

%
% analyze when MACD line is around 0, plot each of these points derivatives
% wrt price change over next x seconds
% change_in_future_360 = change_in_future(btce_data.last,360);
% change_in_future_720 = change_in_future(btce_data.last,720);
% change_in_future_1440 = change_in_future(btce_data.last,1440);
% change_in_future_2880 = change_in_future(btce_data.last,2880);
% change_360_colors = change_color(change_in_future_360, -.005);
% change_720_colors = change_color(change_in_future_720, -.005);
% change_1440_colors = change_color(change_in_future_1440, -.005);
% change_2880_colors = change_color(change_in_future_2880, -.005);
%
% macd = moving_average_convergence_divergence(btce_data.last,12,22,11,60);
%
% parpool(5);
% matlabpool('open',4);
% signal_vector = [];
% signal_name_vector = {};
% signal_count = 1;
% for period = 20:10:120
%     for sig = 12
%         macd = moving_average_convergence_divergence(btce_data.last,12,26,sig,period);
%         delta_macd = [0 (macd(2:end)-macd(1:end-1))];
%         emaf_005 = exponential_moving_average(btce_data.last,.005);
%         emaf_015 = exponential_moving_average(btce_data.last,.015);
%
%         signal_vector(signal_count,:) = macd;
%         signal_name_vector{end+1} = ['MACD(12,26,' num2str(sig) ') times ' num2str(period)];
%         signal_count = signal_count + 1;
%
%         signal_vector(signal_count,:) = delta_macd;
%         signal_name_vector{end+1} = ['Change in MACD(12,26,' num2str(sig) ') times ' num2str(period)];
%         signal_count = signal_count + 1;
%
%         signal_vector(signal_count,:) = emaf_005;
%         signal_name_vector{end+1} = ['EMAF(.005)'];
%         signal_count = signal_count + 1;
%
%         signal_vector(signal_count,:) = emaf_015;
%         signal_name_vector{end+1} = ['EMAF(.015)'];
%         signal_count = signal_count + 1;
%
%
%         figure;
%         subplot(2,2,1);
%         scatter(macd(1:length(change_in_future_360.low)),...
%             delta_macd(1:length(change_in_future_360.low)),[],change_360_colors,'+');
%         title(['MACD(12,26,' num2str(sig) ') times ' num2str(period) ' - 360 seconds']);
%         xlabel('MACD');
%         ylabel('Change in MACD');
%
%         subplot(2,2,2);
%         scatter(macd(1:length(change_in_future_720.low)),...
%             delta_macd(1:length(change_in_future_720.low)),[],change_720_colors,'+');
%         title(['MACD(12,26,' num2str(sig) ') times ' num2str(period) ' - 720 seconds']);
%         xlabel('MACD');
%         ylabel('Change in MACD');
%
%         subplot(2,2,3);
%         scatter(macd(1:length(change_in_future_1440.low)),...
%             delta_macd(1:length(change_in_future_1440.low)),[],change_1440_colors,'+');
%         title(['MACD(12,26,' num2str(sig) ') times ' num2str(period) ' - 1440 seconds']);
%         xlabel('MACD');
%         ylabel('Change in MACD');
%
%         subplot(2,2,4);
%         scatter(macd(1:length(change_in_future_2880.low)),...
%             delta_macd(1:length(change_in_future_2880.low)),[],change_2880_colors,'+');
%         title(['MACD(12,26,' num2str(sig) ') times ' num2str(period) ' - 2880 seconds']);
%         xlabel('MACD');
%         ylabel('Change in MACD');
%     end
% end
%
% for ii = 1:length(signal_vector)
%    for jj = ii:length(signal_vector)
%
%        if(ii ~= jj)
%           figure; subplot(2,2,1);
%           scatter(signal_vector(ii,1:length(change_360_colors)),...
%               signal_vector(jj,1:length(change_360_colors)),...
%               [],change_360_colors,'+');
%           title('360 seconds');
%           xlabel(signal_name_vector(ii));ylabel(signal_name_vector(jj));
%           subplot(2,2,2);
%           scatter(signal_vector(ii,1:length(change_720_colors)),...
%               signal_vector(jj,1:length(change_720_colors)),...
%               [],change_720_colors,'+');
%           title('720 seconds');
%           xlabel(signal_name_vector(ii));ylabel(signal_name_vector(jj));
%           subplot(2,2,3);
%           scatter(signal_vector(ii,1:length(change_1440_colors)),...
%               signal_vector(jj,1:length(change_1440_colors)),...
%               [],change_1440_colors,'+');
%           title('1440 seconds');
%           xlabel(signal_name_vector(ii));ylabel(signal_name_vector(jj));
%           subplot(2,2,4);
%           scatter(signal_vector(ii,1:length(change_2880_colors)),...
%               signal_vector(jj,1:length(change_2880_colors)),...
%               [],change_2880_colors,'+');
%           title('2880 seconds');
%           xlabel(signal_name_vector(ii));ylabel(signal_name_vector(jj));
%           pause;
%        end
%
%    end
% end

% scatter3(macd(1:length(change_in_future_360.low)),...
%     delta_macd(1:length(change_in_future_360.low)),...
%     change_in_future_360.low,[],...
%     change_360_colors);
% scatter(macd(1:length(change_in_future_360.low)),...
%  delta_macd(1:length(change_in_future_360.low)),[],change_360_colors,'+');
% xlabel('MACD');
% ylabel('Change in MACD');

%find crossover points, i.e. where the MACD goes from positive to negative
%or vice versa
% crossovers = zeros(1,length(macd));
% for ii = 2:length(macd)
%     if((macd(ii) > 0) && (macd(ii-1)<0))
%         crossovers(ii) = 1;
%     elseif((macd(ii) < 0) && (macd(ii-1) > 0))
%         crossovers(ii) = 1;
%     end
% end
% crossovers = logical(crossovers);
%
% figure;
% scatter(delta_macd(crossovers),change_in_future_.low(crossovers));
