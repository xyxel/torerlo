-module(torerlo_pgsql).

-compile(export_all).

db_connect(Servername, Database_user, Database_passwd, Database_name) ->
    {ok, DB} = pgsql:connect(Servername, Database_user, Database_passwd, [{database, Database_name}]),
    {ok, DB}.

loop(DB, Pid_response) ->
    receive
        {request_to_db, {Sock, Table_peers, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash}} ->
            case db_select(DB, Table_peers, Client_id, Torrent_hash) of
                {ok, _, [{0}]} -> Query_insert = string:concat(string:concat("INSERT INTO ", Table_peers), " VALUES ($1, $2, $3, $4, $5, $6, $7, NOW());");
                {ok, _, _} -> Query_insert = string:concat(string:concat("UPDATE ", Table_peers), " SET peer_ip = $2, peer_port = $3, peer_uploaded = $4, peer_downloaded = $5, peer_left = $6, peer_time = NOW() WHERE peer_id = $1 AND torrent_hash = $7")
            end,
            pgsql:equery(DB, Query_insert, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]),
            Query_select = string:concat(string:concat("SELECT peer_ip,peer_port FROM ", Table_peers), " WHERE torrent_hash = $1 AND peer_id != $2"),
            {ok, _, Rows} = pgsql:equery(DB, Query_select, [Torrent_hash, Client_id]),
            Pid_response ! {response_from_db, Sock, Rows}
    end.

db_create(DB, Table_peers) ->
%    io:format("Torrent table creating...~n", []),
%    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_torrent), " (Name char(60), Link char(100), Owner char(20), torrent_hash char(60), torrent_description char(100), torrent_size char(20), torrent_time time)")),
    io:format("Peers table creating...~n", []),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_peers), " (peer_id char(60), peer_ip char(16), peer_port varchar(8), peer_uploaded varchar(20), peer_downloaded varchar(20), peer_left varchar(20), torrent_hash char(60), peer_time time)")).

db_select(DB, Tablename, Client_id, Torrent_hash) ->
    Query = string:concat(string:concat("SELECT COUNT(*) FROM ", Tablename), " WHERE peer_id = $1 AND torrent_hash = $2"),
    pgsql:equery(DB, Query, [Client_id, Torrent_hash]).

db_check_tables(DB, Table_peers) ->
    {ok, _, [{Tables}]} = pgsql:equery(DB, "SELECT COUNT(table_name) FROM information_schema.tables WHERE table_name=$1", [Table_peers]),
    {ok, Tables}.

db_close(DB) ->
    pgsql:close(DB).
