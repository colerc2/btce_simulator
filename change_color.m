function [colors ] = change_color( change_vs_time, thresh )
    change_vs_time = change_vs_time.low;
    %range = max(change_vs_time)-min(change_vs_time);
    min_change = min(change_vs_time);

    colors = zeros(length(change_vs_time),3);
    %colors(change_vs_time>thresh) = [0 0 1];%non-profit = blue
   
    %shade_of_red = (change_vs_time<thresh);
    for ii = 1:length(change_vs_time)
        if(change_vs_time(ii) < thresh)
           %colors(ii,1) =  (abs(change_vs_time(ii))-abs(thresh))/...
            %   (abs(min_change)-abs(thresh));
%            colors(ii,2) = .05;
%            colors(ii,3) = (1-colors(ii,1))/2;
           colors(ii,:) = [1 0 0]; 

        else
           colors(ii,:) = [0 0 1]; 
        end
%        colors(ii,1) = 1*...
%            (1-((change_vs_time(ii)-min_change)/range));
%        colors(ii,3) = 1*...
%            ((change_vs_time(ii)-min_change)/range);
    end

end

