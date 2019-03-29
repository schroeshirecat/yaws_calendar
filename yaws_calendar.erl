-module(yaws_calendar).
-author('dev@ofehrmedia.com').
-export([start/1,is_valid_datestr/1,make_date/1,make_date/3,make_datestr/1,make_datetimestr/1]).
-include("../einc/yaws_api.hrl").
start(Datestr) ->
    Today = erlang:date(),
    try is_valid_datestr(Datestr) of
	_ ->
	    Date = make_date(Datestr),
	    make_calendar(Date,Today)
    catch
	_:_  ->  make_calendar(Today,Today)
    end.

is_valid_datestr(Datestr) ->
    Today = make_datestr(erlang:date()),
    case string:len(Datestr) =:= 10 of
	true ->
	    try string:tokens(Datestr,"-") of
		_ -> 
		    [Y,M,D] = string:tokens(Datestr,"-"),
		    try make_date(Y,M,D) of
			_ ->
			    case make_date(Y,M,D) of
				true -> Datestr;
				false -> Today
			    end
		    catch
			_:_ -> Today
		    end		    
	    catch
		_:_ -> Today
	    end;
	false ->
	    Today
    end.
    
make_date(Datestr) ->
    case string:len(Datestr) =:= 10 of
	true -> [Y,M,D] = string:tokens(Datestr,"-");
	false -> [Y,M,D] = string:tokens(make_datestr(erlang:date()),"-")
    end,
    {erlang:list_to_integer(Y),erlang:list_to_integer(M),erlang:list_to_integer(D)}.

make_date(Y,M,D) ->
    calendar:valid_date({erlang:list_to_integer(Y),
    erlang:list_to_integer(M),erlang:list_to_integer(D)}).
    
    
make_datestr(Date) ->
    case calendar:valid_date(Date) of
	true -> {Y,M,D} = Date;
	false -> {Y,M,D} = erlang:date()
   end,
   %io_lib:format("~s\-~s\-~s",[less_than_10(Y),less_than_10(M),less_than_10(D)]).
   less_than_10(Y) ++ "-" ++ less_than_10(M) ++ "-" ++ less_than_10(D).

make_datetimestr(DateTime) ->
   [{Year,Month,Day},{Hour,Minute,Second}] = DateTime,
   io_lib:format("~s\-~s\-~s\T~s\:~s\:~s\Z",[less_than_10(Year),less_than_10(Month),less_than_10(Day),less_than_10(Hour),less_than_10(Minute),less_than_10(Second)]).


is_in_same_month(Date1,Date2) ->
    {Y1,M1,D1} = Date1,
    {Y2,M2,D2} = Date2,
    case Y1 =:= Y2 of 
	true ->
	    case M1 =:= M2 of
		true ->
		    sameyearandmonth;
		false ->
		    notsameyearandmonth
	    end;
	false ->
	    notsameyear
   end.

less_than_10(X) ->
    case X < 10 of
      true ->
        Y = X,
        lists:flatten(io_lib:format("0~p",[Y]));
      false ->
        lists:flatten(io_lib:format("~p",[X]))
    end.
    
make_calendar(Date,Today)->
    Monthnames_en = {"January","February","March","April","May","June","July","August","September","Oktober","November","December"},
    Daynames_en = {{"Monday","Mon","Mo"},{"Tuesday","Tue","Tu"},{"Wednesday","Wed","We"},{"Thursday","Thu","Th"},{"Friday","Fri","Fr"},{"Saturday","Sat","Sa"},{"Sunday","Sun","Su"}},
    DateYear = erlang:element(1,Date),
    DateMonth = erlang:element(2,Date),
    DateDay = erlang:element(3,Date),
    Mo = erlang:element(3,erlang:element(1,Daynames_en)),
    Tu = erlang:element(3,erlang:element(2,Daynames_en)),
    We = erlang:element(3,erlang:element(3,Daynames_en)),
    Th = erlang:element(3,erlang:element(4,Daynames_en)),
    Fr = erlang:element(3,erlang:element(5,Daynames_en)),
    Sa = erlang:element(3,erlang:element(6,Daynames_en)),
    Su = erlang:element(3,erlang:element(7,Daynames_en)),
    Previousmonth = DateMonth - 1,
    Nextmonth = DateMonth + 1,
    case Previousmonth =:= 0 of
	true -> 
	    Previousyear = DateYear - 1,
	    Previousdate = {Previousyear,12,1};
	false -> Previousdate = {DateYear,Previousmonth,1}
    end,
    case Nextmonth =:= 13 of
	true -> 
	    Nextyear = DateYear + 1,
	    Nextdate = {Nextyear,1,1};
	false -> Nextdate = {DateYear,Nextmonth,1}
    end,
    Previousdatestr = make_datestr(Previousdate),
    Nextdatestr = make_datestr(Nextdate),
    Calendar ="",
    MyCalendar = add_day_to_calendar(Date,1,1,Calendar),
    io_lib:format("<table class=\"calendarTable\"><thead><tr><th><a href=\"?date=~s\" title=\"previous month\"><<</a></th><th colspan=\"5\">~s ~s</th><th><a href=\"?date=~s\" title=\"next month\">>></a></th></tr><tr><th>~s</th><th>~s</th><th>~s</th><th>~s</th><th>~s</th><th>~s</th><th>~s</th></tr></thead>~n<tbody>~s</tbody>~n</table>~n",[Previousdatestr,erlang:element(DateMonth,Monthnames_en),erlang:integer_to_list(DateYear),Nextdatestr,Mo,Tu,We,Th,Fr,Sa,Su,MyCalendar]).


