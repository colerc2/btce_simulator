function data = red_btce_csv(file_name)

%I'm too stupid to use a function that's already made to read this file, so
%we're doin' it the old fashioned way

%open file handle
fid = fopen(file_name);


%ask_volumes = 162
%grab first line of file, loop 'til file end
counter = 1;
tline = fgetl(fid);
last_updated = {};
data = [];
while (ischar(tline))
    %split line at commas
    split = strsplit(tline, ',');
    
    %info provided by the ticker
    temp.high = str2double(split(1));
    temp.low = str2double(split(2));
    temp.avg = str2double(split(3));
    temp.vol = str2double(split(4));
    temp.vol_cur = str2double(split(5));
    temp.last = str2double(split(6));
    temp.buy = str2double(split(7));
    temp.sell = str2double(split(8));
    temp.updated = split(9);
    temp.server_time = split(10);
    
    %ask_prices, ask_volumes, bid_prices, bid_volumes
    %these can vary in length, so we have to find the indexes where they
    %start
    [~, ask_prices_index] = ismember('ask_prices', split);
    [~, ask_volumes_index] = ismember('ask_volumes', split);
    [~, bid_prices_index] = ismember('bid_prices', split);
    [~, bid_volumes_index] = ismember('bid_volumes', split);
    
    %each of these will be a vector of doubles
    temp.ask_prices = str2double(split(ask_prices_index+1:ask_volumes_index-1));
    temp.ask_volumes = str2double(split(ask_volumes_index+1:bid_prices_index-1));
    temp.bid_prices = str2double(split(bid_prices_index+1:bid_volumes_index-1));
    temp.bid_volumes = str2double(split(bid_volumes_index+1:end));
   
    %save this struct in a vector if the data is new
    if(isequal(last_updated,temp.updated))
       %display('This is probably working'); 
    else
        last_updated = temp.updated;
        data = [data temp];
    end
    
    %increment counter and get next line
    counter = counter + 1;
    tline = fgetl(fid);
end

end

