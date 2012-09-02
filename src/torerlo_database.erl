-module(torerlo_database).

-compile(export_all).

clean_loop(DB, Table_peers) ->
    torerlo_pgsql:db_delete_peers(DB, Table_peers, "peer_time", "15"),
    timer:sleep(15000),
    clean_loop(DB, Table_peers).

db_loop(DB, Pid_response) ->
    receive
        {announce_request_to_db, {Sock, Table_peers, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash}} ->
            io:format("catch announce request to db", []),
            case torerlo_pgsql:db_select_count(DB, {from, Table_peers}, {where_eq, [["peer_id", Client_id], ["torrent_hash", Torrent_hash]]}, {where_not_eq, []}) of
                {ok, 0} -> torerlo_pgsql:db_insert(DB, {into, Table_peers}, {values, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]});
                {ok, _} -> torerlo_pgsql:db_update(DB, {table, Table_peers}, {values, [["peer_id", Client_id], ["peer_ip", Client_ip], ["peer_port", Client_port], ["peer_uploaded", Client_uploaded], ["peer_downloaded", Client_downloaded], ["peer_left", Client_left], ["torrent_hash", Torrent_hash]]})
            end,
	    {ok, Rows} = torerlo_pgsql:db_select(DB, {select, ["peer_ip","peer_port"]}, {from, Table_peers}, {where_eq, [["torrent_hash", Torrent_hash]]}, {where_not_eq, [["peer_id", Client_id]]}),
            Pid_response ! {response_from_db, Sock, "announce", Rows},
            db_loop(DB, Pid_response);
        {scrape_request_to_db, {Sock, Client_ip, HashList}} -> 
            io:format("catch scrape request to db", []),
            Pid_response ! {response_from_db, Sock, "scrape", create_scrape_list(DB, Client_ip, HashList, [])},
            db_loop(DB, Pid_response)
    end.

create_scrape_list(DB, Client_ip, [Torrent_hash | HashList], RespList) ->
    Tablename = "peers",
    {ok, Peers_complete} = torerlo_pgsql:db_select_count(DB, {from, Tablename}, {where_eq, [["torrent_hash", Torrent_hash]]}, {where_not_eq, [["peer_ip", Client_ip]]}),
    {ok, Peers_downloaded} = torerlo_pgsql:db_select_count(DB, {from, Tablename}, {where_eq, [["torrent_hash", Torrent_hash], ["peer_left", "'0'"]]}, {where_not_eq, [["peer_ip", Client_ip]]}),
    {ok, Peers_incomplete} = torerlo_pgsql:db_select_count(DB, {from, Tablename}, {where_eq, [["torrent_hash", Torrent_hash]]}, {where_not_eq, [["peer_ip", Client_ip], ["peer_left", "'0'"]]}),
    create_scrape_list(DB, Client_ip, HashList, lists:append(RespList, [{Torrent_hash, Peers_complete, Peers_downloaded, Peers_incomplete, "torrent_name"}]));
create_scrape_list(DB, Client_ip, [], RespList) ->
    RespList.