add_day_to_calendar(Date,Index,Dayindex,Calendar) ->
    {Y,M,_D} = Date,
    Today = erlang:date(),
    Dayofweek = calendar:day_of_the_week(Y,M,1),
    Lastdayofmonth = calendar:last_day_of_the_month(Y,M),
    case Index < Dayofweek of
	true -> 
	    Newcalendar = Calendar ++ "<td>&nbsp;</td>",
	    Newindex = Index +1,
	    add_day_to_calendar(Date,Newindex,Dayindex,Newcalendar);
	false ->
	    case (Dayindex =< Lastdayofmonth) and (Index =< 42) of
		true -> 
		     case (Dayofweek + Dayindex-1) rem 7 of
			0 -> 
			    Newcalendar = Calendar  ++ add_table_cell(Date,Today,Dayindex) ++ "</tr><tr>\n";
			_ ->
			    Newcalendar = Calendar ++ add_table_cell(Date,Today,Dayindex) ++ "</td>"
		    end,
		    Nextindex = Index +1,
		    Nextdayindex = Dayindex + 1,
		    add_day_to_calendar(Date,Nextindex,Nextdayindex,Newcalendar);
		false ->
		    case Index =< 42 of
			true ->  
			    case (Dayofweek + Dayindex -1) rem 7 of
				0 -> 
				    Newcalendar = Calendar ++ "<td>&nbsp;</td></tr><tr>\n";
				_ ->
				    Newcalendar = Calendar ++ "<td>&nbsp;</td>"
			    end,
			    Newindex = Index +1,
			    Newdayindex = Dayindex +1,
			    add_day_to_calendar(Date,Newindex,Newdayindex,Newcalendar);
			false -> Calendar ++ "</tr>"
		   end
	    end
    end.


add_table_cell({Yd,Md,_Dd},{_Yt,_Mt,_Dt},Dayindex) when Yd =< 2015,Md<9 -> "<td>" ++ erlang:integer_to_list(Dayindex) ++ "</td>";

add_table_cell({Yd,Md,_Dd},{_Yt,_Mt,_Dt},Dayindex) when Yd =:= 2015, Md >= 9 -> io_lib:format("<td><a href=\"?date=~s\-~s\-~s\">~s</a></td>",[erlang:integer_to_list(Yd),less_than_10(Md),less_than_10(Dayindex),erlang:integer_to_list(Dayindex)]);

add_table_cell({Yd,Md,_Dd},{Yt,Mt,_Dt},Dayindex) when Yd > 2015,Yd =< Yt, Md =:= Mt -1 -> io_lib:format("<td><a href=\"?date=~s\-~s\-~s\">~s</a></td>",[erlang:integer_to_list(Yd),less_than_10(Md),less_than_10(Dayindex),erlang:integer_to_list(Dayindex)]);

add_table_cell({Yd,Md,_Dd},{Yt,Mt,Dt},Dayindex) when Yd =:= Yt, Md =:= Mt, Dayindex < Dt -> io_lib:format("<td><a href=\"?date=~s\-~s\-~s\">~s</a></td>",[erlang:integer_to_list(Yd),less_than_10(Md),less_than_10(Dayindex),erlang:integer_to_list(Dayindex)]);

add_table_cell({Yd,Md,_Dd},{Yt,Mt,Dt},Dayindex) when Yd =:= Yt, Md =:= Mt, Dayindex =:= Dt -> io_lib:format("<td class=\"today\"><a href=\"?date=~s\-~s\-~s\">~s</a></td>",[erlang:integer_to_list(Yd),less_than_10(Md),less_than_10(Dayindex),erlang:integer_to_list(Dayindex)]);

add_table_cell({Yd,Md,_Dd},{Yt,Mt,Dt},Dayindex) when Yd =:= Yt, Md =:= Mt, Dayindex > Dt -> "<td>" ++ erlang:integer_to_list(Dayindex) ++ "</td>";

add_table_cell({Yd,Md,_Dd},{Yt,Mt,_Dt},Dayindex) when Yd >= Yt, Md > Mt -> "<td>" ++ erlang:integer_to_list(Dayindex) ++ "</td>";

add_table_cell({Yd,_Md,_Dd},{Yt,_Mt,_Dt},Dayindex) when Yd > Yt -> "<td>" ++ erlang:integer_to_list(Dayindex) ++ "</td>".
