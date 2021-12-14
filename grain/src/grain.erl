-module(grain).

%% API exports
-export([main/1]).
-export([worker/1]).
-export([search_repos/2, handle_week_commit/2, get_the_weekly_commit_count/3]).

%%====================================================================
%% API functions
%%====================================================================

-define(URL, "https://api.github.com/").
-define(USER_AGENT, {"User-Agent", "Awesome-Beam"}).
-define(ACCEPT_JSON, {"Accept", "application/vnd.github.v3+json"}).
-define(ACCEPT_STAR_JSON, {"Accept", "application/vnd.github.v3.star+json"}).
-define(TIMEOUT, 60000).
-define(Erlang, {"erlang", "otp"}).
-define(Elixir, {"elixir-lang", "elixir"}).
-define(HomePageData, "../data/index.data").
-define(CacheWeek(T), "./cache/" ++ T ++ "_week").
-define(CacheMonth(T), "./cache/" ++ T ++ "_month").

-define(normalize(N), lists:concat(string:replace(N, "-", "_", all))).

%% escript Entry point
main(_) ->
    application:ensure_all_started(inets),
    application:ensure_all_started(ssl),
    application:ensure_all_started(ibrowse),
    Token = os:getenv("ACCESS_TOKEN"),
    Token == false andalso io:format("warning GITHUB ACCESS TOKEN is empty, watch out api rate limit~n"),
    render_home_page(Token),
    ElixirTop = render_star_race("../elixir_star_race.json", "../data/elixir_star_race.data", Token),
    ErlangTop = render_star_race("../erlang_star_race.json", "../data/erlang_star_race.data", Token),
    render_top_page(?HomePageData, ErlangTop ++ ElixirTop),
    render_hex_pm_top_repos(),
    erlang:halt(0).

%%====================================================================
%% Internal functions
%%====================================================================
render_home_page(Token) ->
    render_page([?Erlang, ?Elixir], ?HomePageData, Token).

render_top_page(File, Tops) ->
    TopChildren =
        pmap(fun({Owner, Repo, Token, Count}) ->
            render_page([{Owner, Repo}], "../data/" ++ Repo ++ ".data", Token),
            Sep = <<"⇧"/utf8>>,
            {Count,
                #{
                    <<"label">> =>
                    <<(list_to_binary(Repo))/binary, Sep/binary, (integer_to_binary(Count))/binary>>,
                    <<"url">> => list_to_binary("assets/" ++ Repo ++ ".html"),
                    <<"icon">> => get_icon(Repo)
                }
            }
             end, Tops, 5),
    {_, SortTops} = lists:unzip(lists:sort(fun(A, B) -> A > B end, TopChildren)),
    List =
        [
            #{
                <<"label">> => <<"⬆︎⬆︎⬆︎⬆︎📈"/utf8>>,
                <<"url">> => <<"assets/erlang_star_race.html">>,
                <<"icon">> => <<"https://www.erlang.org/img/erlang.png">>
            },
            #{
                <<"label">> => <<"⬆︎⬆︎⬆︎⬆︎📈"/utf8>>,
                <<"url">> => <<"assets/elixir_star_race.html">>,
                <<"icon">> => <<"assets/elixir.svg">>
            },
            #{
                <<"label">> => <<"HexPM Download📈"/utf8>>,
                <<"url">> => <<"assets/hex_pm_downloads.html">>,
                <<"icon">> => <<"https://hex.pm/images/favicon-160-93fa091b05b3e260e24e08789344d5ea.png">>
            },
            #{
                <<"label">> => <<"5️⃣0️⃣0️⃣0️⃣⬆️"/utf8>>,
                <<"icon">> => <<"assets/star.svg">>
            }
            | SortTops],
    Bin = jsone:encode(List),
    {ok, FilePid} = file:open(File, [append, binary]),
    file:write(FilePid, <<"var top_nav= ", Bin/binary, ";\n">>),
    Time = calendar:system_time_to_rfc3339(erlang:system_time(second)),
    file:write(FilePid, <<"var updateDate=\"", (list_to_binary(Time))/binary, "\";\n">>),
    file:close(FilePid).

render_page(Repos, FileName, Token) ->
    {ok, File} = file:open(FileName, [write, binary]),
    handle_star_history(File, Token, Repos),
    handle_code_frequency(File, Token, Repos),
    handle_last_year_commit(File, Token, Repos),
    handle_release_tree(File, Token, Repos),
    handle_avatar(File, Token, Repos),
    ok = file:close(File).

