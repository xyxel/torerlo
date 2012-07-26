-module(torerlo_pgsql).

-compile(export_all).

db_connect(Servername, Database_user, Database_passwd, Database_name) ->
    {ok, DB} = pgsql:connect(Servername, Database_user, Database_passwd, [{database, Database_name}]),
    {ok, DB}.

db_create(DB, Table_torrent, Table_peers, Table_seeds) ->
    io:format("Torrent table creating...~n", []),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_torrent), " (Name char(20), Link char(100), Owner char(20), torrent_hash char(20), torrent_description char(100), torrent_size char(20), torrent_time time)")),
    io:format("Peers table creating...~n", []),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_peers), " (peer_id char(20), peer_ip char(16), peer_port varchar(8), peer_uploaded varchar(20), peer_downloaded varchar(20), peer_left varchar(20), torrent_hash char(20), peer_time time)")),
    io:format("Seeds table creating...~n", []),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_seeds), " (seed_id char(20), seed_ip char(16), seed_port varchar(8), seed_uploaded varchar(20), seed_downloaded varchar(20), seed_left varchar(20), torrent_hash char(20), seed_time time)")).

db_select_peers(DB, Table_peers, Torrent_hash, Peer_id) ->
    Query = string:concat(string:concat("SELECT peer_id,peer_ip,peer_port FROM ", Table_peers), " WHERE torrent_hash = $1 AND peer_id != $2"),
    {ok, _, Rows} = pgsql:equery(DB, Query, [Torrent_hash, Peer_id]),
    {list, create_peers_list(Rows, [])}.

create_peers_list([{Peer_id, Peer_ip, Peer_port} | TailDict], []) ->
    create_peers_list(TailDict, lists:append([], [{dict, dict:from_list([{<<"peer_id">>, Peer_id},{<<"ip">>, Peer_ip}, {<<"port">>, Peer_port}])}]));
create_peers_list([{Peer_id, Peer_ip, Peer_port} | TailDict], Acc) ->
    create_peers_list(TailDict, lists:append(Acc, [{dict, dict:from_list([{<<"peer_id">>, Peer_id},{<<"ip">>, Peer_ip}, {<<"port">>, Peer_port}])}]));
create_peers_list([], Acc) ->
    Acc.

db_select(DB, Tablename, Client_id, Torrent_hash) ->
    Query = string:concat(string:concat("SELECT COUNT(*) FROM ", Tablename), " WHERE peer_id = $1 AND torrent_hash = $2"),
    pgsql:equery(DB, Query, [Client_id, Torrent_hash]).

db_insert(DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Hash_torrent, Desc_torrent, Size_torrent) ->
    Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2, $3, $4, $5, $6, NOW());"),
    pgsql:equery(DB, Query, [Name_torrent, Link_torrent, Owner_torrent, Hash_torrent, Desc_torrent, Size_torrent]).

db_insert(DB, Tablename, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash) ->
    case db_select(DB, Tablename, Client_id, Torrent_hash) of
        {ok, _, [{0}]} -> Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2, $3, $4, $5, $6, $7, NOW());");
        {ok, _, _} -> Query = string:concat(string:concat("UPDATE ", Tablename), " SET peer_ip = $2, peer_port = $3, peer_uploaded = $4, peer_downloaded = $5, peer_left = $6, peer_time = NOW() WHERE peer_id = $1 AND torrent_hash = $7")
    end,
    pgsql:equery(DB, Query, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]),
    {ok, {}}.

db_check_tables(DB, Table_torrent, Table_peers, Table_seeds) ->
    {ok, _, [{Tables}]} = pgsql:equery(DB, "SELECT COUNT(table_name) FROM information_schema.tables WHERE table_name=$1 or table_name=$2 or table_name=$3", [Table_torrent, Table_peers, Table_seeds]),
    {ok, Tables}.

db_close(DB) ->
    pgsql:close(DB).
