-module(torerlo_listen).

-compile(export_all).

listen(Port, Pid_database) ->
    {ok, LSock} = gen_tcp:listen(Port,[list,{active,false}]),
    loop_accept(LSock, Pid_database).

loop_accept(LSock, Pid_database) ->
%    {ok, Sock} = gen_tcp:accept(LSock),
    case gen_tcp:accept(LSock) of
        {ok, Sock} ->
            loop_recv(Sock, Pid_database),
            loop_accept(LSock, Pid_database);
        {_,_} ->
            io:format("ACCEPT ERROR\n",[])
    end.

loop_recv(Sock, Pid_database) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, Msg} ->
%            Msg = process(Data),
            io:format("message: ~p~n",[Msg]),
            {ok, DictPairs} = torerlo_parser:parser(Msg, 99),
            {ok, {Peer_ip, Peer_port}} = inet:peername(Sock),
%            torerlo_pgsql:db_insert(DB, "peers", dict:fetch("peer_id", DictPairs), inet_parse:ntoa(Peer_ip), dict:fetch("port", DictPairs), dict:fetch("uploaded", DictPairs), dict:fetch("downloaded", DictPairs), dict:fetch("left", DictPairs), dict:fetch("info_hash", DictPairs)),
            Pid_database ! {insert, {Sock, "peers", dict:fetch("peer_id", DictPairs), inet_parse:ntoa(Peer_ip), dict:fetch("port", DictPairs), dict:fetch("uploaded", DictPairs), dict:fetch("downloaded", DictPairs), dict:fetch("left", DictPairs), dict:fetch("info_hash", DictPairs)}};
%%            Response = torerlo_pgsql:db_select_peers(DB, "peers", dict:fetch("info_hash", DictPairs), dict:fetch("peer_id", DictPairs)),
            %% case Response of
            %%     {list, []} -> gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n" ++ "Content-Type: text/plain\r\n\r\n" ++ "ERROR");
            %%     {list, _} -> gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n"),
            %%                  gen_tcp:send(Sock, "Content-Type: text/plain\r\n"),
            %%                  gen_tcp:send(Sock,  torerlo_code:encode({dict, dict:from_list([{<<"interval">>, 20}, {<<"peers">>, Response}])})),
	    %%                  gen_tcp:close(Sock)
            %% end,
        %%    loop_recv(Sock, Pid_database);
        {_,_} ->
            io:format("ERROR\n",[])
    end.    

loop() ->
    receive
        {Sock, DictResponse} ->
            case DictResponse of
                {list, []} -> gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n" ++ "Content-Type: text/plain\r\n\r\n" ++ "ERROR");
                {list, _} -> gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n"),
                             gen_tcp:send(Sock, "Content-Type: text/plain\r\n\r\n"),
                             gen_tcp:send(Sock,  torerlo_code:encode({dict, dict:from_list([{<<"interval">>, 20}, {<<"peers">>, DictResponse}])}))
            end,
            gen_tcp:close(Sock),
	    loop()
    end.
