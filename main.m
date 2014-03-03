clear all; close all; clc;

%TODO
%-need to make it based on time, not data points collected, i.e. if i say a
%i want an exponential moving average filter with 60 points, it should do
%the last 60 seconds, not the last 60 data points, fuck that's hard

%runtime params
data_file_path = 'data\';
%data_file_name = 'btc_usd_depth';
data_file_name = 'btc_usd_depth_nov_24_dec_18';
data_file_extension = '.csv';
load_from_mat = 1; %if you've loaded this file before, set this to 1
pair = 'btc_usd';
sliding_window_width = 100000;%seconds
plot_every_n_seconds = 25000;
show_sliding_plot = 0;
simulation_speed = 1;%1 is as fast as possible(gg cpu), 0 is real time(lame):TODO
btc_fee = .002;
window_length = 1; %minute(TODO, see above), for financial analysis stuff, maf, emaf, macd, etc.

%initialize wallet m8
wallet.btc = 1;
wallet.usd = 0;
wallet.btc_on_orders = 0;
wallet.usd_on_orders = 0;

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
    btce_data_cell = read_btce_csv([data_file_path data_file_name data_file_extension], 1);
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

% %test plot for data vs. date
% figure;
% plot(btce_data.updated, btce_data.last);
% datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
% ylabel('BTC/USD ($)'); xlabel('Time');

%do a bunch of singal processing that the bot will use later
fprintf('Doing some data crunching (maf and such)...');
%simple moving average filters, second param changes the order (seconds)
%maf_10 = moving_average(btce_data.last,10);
%maf_100 = moving_average(btce_data.last,100);
%weighted moving average
% wmaf_10 = weighted_moving_average(btce_data.last,10);
% wmaf_100 = weighted_moving_average(btce_data.last,100);
%exponential moving average
% emaf_005 = exponential_moving_average(btce_data.last,0.005);
% emaf_015 = exponential_moving_average(btce_data.last,0.015);
%TODO: Moving average convergence-divergence, first three parameters are
%the typical weights applied, i.e. the n-term MAF, and the fourth parameter
%is the time period that each of these will be applied over, e.g. 12, 26,
%9, 10 correspond to a 120sec,260,sec,90sec MACD
short = 12;
long = 26;
sig = 9;
period = [100 20 60 70 80 90 120];
macd_window = 30;%used for sell signal later in code
macd_spread_thresh = [-.6 -2 -0.75 -0.5 -0.5 -0.5 -0.6];%used for sell signal later in code
for ii = 1:length(period)
    [macd(ii,:), macd_line(ii,:), signal_line(ii,:)] = ...
        moving_average_convergence_divergence(btce_data.last,...
        short, long, sig, period(ii));
end
%scale her so she's easier to plot with other stuff
%max_macd = max(abs(macd));
%macd = macd*(10/max_macd);
delta_macd = [0 (macd(1,2:end)-macd(1,1:end-1))];

change_in_future_2880 = change_in_future(btce_data.last,2880);
%TODO: plot all of these against the maximum/minimum change in price over
%the next x seconds/minutes. this will show whether there is some sort of
%correlation between these indicators and future prices. this shit is
%weird, why can't i just have a time machine

fprintf('done!\n');

%now that we have all the data, start simulating the market