handle_star_history(File, Token, Repos) ->
    pmap(fun({Owner, Repo}) ->
        {OldPage, OldCount, OldStar} =
            case file:read_file(?CacheWeek(Repo)) of
                {ok, Cache} -> binary_to_term(Cache);
                {error, enoent} -> {1, 0, #{}}
            end,
        {Page, Count, StarCache, StarHistoryMap} =
            get_star_history_by_week(Owner, Repo, OldPage, OldCount, OldStar, Token),
        ok = file:write_file(?CacheWeek(Repo), term_to_binary({Page, Count, StarCache})),
        StarHistory = maps:to_list(StarHistoryMap),
        SortStar = lists:map(fun({K, V}) -> [K, V] end, lists:sort(StarHistory)),
        Bin = jsone:encode(SortStar),
        file:write(File, ["var ", ?normalize(Owner), "_", ?normalize(Repo), "_star=", Bin, ";\n"])
         end, Repos, 10).

handle_code_frequency(File, Token, Repos) ->
    [begin
         CodeFreq = get_code_frequency(Owner, Repo, Token),
         {AddCode, DelCode} =
             lists:foldl(fun([Time, Add, Del], {Acc1, Acc2}) ->
                 Date = to_date(Time),
                 {[[Date, Add] | Acc1], [[Date, Del] | Acc2]} end, {[], []}, CodeFreq),
         AddBin = jsone:encode(lists:reverse(AddCode)),
         DelBin = jsone:encode(lists:reverse(DelCode)),
         Owner1 = ?normalize(Owner),
         Repo1 = ?normalize(Repo),
         file:write(File, ["var ", Owner1, "_", Repo1, "_add_code=", AddBin, ";\n"]),
         file:write(File, ["var ", Owner1, "_", Repo1, "_del_code=", DelBin, ";\n"])
     end || {Owner, Repo} <- Repos].

handle_avatar(File, Token, Repos) ->
    [begin
         Contributors = get_contributors(Owner, Repo, Token, 4),
         Avatars =
             [begin #{
                 <<"type">> => <<"avatar">>,
                 <<"size">> => 20,
                 <<"src">> => Avatar}
              end || #{<<"avatar_url">> := Avatar} <- Contributors],
         Bin = jsone:encode(Avatars),
         Owner1 = ?normalize(Owner),
         Repo1 = ?normalize(Repo),
         file:write(File, ["var ", Owner1, "_", Repo1, "_contributors=", Bin, ";\n"])
     end || {Owner, Repo} <- Repos].

get_contributors(Owner, Repo, Token, Page) ->
    get_contributors(Owner, Repo, Token, 1, Page + 1, []).

get_contributors(_Owner, _Repo, _Token, Max, Max, Acc) -> Acc;
get_contributors(Owner, Repo, Token, Page, Max, Acc) ->
    Path = "/contributors?per_page=30&page=" ++ integer_to_list(Page),
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    case request(Owner, Repo, Token, Path, Headers) of
        [] -> Acc;
        List -> get_contributors(Owner, Repo, Token, Page + 1, Max, Acc ++ List)
    end.

%% /repos/{owner}/{repo}/stats/code_frequency
get_code_frequency(Owner, Repo, Token) ->
    Path = "/stats/code_frequency",
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    request(Owner, Repo, Token, Path, Headers).

-define(DAY, 24 * 3600).
handle_last_year_commit(File, Token, Repos) ->
    [begin
         Commits = get_the_last_year_of_commit_activity(Owner, Repo, Token),
         Owner1 = ?normalize(Owner),
         Repo1 = ?normalize(Repo),
         [#{<<"week">> := Start} | _] = Commits,
         #{<<"week">> := End} = lists:last(Commits),
         StartDate = to_date(Start),
         EndDate = to_date(End + 6 * ?DAY),
         {Res, Total} =
             lists:foldl(fun(
                 #{<<"days">> := [C1, C2, C3, C4, C5, C6, C7],
                     <<"week">> := Week, <<"total">> := T},
                 {Acc, Acc1}) ->
                 D7 = [to_date(Week), C1],
                 D1 = [to_date(Week + 1 * ?DAY), C2],
                 D2 = [to_date(Week + 2 * ?DAY), C3],
                 D3 = [to_date(Week + 3 * ?DAY), C4],
                 D4 = [to_date(Week + 4 * ?DAY), C5],
                 D5 = [to_date(Week + 5 * ?DAY), C6],
                 D6 = [to_date(Week + 6 * ?DAY), C7],
                
                 {[D6, D5, D4, D3, D2, D1, D7 | Acc], [T | Acc1]}
                         end, {[], []}, Commits),
         file:write(File, ["var ", Owner1, "_", Repo1, "_commit_range=", jsone:encode([StartDate, EndDate]), ";\n"]),
         file:write(File, ["var ", Owner1, "_", Repo1, "_year_commit=", jsone:encode(lists:reverse(Res)), ";\n"]),
         file:write(File, ["var ", Owner1, "_", Repo1, "_week_commit=", jsone:encode(lists:reverse(Total)), ";\n"])
     end || {Owner, Repo} <- Repos].

%% https://docs.github.com/en/rest/reference/repos#get-the-last-year-of-commit-activity
get_the_last_year_of_commit_activity(Owner, Repo, Token) ->
    Path = "/stats/commit_activity",
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    request(Owner, Repo, Token, Path, Headers).

handle_week_commit(File, Token) ->
    [begin
         #{<<"all">> := All} = get_the_weekly_commit_count(Owner, Repo, Token),
         Owner1 = ?normalize(Owner),
         Repo1 = ?normalize(Repo),
         file:write(File, ["var ", Owner1, "_", Repo1, "_week_commit=", jsone:encode(All), ";\n"])
     end || {Owner, Repo} <- [?Erlang, ?Elixir]].

%% https://docs.github.com/en/rest/reference/repos#get-the-weekly-commit-count
get_the_weekly_commit_count(Owner, Repo, Token) ->
    Path = "/stats/participation",
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    request(Owner, Repo, Token, Path, Headers).

handle_release_tree(File, Token, Repos) ->
    List = [begin get_releases(Owner, Repo, Token) end || {Owner, Repo} <- Repos],
    Releases = lists:sort(fun(A, B) -> element(5, A) > element(5, B) end, lists:flatten(List)),
    Children = lists:foldl(fun({Repo, Tag, CreateAt, Count, _}, Acc) ->
        Key = binary:part(CreateAt, 0, 7),
        N =
            case Repo of
                "otp" -> <<"🍏"/utf8, "-", Tag/binary>>;
                _ -> <<"🍎"/utf8, "-", Tag/binary>>
            end,
        Name = #{name => N, value => Count},
        maps:update_with(Key, fun(L) -> [Name | L] end, [Name], Acc) end, #{}, Releases),
    Children1 = lists:map(fun({K, V}) -> [{name, K}, {children, V}] end, lists:sort(maps:to_list(Children))),
    Tree = #{name => <<"🎂"/utf8>>, children => Children1},
    file:write(File, ["var release_tree=", jsone:encode(Tree), ";\n"]).

%% https://docs.github.com/en/rest/reference/repos#list-releases
get_releases(Owner, Repo, Token) ->
    get_release(Owner, Repo, Token, 1, []).

get_release(Owner, Repo, Token, Page, Acc) ->
    Path = "/releases?per_page=10&page=" ++ integer_to_list(Page),
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    case request(Owner, Repo, Token, Path, Headers) of
        [] -> Acc;
        Res ->
            Add =
                lists:foldl(fun(#{<<"tag_name">> := Tag,
                    <<"created_at">> := CreateAt,
                    <<"assets">> := Assets}, Acc0) ->
                    Time = calendar:rfc3339_to_system_time(binary_to_list(CreateAt)),
                    case erlang:system_time(second) - Time > 365 * ?DAY of
                        true -> Acc0;
                        false ->
                            Size = lists:foldl(fun(#{<<"size">> := S}, Sum) -> S + Sum end, 0, Assets),
                            [{Repo, Tag, CreateAt, Size, Time} | Acc0]
                    end
                            end, [], Res),
            case Add of
                [] -> Acc;
                _ -> get_release(Owner, Repo, Token, Page + 1, Add ++ Acc)
            end
    end.

%% https://docs.github.com/en/rest/reference/repos#get-a-repository
get_repo(Owner, Repo, Token) ->
    Path = "",
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    request(Owner, Repo, Token, Path, Headers).

render_star_race(Source, Target, Token) ->
    {ok, Bin} = file:read_file(Source),
    List = jsone:decode(Bin),
    ListCount =
        [begin
             [Owner, Repo] = binary:split(FullName, <<"/">>),
             Owner1 = binary_to_list(Owner),
             Repo1 = binary_to_list(Repo),
             #{<<"stargazers_count">> := Count} = get_repo(Owner1, Repo1, Token),
             io:format("~p~n", [{Count, Owner1, Repo1}]),
             {Owner1, Repo1, Token, Count}
         end || FullName <- List],
    ListSort = lists:sort(fun(A, B) -> element(4, A) > element(4, B) end, ListCount),
    ListStar = pmap(fun({Owner, Repo, Token1, Count}) ->
        {OldPage, OldCount, OldStar} =
            case file:read_file(?CacheMonth(Repo)) of
                {ok, CacheBin} -> binary_to_term(CacheBin);
                {error, enoent} -> {1, 0, #{}}
            end,
        {PageCache, CountCache, StarCache, Stars} = get_star_history_by_month(Owner, Repo, OldPage, OldCount, OldStar, Token1),
        file:write_file(?CacheMonth(Repo), term_to_binary({PageCache, CountCache, StarCache})),
        {list_to_binary(Repo), Count, Stars}
                    end, ListSort, 15),
    StarSort = lists:sort(fun(A, B) -> element(2, A) > element(2, B) end, ListStar),
    {ok, File} = file:open(Target, [write, binary]),
    gen_race_data(lists:sublist(StarSort, 50), "race_top", File),
    Len = length(StarSort),
    case Len > 50 of
        true ->
            Tail = lists:sublist(StarSort, Len - 50, Len),
            gen_race_data(Tail, "race_tail", File);
        false -> ok
    end,
    file:close(File),
    lists:filter(fun({_, _, _, Count}) -> Count >= 5000 end, ListSort).

pmap(Fun, List, Number) ->
    Len = length(List),
    WorkerNum =
        case Len >= Number of
            true -> Number;
            false -> Len
        end,
    Workers = [begin {Seq, spawn_link(?MODULE, worker, [Fun])}
               end || Seq <- lists:seq(1, WorkerNum)],
    [begin erlang:send(Pid, {self(), lists:nth(Nth, List)}) end || {Nth, Pid} <- Workers],
    {_, UnDone} = lists:split(WorkerNum, List),
    Res = pmap_receive(Len, UnDone, []),
    [begin erlang:send(Pid, stop) end || {_Nth, Pid} <- Workers],
    Res.

pmap_receive(Len, [Task | List], Acc) ->
    receive {Worker, Res} ->
        erlang:send(Worker, {self(), Task}),
        pmap_receive(Len - 1, List, [Res | Acc])
    end;
pmap_receive(Len, [], Acc) when Len > 0 ->
    receive {_Worker, Res} ->
        pmap_receive(Len - 1, [], [Res | Acc])
    end;
pmap_receive(0, [], Acc) ->
    Acc.

worker(Fun) ->
    receive {Pid, Msg} ->
        erlang:send(Pid, {self(), Fun(Msg)}),
        worker(Fun);
        stop ->
            stop
    end.

gen_race_data(Source, Var, File) ->
    Now = erlang:system_time(second),
    YAxis = lists:map(fun({Repo, _, _}) -> Repo end, Source),
    {Result, _} =
        lists:foldl(fun(Seq, {Res, Latest}) ->
            Time = calendar:system_time_to_rfc3339(Now - Seq * 30 * ?DAY),
            Date = list_to_binary(lists:sublist(Time, 7)),
            {Data, NewLatest} =
                lists:foldl(fun({Repo, _Count, Star}, {Acc, L}) ->
                    case maps:find(Date, Star) of
                        {ok, S} -> {[S | Acc], maps:put(Repo, S, L)};
                        error -> {[maps:get(Repo, L, 0) | Acc], L}
                    end
                            end, {[], Latest}, Source),
            Data1 = lists:reverse(Data),
            {Data2, YAxis1} = lists:unzip(lists:sort(lists:zip(Data1, YAxis))),
            {YAxis2, _} = lists:foldr(fun(Repo, {Acc, C}) ->
                Rank = get_rank(C),
                {[<<Rank/binary, <<":">>/binary, Repo/binary>> | Acc], C + 1} end,
                {[], 1}, YAxis1),
            {[#{<<"yAxis">> => lists:reverse(YAxis2), <<"data">> => lists:reverse(Data2), <<"date">> => Date} | Res],
                NewLatest}
                    end, {[], #{}}, lists:seq(40, 1, -1)),
    file:write(File, ["var ", Var, "=", jsone:encode(lists:reverse(Result)), ";\n"]).


%% https://docs.github.com/en/rest/reference/search#search-repositories
search_repos(Language, _Token) ->
    Url = ?URL ++ "search/repositories?q=" ++ Language ++ "+archived:false&sort=stars&order=desc&page=1&per_page=50",
    Headers = [?ACCEPT_JSON, ?USER_AGENT],
    {ok, "200", _, Body} = ibrowse:send_req(Url, Headers, get, <<>>, [], ?TIMEOUT),
    #{<<"items">> := List} = jsone:decode(list_to_binary(Body)),
    [begin
         [_Owner, Repo] = binary:split(FName, <<"/">>),
         %% Stars = get_star_history_by_month(binary_to_list(Owner), binary_to_list(Repo), Token),
         {Repo, Count} end ||
        #{<<"full_name">> := FName, <<"stargazers_count">> := Count} <- List].

get_star_history_by_week(Owner, Repos, OldPage, OldCount, OldStar, Token) ->
    GroupFun = fun(#{<<"starred_at">> := Time}, {AccT, CountT}) ->
        SystemTime =
            calendar:rfc3339_to_system_time(binary_to_list(Time)),
        {Date, _} =
            calendar:system_time_to_local_time(SystemTime, second),
        Sunday =
            SystemTime
                + (7 - calendar:day_of_the_week(Date)) * 24 * 3600,
        SunRfc3399 =
            list_to_binary(calendar:system_time_to_rfc3339(Sunday)),
        [SunDate | _] = binary:split(SunRfc3399, [<<"T">>]),
        {maps:update_with(SunDate,
            fun(V) -> V + 1 end,
            CountT + 1,
            AccT),
            CountT + 1}
               end,
    get_star_history(Owner, Repos, Token, GroupFun, OldPage, OldCount, OldStar).

get_star_history_by_month(Owner, Repos, OldPage, OldCount, OldStar, Token) ->
    GroupFun = fun(#{<<"starred_at">> := Time}, {AccT, CountT}) ->
        Month = binary:part(Time, 0, 7),
        {maps:update_with(Month,
            fun(V) -> V + 1 end,
            CountT + 1,
            AccT),
            CountT + 1}
               end,
    get_star_history(Owner, Repos, Token, GroupFun, OldPage, OldCount, OldStar).

get_star_history(Owner, Repo, Token, GroupFun, Page, Count, Acc) ->
    Path = "/stargazers?per_page=100&page=" ++ integer_to_list(Page),
    Headers = [?ACCEPT_STAR_JSON, ?USER_AGENT],
    Res = request(Owner, Repo, Token, Path, Headers),
    {NewAcc, NewCount} = lists:foldl(GroupFun, {Acc, Count}, Res),
    Len = length(Res),
    io:format("star: ~p :~p ~p ~p~n", [Repo, Page, NewCount, Len]),
    case Len < 100 of
        true -> {Page, Count, Acc, NewAcc};
        false -> get_star_history(Owner, Repo, Token, GroupFun, Page + 1, NewCount, NewAcc)
    end.

request(Owner, Repo, Token, Path, Headers) ->
    UrlList =  [?URL, "repos/", Owner, "/", Repo, Path],
    AuthHeader = 
        case Token of
            false -> [];
            _ -> [{"Authorization", "token " ++ Token}]
        end,
    Url = lists:concat(UrlList),
    case ibrowse:send_req(Url, AuthHeader ++ Headers, get, <<>>, [], ?TIMEOUT) of
        {ok, "200", _, Body} ->
            jsone:decode(list_to_binary(Body));
        {ok, "202", _, _} ->
%% Computing repository statistics is an expensive operation,
%% so we try to return cached data whenever possible.
%% If the data hasn't been cached when you query a repository's statistics, you'll receive a 202 response;
%% a background job is also fired to start compiling these statistics.
%% Give the job a few moments to complete, and then submit the request again.
%% If the job has completed, that request will receive a 200 response with the statistics in the response body.
%%Repository statistics are cached by the SHA of the repository's default branch;
%% pushing to the default branch resets the statistics cache.
            timer:sleep(60000),
            {ok, "200", _Header, Body} = ibrowse:send_req(Url, AuthHeader ++ Headers, get, <<>>, [], ?TIMEOUT),
            jsone:decode(list_to_binary(Body));
        {ok, "403", _Header, Body} ->
            io:format("Forbidden by GITHUB: ~p~n", [Body]),
            error({403, Url, Headers, Body});
        {error, req_timedout} ->
            io:format("TIMEOUT by GITHUB: ~p ~p ~p~n", [Url, Headers, ?TIMEOUT]),
            error({req_timedout, Url, Headers, ?TIMEOUT})
    end.

to_date(Time) ->
    {{Y, M, D}, _} = timestamp_to_datetime(Time),
    iolist_to_binary(io_lib:format("~w-~2..0w-~2..0w", [Y, M, D])).

%% calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}}),
-define(UnixEpochGS, 62167219200).
timestamp_to_datetime(TimeStamp) ->
    GregorianSeconds = TimeStamp + ?UnixEpochGS,
    UniversalTime = calendar:gregorian_seconds_to_datetime(GregorianSeconds),
    calendar:universal_time_to_local_time(UniversalTime).

get_icon("otp") -> <<"https://www.erlang.org/img/erlang.png">>;
get_icon("emqx") -> <<"https://www.emqx.io/static/favicon.ico">>;
get_icon("rabbitmq-server") -> <<"https://www.rabbitmq.com/favicon.ico">>;
get_icon("cowboy") -> <<"https://ninenines.eu/img/ico/favicon.ico">>;
get_icon("phoenix") -> <<"https://hexdocs.pm/phoenix/assets/logo.png">>;
get_icon("ecto") -> <<"https://hexdocs.pm/ecto/assets/logo.png">>;
get_icon(_) -> <<"./assets/star.svg">>.

get_rank(1) -> <<"1️⃣"/utf8>>;
get_rank(2) -> <<"2️⃣"/utf8>>;
get_rank(3) -> <<"3️⃣"/utf8>>;
get_rank(4) -> <<"4️⃣"/utf8>>;
get_rank(5) -> <<"5️⃣"/utf8>>;
get_rank(6) -> <<"6️⃣"/utf8>>;
get_rank(7) -> <<"7️⃣"/utf8>>;
get_rank(8) -> <<"8️⃣"/utf8>>;
get_rank(9) -> <<"9️⃣"/utf8>>;
get_rank(10) -> <<"🔟"/utf8>>;
get_rank(I) -> integer_to_binary(I).

render_hex_pm_top_repos() ->
    Url = "https://hex.pm/api/packages?page=1&sort=downloads",
    Headers = [{"Accept", "application/vnd.hex+erlang"}, ?USER_AGENT],
    case ibrowse:send_req(Url, Headers, get, <<>>, [], ?TIMEOUT) of
        {ok, "200", _, Body} ->
            Repos = erlang:binary_to_term(list_to_binary(Body)),
            {Name, All, Day, Week, Recent} =
                lists:foldl(fun(I, {NameAcc, AllAcc, DayAcc, WeekAcc, RecentAcc}) ->
                    #{<<"name">> := Name,
                        <<"downloads">> := #{<<"all">> := All, <<"day">> := Day, <<"recent">> := Recent,
                            <<"week">> := Week}} = I,
                    {[Name | NameAcc], [All | AllAcc], [Day | DayAcc], [Week | WeekAcc], [Recent | RecentAcc]}
                            end, {[], [], [], [], []}, lists:reverse(lists:sublist(Repos, 100))),
            PieAll = [begin #{<<"name">> => N, <<"value">> => A} end || {N, A} <- lists:zip(Name, All)],
            PieWeek = [begin #{<<"name">> => N, <<"value">> => A} end || {N, A} <- lists:zip(Name, Week)],
            PieRecent = [begin #{<<"name">> => N, <<"value">> => A} end || {N, A} <- lists:zip(Name, Recent)],
            Bin = [
                "var names=", jsone:encode(Name), ";\n", "var alls=", jsone:encode(All), ";\n",
                "var days=", jsone:encode(Day), ";\n", "var weeks=", jsone:encode(Week), ";\n",
                "var weeks=", jsone:encode(Week), ";\n", "var recents=", jsone:encode(Recent), ";\n",
                "var pieAllData = ", jsone:encode(PieAll), ";\n",
                "var pieWeekData = ", jsone:encode(PieWeek), ";\n",
                "var pieRecentData = ", jsone:encode(PieRecent), ";\n"
            ],
            file:write_file("../data/hex_pm.data", Bin),
            ok;
        Error ->
            io:format("hex.pm downloads chart error:~p", [Error])
    end.