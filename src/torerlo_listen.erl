-module(torerlo_listen).

-export([listen/4]).

listen(Database_name, Database_user, Database_passwd, Port) ->
    {ok, LSock} = gen_tcp:listen(Port,[list,{active,false}]),
    loop_accept(LSock).

loop_accept(LSock) ->
%    {ok, Sock} = gen_tcp:accept(LSock),
    case gen_tcp:accept(LSock) of
        {ok, Sock} ->
            loop_recv(Sock),
            loop_accept(LSock);
        {_,_} ->
            io:format("ACCEPT ERROR\n",[])
    end.

loop_recv(Sock) ->
    case gen_tcp:recv(Sock, 0) of
        {ok, Msg} ->
%            Msg = process(Data),
            io:format("message: ~p~n",[Msg]),
            gen_tcp:send(Sock, "Catch!"),
            loop_recv(Sock);
        {_,_} ->
            io:format("ERROR\n",[])
    end.