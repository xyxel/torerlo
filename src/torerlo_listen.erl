-module(torerlo_listen).

-export([listen/5,response_code/2]).

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
            gen_tcp:send(Sock, response_code(torerlo_pgsql:db_select_peers(DB, "peers", dict:fetch("info_hash", DictPairs)), [])),
            loop_recv(Sock, DB);
        {_,_} ->
            io:format("ERROR\n",[])
    end.

response_code([{Id, _, _} | TailDict], []) ->
    response_code(TailDict, binary_to_list(Id));
response_code([{Id, _, _} | TailDict], Acc) ->
    response_code(TailDict, string:concat(Acc, binary_to_list(Id)));
response_code([], Acc) ->
    Acc.
    
