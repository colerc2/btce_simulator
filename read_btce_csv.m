function data = read_btce_csv(file_name, percent)

%I'm too stupid to use a function that's already made to read this file, so
%we're doin' it the old fashioned way

%open file handle
fid = fopen(file_name,'rt');

%find number of lines in file TODO: fix, currently searching for \r\n
% sys_cmd = ['find /c /v ""<' file_name];
% [return_code ,sys_cmd_answer] = system(sys_cmd);
% if(return_code == 0)%command returned successfully
%     line_count = str2double(sys_cmd_answer);
% end
% line_count = round(line_count * percent) ;
line_count = 1356922;%wow such good coding TODO

%preallocate cell array
%line_array = cell(1000,1);
line_array = cell(line_count,10);

%read lines, will do parsing later in parallel, do this in series because
%speed is limited by disk read, multiple threads won't speed it up
waitbar_ = waitbar(0,'Reading file...');
set(waitbar_,'Name',['Reading file ' file_name]);
one_percent_of_file = round(line_count/100);
tic;
maf = [ 0 0 0 0 0];
for line_counter = 1:line_count
%while(line_counter < 1000)
%save to cell array
    %line_array{line_counter} = fgetl(fid);
    
    %split at commas
    lineData = textscan(fgetl(fid),'%s',10,'Delimiter',',');
  
    %[textscan(fgetl(fid),'%s',10,'Delimiter',',')]
    line_array(line_counter,:) = lineData{1};
    %pack;
    
    %convert cells to appropriate types
    line_array(line_counter,1:8) = cellfun(@(s) {str2double(s)},...
        line_array(line_counter,1:8));
    line_array(line_counter,9:10) = cellfun(@(s) {datenum(char(s))},...
        line_array(line_counter,9:10));
    
    %print progress to waitbar
    if(mod(line_counter,one_percent_of_file) == 0)
        perc = line_counter/line_count;
        time = toc; tic;
        perc_remaining = 1-perc;
        time_remaining_seconds = round(perc_remaining/.01*time);
        maf = [maf(2:end) time_remaining_seconds];
        if(perc_remaining < .95)
            time_remaining_seconds = mean(maf);
        end
        time_remaining_min = floor(time_remaining_seconds/60);
        time_remaining_sec = floor(mod(time_remaining_seconds,60));
        if(time_remaining_min == 0)
            waitbar(perc,waitbar_,sprintf('%d%% done\n%d seconds remaining...',...
                round(perc*100),(time_remaining_sec)))
        else
            waitbar(perc,waitbar_,sprintf('%d%% done\n%d:%02d remaining...',...
                round(perc*100),(time_remaining_min),(time_remaining_sec)))
        end
    end
    
end
close(waitbar_);
fclose(fid);

data = line_array;

%ask_volumes = 162
%grab first line of file, loop 'til file end
% counter = 1;
% tline = fgetl(fid);
% last_updated = {};
% data = [];
% while (ischar(tline))
%     %split line at commas
%     split = strsplit(tline, ',');
%
%     %info provided by the ticker
%     temp.high = str2double(split(1));
%     temp.low = str2double(split(2));
%     temp.avg = str2double(split(3));
%     temp.vol = str2double(split(4));
%     temp.vol_cur = str2double(split(5));
%     temp.last = str2double(split(6));
%     temp.buy = str2double(split(7));
%     temp.sell = str2double(split(8));
%     temp.updated = split(9);
%     temp.server_time = split(10);
%
%     %ask_prices, ask_volumes, bid_prices, bid_volumes
%     %these can vary in length, so we have to find the indexes where they
%     %start
%     [~, ask_prices_index] = ismember('ask_prices', split);
%     [~, ask_volumes_index] = ismember('ask_volumes', split);
%     [~, bid_prices_index] = ismember('bid_prices', split);
%     [~, bid_volumes_index] = ismember('bid_volumes', split);
%
%     %each of these will be a vector of doubles
%     temp.ask_prices = str2double(split(ask_prices_index+1:ask_volumes_index-1));
%     temp.ask_volumes = str2double(split(ask_volumes_index+1:bid_prices_index-1));
%     temp.bid_prices = str2double(split(bid_prices_index+1:bid_volumes_index-1));
%     temp.bid_volumes = str2double(split(bid_volumes_index+1:end));
%
%     %save this struct in a vector if the data is new
%     if(isequal(last_updated,temp.updated))
%        %display('This is probably working');
%     else
%         last_updated = temp.updated;
%         data = [data temp];
%     end
%
%     %increment counter and get next line
%     counter = counter + 1;
%     tline = fgetl(fid);
% end

end

