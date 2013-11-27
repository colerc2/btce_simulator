clear all; close all; clc;

%runtime params
data_file_path = 'data\';
data_file_name = 'btc_usd_depth';
data_file_extension = '.csv';
load_from_mat = 1; %if you've loaded this file before, set this to 1
pair = 'btc_usd';
sliding_window_width = 1000;%seconds
plot_every_n_seconds = 2;
simulation_speed = 1;%1 is as fast as possible(gg cpu), 0 is real time(lame):TODO
btc_fee = .002;

%initialize wallet m8
wallet.btc = 12;
wallet.usd = 0;
wallet.btc_on_orders = 0;
wallet.usd_on_orders = 0;

%read in data from csv file, save as .mat so it's faster next time, it
%takes a reaaaalllly long time the first time, like 30 minutes or so, after
%that, once it's in .mat format, it should only take a few seconds for day
%worth of data
fprintf('Loading...');
if(load_from_mat)
    load([data_file_name '.mat']);
else
    btce_data = read_btce_csv([data_file_path data_file_name data_file_extension]);
    save([data_file_name '.mat'], 'btce_data');
end
fprintf('done!\n');

%convert btce_data.updated dates to matlab format (Matlab serial dates)
fprintf('Converting dates for Matlab...');
seconds = datenum(char([btce_data.updated]));%takes a few seconds
fprintf('done!\n');

%test plot for data vs. date
figure;
plot(seconds, [btce_data.last]);
datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
ylabel('BTC/USD ($)'); xlabel('Time');

%do a bunch of singal processing that the bot will use later
fprintf('Doing some data crunching (maf and such)...');
%simple moving average filters, second param changes the order (seconds)
maf_10 = moving_average([btce_data.last],10);
maf_100 = moving_average([btce_data.last],100);
%weighted moving average
wmaf_10 = weighted_moving_average([btce_data.last],10);
wmaf_100 = weighted_moving_average([btce_data.last],100);
%TODO: exponential moving average filters
%TODO: Moving average convergence-divergence
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
for ii = 1:length(seconds)
    %make a sliding window plot
    if(mod(ii,plot_every_n_seconds)==0)
        figure(2);
        plot_indices = max(1,ii-sliding_window_width):min(length(seconds),ii);
        
        %plots buys and sells, this is gonna suck TODO
%         if(~isempty(buys))
%             for jj = 1:length(buys)
%                 buy_plot_indices = plot_indices(seconds(plot_indices)>...
%                     buys(jj).time);
%                 temp_ones = ones(1,length(buy_plot_indices))*buys(jj).price;
%                 %plot(seconds(buy_plot_indices),temp_ones, 'g', 'LineWidth', 3);
%                 handle = plot(seconds(plot_indices),[btce_data(plot_indices).last],...
%                     'b',seconds(buy_plot_indices),temp_ones, 'g');
%                 set(handle(2), 'LineWidth', 3);
%                 xlim([(addtodate(seconds(ii),-sliding_window_width,'second')) seconds(ii)]);
%                 datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h TODO
%             end
%         else
            h = plot(seconds(plot_indices),[btce_data(plot_indices).last],'b', ...
                seconds(plot_indices), maf_10(plot_indices),'g',...
                seconds(plot_indices), maf_100(plot_indices), 'r',...
                seconds(plot_indices), wmaf_10(plot_indices), 'c',...
                seconds(plot_indices), wmaf_100(plot_indices), 'm');
            set(h(1), 'LineWidth', 2);
            xlim([(addtodate(seconds(ii),-sliding_window_width,'second')) seconds(ii)]);
            datetick('x', 'keepticks', 'keeplimits'); %<----needs changed for data >24h
%         end
        
        pause(.01);
    end
       
    
    %create a sell at a random time for testing
    if(ii == 300)
        wallet.btc_on_orders = 1;
        wallet.btc = wallet.btc - 1;
        
        temp.time = seconds(ii);
        temp.quantity = 1;
        temp.price = 718;
        temp.units = 'btc';
        temp.buy = btce_data(ii).buy;
        temp.sell = btce_data(ii).sell;
        temp.completed = 0;
        temp.time_completed = 0;
        sells = [sells temp];
    end
    
    %create a buy at random time for testing
    if(ii == 1200)
        wallet.usd_on_orders = 702;
        wallet.usd = wallet.usd - 702;
        
        temp.time = seconds(ii);
        temp.quantity = 1;
        temp.price = 702;
        temp.units = 'btc';
        temp.buy = btce_data(ii).buy;
        temp.sell = btce_data(ii).sell;
        temp.completed = 0;
        temp.time_completed = 0;
        buys = [buys temp];
    end
    
    %buys
    if(~isempty(buys))
        for jj = 1:length(buys)
            if(buys(jj).completed == 0)
                %assuming that the sell price is higher than price we'd like to
                %buy at when the buy was created
                if(btce_data(ii).buy < buys(jj).price)
                    buys(jj).completed = 1;
                    buys(jj).time_completed = seconds(ii);
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
                if(btce_data(ii).sell > sells(jj).price)
                    sells(jj).completed = 1;
                    sells(jj).time_completed = seconds(ii);
                    fprintf('%f BTC sold at $%f\n', sells(jj).quantity,...
                        sells(jj).price);
                    
                %adjust wallet prices
                btc_from_wallet = sells(jj).quantity;
                usd_to_wallet = sells(jj).quantity * sells(jj).price * (1-btc_fee);
                wallet.btc_on_orders = wallet.btc_on_orders - btc_from_wallet;
                wallet.usd = wallet.usd + usd_to_wallet;
                end
            end
       end
    end
    
end

wallet
