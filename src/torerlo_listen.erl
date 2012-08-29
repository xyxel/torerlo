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
            {ok, Mode, DictPairs} = torerlo_parser:parser(Msg, 99),
            {ok, {Peer_ip, Peer_port}} = inet:peername(Sock),
            io:format("mode: ~p~n", [Mode]),
            case Mode of
              "announce" -> Pid_database ! {announce_request_to_db, {Sock, "peers", dict:fetch("peer_id", DictPairs), inet_parse:ntoa(Peer_ip), dict:fetch("port", DictPairs), dict:fetch("uploaded", DictPairs), dict:fetch("downloaded", DictPairs), dict:fetch("left", DictPairs), dict:fetch("info_hash", DictPairs)}};
              "scrape" -> Pid_database ! {scrape_request_to_db, {Sock, inet_parse:ntoa(Peer_ip), dict:fetch("info_hash", DictPairs)}}
            end;
        {_,_} ->
            io:format("ERROR\n",[])
    end.    

loop() ->
    receive
        {response_from_db, Sock, Mode, Rows} ->
            io:format("catch response from db", []),
            case Mode of
              "announce" ->
                DictResponse = create_peers_list(Rows, <<>>),
                gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n"),
                gen_tcp:send(Sock, "Content-Type: text/plain\r\n\r\n"),
                gen_tcp:send(Sock,  torerlo_code:encode({dict, dict:from_list([{<<"interval">>, 20}, {<<"peers">>, DictResponse}])}));
              "scrape" ->
                DictResponse = create_infohash_list(Rows, []),
                gen_tcp:send(Sock, "HTTP/1.0 200 OK\r\n"),
                gen_tcp:send(Sock, "Content-Type: text/plain\r\n\r\n"),
                gen_tcp:send(Sock,  torerlo_code:encode({dict, dict:from_list([{<<"files">>, DictResponse}])}))
            end,
            gen_tcp:close(Sock),
            loop()
    end.

create_peers_list([{Peer_ip, Peer_port} | TailDict], <<>>) ->
    Binary_ip = list_to_binary([list_to_integer(X) || X <- string:tokens(string:strip(binary_to_list(Peer_ip)), ".")]),
    Binary_port = list_to_integer(binary_to_list(Peer_port)),
    create_peers_list(TailDict, <<Binary_ip/binary, Binary_port:16>>);
create_peers_list([{Peer_ip, Peer_port} | TailDict], Acc) ->
    Binary_ip = list_to_binary([list_to_integer(X) || X <- string:tokens(string:strip(binary_to_list(Peer_ip)), ".")]),
    Binary_port = list_to_integer(binary_to_list(Peer_port)),
    create_peers_list(TailDict, <<Acc/binary, Binary_ip/binary, Binary_port:16>>);
create_peers_list([], Acc) ->
    Acc.

create_infohash_list([{Torrent_hash, Peers_complete, Peers_downloaded, Peers_incomplete, Torrent_name} | TailDict], []) ->
    create_infohash_list(TailDict, [{dict, dict:from_list([{Torrent_hash, {dict, dict:from_list([{<<"complete">>, Peers_complete}, {<<"downloaded">>, Peers_downloaded}, {<<"incomplete">>, Peers_incomplete}])}}])}]);
create_infohash_list([{Torrent_hash, Peers_complete, Peers_downloaded, Peers_incomplete, Torrent_name} | TailDict], Acc) ->
    create_infohash_list(TailDict, lists:append(Acc, [{dict, dict:from_list([{Torrent_hash, {dict, dict:from_list([{<<"complete">>, Peers_complete}, {<<"downloaded">>, Peers_downloaded}, {<<"incomplete">>, Peers_incomplete}])}}])}]));
create_infohash_list([], Acc) ->
    {list, Acc}.

