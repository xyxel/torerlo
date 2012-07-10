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

db_select(DB, Tablename, Field) ->
    Query = string:concat(string:concat(string:concat("SELECT ", Field), " FROM "), Tablename),
    pgsql:equery(DB, Query).

%db_update(DB, ) ->
%    pgsql:equery(DB, "UPDATE $1 SET 

db_insert(DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Hash_torrent, Desc_torrent, Size_torrent) ->
    Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2, $3, $4, $5, $6, NOW);"),
    pgsql:equery(DB, Query, [Name_torrent, Link_torrent, Owner_torrent, Hash_torrent, Desc_torrent, Size_torrent]).

db_insert(DB, Tablename, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash) ->
%    case Tablename of
%        peers ->
%            pgsql:equery(DB, "INSERT INTO peers VALUES ($1,$2);", [Name_table,Name_torrent_table]);
%        seeds ->
%            pgsql:equery(DB, "INSERT INTO seeds VALUES ($1,$2);", [Name_table,Name_torrent_table])
%    end.
    Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2, $3, $4, $5, $6, $7, NOW);"),
    pgsql:equery(DB, Query, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]).

db_check_tables(DB, Table_torrent, Table_peers, Table_seeds) ->
    {ok, _, [{Tables}]} = pgsql:equery(DB, "SELECT COUNT(table_name) FROM information_schema.tables WHERE table_name=$1 or table_name=$2 or table_name=$3", [Table_torrent, Table_peers, Table_seeds]),
    {ok, Tables}.

db_close(DB) ->
    pgsql:close(DB).
