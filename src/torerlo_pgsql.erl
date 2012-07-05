-module(torerlo_pgsql).

-compile(export_all).

db_connect(Servername, Database_user, Database_passwd, Database_name) ->
    {ok, DB} = pgsql:connect(Servername, Database_user, Database_passwd, [{database, Database_name}]),
    {ok, DB}.

db_create(DB, Table_torrent, Table_peers, Table_seeds) ->
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_torrent), " (Name char(20), Link char(100), Owner char(20), Checksum char(30))")),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_peers), " (Name char(20), Torrent_Name char(20))")),
    pgsql:equery(DB, string:concat(string:concat("CREATE TABLE ", Table_seeds), " (Name char(20), Torrent_Name char(20))")).

db_select(DB, Tablename, Field) ->
    Query = string:concat(string:concat(string:concat("SELECT ", Field), " FROM "), Tablename),
    pgsql:equery(DB, Query).

%db_update(DB, ) ->
%    pgsql:equery(DB, "UPDATE $1 SET 

db_insert(DB, Tablename, Name_torrent, Link_torrent, Owner_torrent, Checksum_torrent) ->
    Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2, $3, $4);"),
    pgsql:equery(DB, Query, [Name_torrent,Link_torrent,Owner_torrent,Checksum_torrent]).

db_insert(DB, Tablename, Name_table, Name_torrent_table) ->
%    case Tablename of
%        peers ->
%            pgsql:equery(DB, "INSERT INTO peers VALUES ($1,$2);", [Name_table,Name_torrent_table]);
%        seeds ->
%            pgsql:equery(DB, "INSERT INTO seeds VALUES ($1,$2);", [Name_table,Name_torrent_table])
%    end.
    Query = string:concat(string:concat("INSERT INTO ", Tablename), " VALUES ($1, $2);"),
    pgsql:equery(DB, Query, [Name_table,Name_torrent_table]).

db_close(DB) ->
    pgsql:close(DB).
