-module(torerlo_listen).

-export([listen/5]).

listen(DB, Database_name, Database_user, Database_passwd, Port) ->
    {ok, LSock} = gen_tcp:listen(Port,[list,{active,false}]),
    loop_accept(LSock, DB).

loop_accept(LSock, DB) ->
%    {ok, Sock} = gen_tcp:accept(LSock),
    case gen_tcp:accept(LSock) of
        {ok, Sock} ->
            loop_recv(Sock, DB),
            loop_accept(LSock, DB);
        {_,_} ->
            io:format("ACCEPT ERROR\n",[])
    end.

loop_recv(Sock, DB) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, Msg} ->
%            Msg = process(Data),
            io:format("message: ~p~n",[Msg]),
            {ok, DictPairs} = torerlo_parser:parser(Msg, 99),
            torerlo_pgsql:db_insert(DB, "peers", dict:fetch("peer_id", DictPairs), dict:fetch("ip", DictPairs), dict:fetch("port", DictPairs), dict:fetch("uploaded", DictPairs), dict:fetch("downloaded", DictPairs), dict:fetch("left", DictPairs), dict:fetch("info_hash", DictPairs)),
            gen_tcp:send(Sock, "Catch!"),
            loop_recv(Sock, DB);
        {_,_} ->
            io:format("ERROR\n",[])
    end.
