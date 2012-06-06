-module(torerelo_listen).

-export([listen/0]).

listen() ->
    receive
        {request, _Message} ->
            io:format("message: ~s\n",[_Message]),
            listen();
        {_,_} ->
            io:format("ERROR\n",[])
    end.