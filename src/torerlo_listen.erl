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
            Pid_database ! {request_to_db, {Sock, "peers", dict:fetch("peer_id", DictPairs), inet_parse:ntoa(Peer_ip), dict:fetch("port", DictPairs), dict:fetch("uploaded", DictPairs), dict:fetch("downloaded", DictPairs), dict:fetch("left", DictPairs), dict:fetch("info_hash", DictPairs)}};
        {_,_} ->
            io:format("ERROR\n",[])
    end.    

loop() ->
    receive
        {response_from_db, Sock, Rows} ->
            gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n"),
            gen_tcp:send(Sock, "Content-Type: text/plain\r\n\r\n"),
            DictResponse = create_peers_list(Rows, <<>>),
            gen_tcp:send(Sock,  torerlo_code:encode({dict, dict:from_list([{<<"interval">>, 20}, {<<"peers">>, DictResponse}])})),
            gen_tcp:close(Sock),
            loop()
    end.

create_peers_list([{Peer_ip, Peer_port} | TailDict], <<>>) ->
%    Acc = list_to_binary([]),
    Binary_ip = list_to_binary([list_to_integer(X) || X <- string:tokens(string:strip(binary_to_list(Peer_ip)), ".")]),
    Binary_port = list_to_integer(binary_to_list(Peer_port)),
    create_peers_list(TailDict, <<Binary_ip/binary, Binary_port:16>>);
create_peers_list([{Peer_ip, Peer_port} | TailDict], Acc) ->
    Binary_ip = list_to_binary([list_to_integer(X) || X <- string:tokens(string:strip(binary_to_list(Peer_ip)), ".")]),
    Binary_port = list_to_integer(binary_to_list(Peer_port)),
    create_peers_list(TailDict, <<Acc/binary, Binary_ip/binary, Binary_port:16>>);
create_peers_list([], Acc) ->
    Acc.