%buys and sells
%buys and sells will be a vector of structs with
%buys.time = time when buy was issued
%buys.quantity = quantity
%buys.price = i wonder what this is
%buys.units = btc/usd
%buys.buy = lowest sell price at the time (i.e.the price you'll pay to buy)
%buys.sell = highest buy price at the time (price you'll get for sell)
%buys.completed = whether or not it's done (0/1)
%temp.time_completed = initialized to zero
buys = [];
sells = [];

%loop through each data point, should be at a maximum of 1Hz
for ii = 1:length(btce_data.updated)
    %make a sliding window plot
    if((mod(ii,plot_every_n_seconds)==0) &&(show_sliding_plot==1))
        figure(2);subplot(2,1,1);hold on;
        
        plot_indices = max(1,ii-sliding_window_width):min(length(btce_data.updated),ii);
        
        %plots buys and sells, this is gonna suck TODO
        
        
        h = plot(btce_data.updated(plot_indices),btce_data.last(plot_indices),'b');
        if(~isempty(sells))
            temp = sells;
            temp(temp.completed==0) = [];
            scatter(sells.time_completed,sells.price,'g');
        end
        
        legend('Last','Sells');
        set(h(1), 'LineWidth', 2);
        xlim([(addtodate(btce_data.updated(ii),-sliding_window_width,'second')) btce_data.updated(ii)]);
        datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
        subplot(2,1,2);
        
        %scale = (max(abs(change_in_future_2880.low*100)))/max(macd);
        %h = plot(btce_data.updated(plot_indices), 100*change_in_future_2880.low(plot_indices),'b',...
        %   btce_data.updated(plot_indices), 100*change_in_future_2880.high(plot_indices),'g',...
        h = plot(btce_data.updated(plot_indices),macd(1,plot_indices),'r',...
            btce_data.updated(plot_indices),macd_line(1,plot_indices),'b',...
            btce_data.updated(plot_indices),signal_line(1,plot_indices),'g',...
            btce_data.updated(plot_indices), zeros(1,length(plot_indices)),'k');
        
        %btce_data.updated(plot_indices), macd(plot_indices),'r',...
        %    btce_data.updated(plot_indices), zeros(1,length(plot_indices)),'c');
        set(h, 'LineWidth', 2);
        legend('MACD Hist', 'MACD', 'Signal');
        xlim([(addtodate(btce_data.updated(ii),-sliding_window_width,'second')) btce_data.updated(ii)]);
        datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
        
        %end
        
        pause(.1);
    end
    
    %do yo thang bot
    %this if statement checks for a sell signal
    if(any_indicator_says_sell(macd(:,max(1,ii-macd_window):ii),macd_spread_thresh)==1)
    %if((min(macd(max(1,ii-macd_window):ii))<macd_spread_thresh) && ...%meets sell req.
    %        ((macd(ii)>0) && (macd(ii-1) <0)))%macd is giving sell signal
        %make sure we haven't had a sell in the last 100 seconds
        go_ahead_with_sell = 0;
        if(isempty(sells))
            go_ahead_with_sell = 1;
        else
            time_since_last_sell = (btce_data.updated(ii)-sells(end).time)*86400;
            if(time_since_last_sell > 100)
                go_ahead_with_sell = 1;
            end
        end
        
        if(go_ahead_with_sell == 1)
            %check if it just crossed over
            %if((macd(ii) < 0) && (macd(ii-1) > 0))
            %fuck it, sell
            temp = [];
            temp.time = btce_data.updated(ii);
            temp.quantity = wallet.btc*0.25;
            temp.price = btce_data.last(ii)*0.9999;%TODO:might want to make this sell*.999
            temp.units = 'btc';
            temp.buy = btce_data.buy(ii);
            temp.sell = btce_data.sell(ii);
            temp.completed = 0;
            temp.time_completed = 0;
            temp.macd_slope = delta_macd(ii);
            sells = [sells temp];
            
            wallet.btc_on_orders = wallet.btc_on_orders + wallet.btc * 0.25;
            wallet.btc = wallet.btc - wallet.btc * 0.25;
            
            %print some stuff out
            %fprintf('Slope of MACD: %f', delta_macd(ii))
            %end
        end
        
    end
    
    %buys
    if(~isempty(buys))
        for jj = 1:length(buys)
            if(buys(jj).completed == 0)
                %assuming that the sell price is higher than price we'd like to
                %buy at when the buy was created
                if(btce_data.last(ii) < buys(jj).price)
                    buys(jj).completed = 1;
                    buys(jj).time_completed = btce_data.updated(ii);
                    fprintf('%f BTC bought at $%f\n', buys(jj).quantity,...
                        buys(jj).price);
                    
                    %adjust wallet prices
                    usd_from_wallet = buys(jj).price*buys(jj).quantity;
                    btc_to_wallet = buys(jj).quantity * (1-btc_fee);
                    wallet.btc = wallet.btc + btc_to_wallet;
                    wallet.usd_on_orders = wallet.usd_on_orders - usd_from_wallet;
                end
            end
        end
    end
    
    %sells
    if(~isempty(sells))
        for jj = 1:length(sells)
            if(sells(jj).completed == 0)
                %assuming that the buy price is lower than price we'd like to
                %sell at when the buy was created
                if(btce_data.last(ii) >= sells(jj).price)
                    sells(jj).completed = 1;
                    sells(jj).time_completed = btce_data.updated(ii);
                    fprintf('%f BTC sold at $%f\n', sells(jj).quantity,...
                        sells(jj).price);
                    
                    %adjust wallet prices
                    btc_from_wallet = sells(jj).quantity;
                    usd_to_wallet = sells(jj).quantity * sells(jj).price * (1-btc_fee);
                    wallet.btc_on_orders = wallet.btc_on_orders - btc_from_wallet;
                    wallet.usd = wallet.usd + usd_to_wallet;
                    
                    %create buy order at 98% of what sold for
                    %TODO this needs to be magical process
                    temp = [];
                    temp.time = btce_data.updated(ii);
                    temp.quantity = usd_to_wallet/(sells(jj).price*.98);
                    temp.price = sells(jj).price*.98;
                    temp.units = 'btc';
                    temp.buy = btce_data.buy(ii);
                    temp.sell = btce_data.sell(ii);
                    temp.completed = 0;
                    temp.time_completed = 0;
                    temp.associated_sell = sells(jj);
                    buys = [buys temp];
                    
                    wallet.usd = wallet.usd - usd_to_wallet;
                    wallet.usd_on_orders = wallet.usd_on_orders + usd_to_wallet;
                    
                end
            end
        end
    end
    if(mod(ii,2500) == 0)
        %wallet
    end
end

wallet
%test plot for data vs. date
figure; hold on;
plot(btce_data.updated, btce_data.last);
datetick('x');
%datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
scatter([sells.time_completed],[sells.price],'r');
buys_non_zero = [buys.time_completed];
buys_non_zero(buys_non_zero==0) = [];
buys_non_zero_price = [buys.price];
buys_non_zero_price = buys_non_zero_price(1:length(buys_non_zero));
scatter(buys_non_zero,buys_non_zero_price,'g');
ylabel('BTC/USD ($)'); xlabel('Time');

buy_times = [];
for ii = 1:length(buys)
   if(buys(ii).completed==1)
       buy_times = [buy_times (buys(ii).time_completed-buys(ii).associated_sell.time)];
   end
end
buy_times = buy_times*86400;
buy_times

%pause;
%
% %do some analysis on slope of MACD vs time it takes to sell
% macd_slopes = [];
% buy_times = [];
% for ii = 1:length(buys)
%     %if(sells(ii).completed == 1)
%     macd_slopes = [macd_slopes buys(ii).associated_sell.macd_slope];
%     if(buys(ii).completed == 1)
%         buy_times = [buy_times (buys(ii).time_completed-buys(ii).associated_sell.time)];
%     else
%         buy_times = [buy_times .02];
%     end
%     %end
% end
% buy_times = buy_times*86400;
% figure;
% scatter(macd_slopes, buy_times);
%
% %try to create some profiles of the MACD or something .005 -> -.025
% step_size = .001;
% macd = moving_average_convergence_divergence([btce_data.last],16,30,10,20);
% delta_macd = [0 (macd(2:end)-macd(1:end-1))];
%
%
% change_in_future_ = change_in_future([btce_data.last], 360);
% change_in_future_ = change_in_future_(:,2);
% %trim outliers
% change_in_future_(change_in_future_>0.005) = 0.005;
% change_in_future_(change_in_future_<(-0.025)) = -0.025;
% change_in_future_ = ceil((change_in_future_+.025)/.001);
%
% %data = [btce_data.last];
% success = 0;
% for profile_length = 5:5:100
%     %go through data and make profiles
%     success = 0;
%     tried = 0;
%     for index_number = 1:30
%        indices = find(change_in_future_==index_number);
%        temp_prof.data = zeros(1,profile_length);
%        temp_prof.num_points = 0;
%        for ii = 1:length(indices)
%            if(indices(ii) > profile_length)
%               sig_to_be_normalized = macd((indices(ii)-profile_length+1):indices(ii));
%               sig_to_be_normalized = sig_to_be_normalized/(max(abs(sig_to_be_normalized)));
%               temp_prof.data = temp_prof.data + sig_to_be_normalized;
% %               temp_prof.data = temp_prof.data + macd((indices(ii)-profile_length+1):indices(ii));
%               temp_prof.num_points = temp_prof.num_points + 1;
%            end
%        end
%        profile(index_number) = temp_prof;
%     end
%
%     %normalize each profile
%     for ii = 1:length(profile)
%        profile(ii).data = profile(ii).data/max(abs(profile(ii).data));
%     end
%
%     %now test
%     for ii = profile_length:length(change_in_future_)
%        macd_signal = macd((ii-profile_length+1):ii);
%        %macd_signal = macd_signal/max(abs(macd_signal));
%        least_squares = [];
%        for each_prof = 1:length(profile)
%           least_squares(each_prof) = sum((macd_signal-profile(each_prof).data).^2);
%        end
%
%        [min_, chosen_prof] = min(least_squares);
%        if(chosen_prof < 10)
%           if(change_in_future_(ii) < 15)
%              success = success + 1;
%           end
%           fprintf('Computed: %i, Actual: %i\n', chosen_prof, change_in_future_(ii));
%           tried = tried + 1;
%        end
% %        if((abs(chosen_prof - change_in_future_(ii)) < 3))
% %            success = success + 1;
% %        end
%     end
% %     fprintf('Profile size: %i, percent correct: %f\n', profile_length, (success/length(change_in_future_)));
%     fprintf('Profile size: %i, percent correct: %f\n', profile_length, (success/tried));
% end
% %fprintf('Success: %f', (success/length(change_in_future_)));
%
%
%
% time_for_future = 300; %seconds, chosen arbitrarily
% %lots of plots, prepare your anus
% %change_in_future_300 = change_in_future([btce_data.last],300);
% trials = [];
% change_in_future_ = [];
% macd = [];
% delta_macd = [];
% trial.quantity = 0;
% trial.future_length = 0;
% trial.ii = 0;
% trial.short = 0;
% trial.long = 0;
% trial.sig = 0;
% trial.slope = 0;
% for future_length = 360
%     change_in_future_ = change_in_future([btce_data.last],future_length);
%     for ii = 5:5:120
%         for short = 6:2:18
%             for long = 22:2:30
%                 for sig = 6:1:12
%                     %macd = moving_average_convergence_divergence([btce_data.last],12,26,9,ii);
%                     macd = moving_average_convergence_divergence([btce_data.last],short,long,sig,ii);
%                     delta_macd = [0 (macd(2:end)-macd(1:end-1))];
%                     delta_delta_macd = [0 (delta_macd(2:end)-delta_macd(1:end-1))];
%                     delta_delta_delta_macd = [0 (delta_delta_macd(2:end)-delta_delta_macd(1:end-1))];
%
%
%                     change_thresh = (change_in_future_(:,2)>-0.011);
%                     slope_threshold = max(delta_macd(change_thresh));
%
%                     %i can't get this to work, wtf, oh well, just count
%                     number_past_threshold = length(delta_macd(delta_macd>slope_threshold));
%                     fprintf([num2str(future_length) ' second future, ' ...
%                         num2str(ii) ' second MACD(' num2str(short) ','...
%                         num2str(long) ',' num2str(sig) '): ' ...
%                         num2str(number_past_threshold) '\n']);
%
%                     trial.quantity = number_past_threshold;
%                     trial.future_length = future_length;
%                     trial.ii = ii;
%                     trial.short = short;
%                     trial.long = long;
%                     trial.sig = sig;
%                     trial.slope = slope_threshold;
%                     trials = [trials trial];
%
%                     figure;
%                     scatter(delta_delta_delta_macd(1:length(change_in_future_(:,2))), change_in_future_(:,2));
%
%                     %figure;
%                     %scatter(delta_macd(1:length(change_in_future_(:,2))), change_in_future_(:,2));
%                     %title(['Price change: ' num2str(ii) ' seconds, macd_dt: ' num2str(jj) ' seconds']);
%                 end
%             end
%         end
%     end
% end
%
% % figure;
% % scatter(delta_macd(1:length(change_in_future_300(:,2))), change_in_future_300(:,2));
%
% wallet
