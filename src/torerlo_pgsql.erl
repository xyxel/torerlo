-module(torerlo_pgsql).

-compile(export_all).


db_connect(Servername, Database_user, Database_passwd, Database_name) ->
    {ok, DB} = pgsql:connect(Servername, Database_user, Database_passwd, [{database, Database_name}]),
    {ok, DB}.


db_create(DB, Tablename, {field, Field_list}) ->
    io:format(string:concat(Tablename, " table creating...~n"), []),
    Query = query_create(string:join(["CREATE TABLE", Tablename, "("], " "), Field_list),
    pgsql:equery(DB, Query).    
    
query_create(Acc, [Field | Field_list]) ->
    case Field of
	"peer_id"         -> query_create(string:concat(Acc, "peer_id varchar(60)"), Field_list);
	"peer_ip"         -> query_create(string:concat(Acc, "peer_ip char(16)"), Field_list);
	"peer_port"       -> query_create(string:concat(Acc, "peer_port varchar(8)"), Field_list);
	"peer_uploaded"   -> query_create(string:concat(Acc, "peer_uploaded varchar(20)"), Field_list);
	"peer_downloaded" -> query_create(string:concat(Acc, "peer_downloaded varchar(20)"), Field_list);
	"peer_left"       -> query_create(string:concat(Acc, "peer_left varchar(20)"), Field_list);
	"torrent_hash"    -> query_create(string:concat(Acc, "torrent_hash varchar(60)"), Field_list);
	"peer_time"       -> query_create(string:concat(Acc, "peer_time time"), Field_list);
	"torrent_name"    -> query_create(string:concat(Acc, "torrent_name varchar(60)"), Field_list);
	"torrent_link"    -> query_create(string:concat(Acc, "torrent_link varchar(100)"), Field_list);
	"torrent_owner"   -> query_create(string:concat(Acc, "torrent_owner varchar(20)"), Field_list);
	"torrent_desc"    -> query_create(string:concat(Acc, "torrent_desc text"), Field_list);
	"torrent_size"    -> query_create(string:concat(Acc, "torrent_size varchar(20)"), Field_list);
	"torrent_time"    -> query_create(string:concat(Acc, "torrent_time time"), Field_list)
    end;
query_create(Acc, []) ->
    string:concat(Acc, ")").
	

db_select_count(DB, {from, Tablename}, {where_eq, []}, {where_not_eq, []}) ->
    Query = string:join(["SELECT COUNT(*) FROM", Tablename], " "),
    {ok, _, [{Count}]} = pgsql:equery(DB, Query, []),
    {ok, Count};
db_select_count(DB, {from, Tablename}, {where_eq, Eq_list}, {where_not_eq, Eq_not_list}) ->
    Pre_query = string:join(["SELECT COUNT(*) FROM", Tablename, "WHERE "], " "),
    Last_query = string:join(query_select(query_select([], Eq_list, "="), Eq_not_list, "!="), " AND "),
    Query = string:concat(Pre_query, Last_query),
    {ok, _, [{Count}]} = pgsql:equery(DB, Query, []),
    {ok, Count}.

db_select(DB, {select, Selected_list}, {from, Tablename}, {where_eq, []}, {where_not_eq, []}) ->
    Query = string:join(["SELECT", select:join(Selected_list, ","), "FROM", Tablename], " "),
    {ok, _, Rows} = pgsql:equery(DB, Query, []),
    {ok, Rows};
db_select(DB, {select, Selected_list}, {from, Tablename}, {where_eq, Eq_list}, {where_not_eq, Eq_not_list}) ->
    Pre_query = string:join(["SELECT", string:join(Selected_list, ","), "FROM", Tablename, "WHERE "], " "),
    Last_query = string:join(query_select(query_select([], Eq_list, "="), Eq_not_list, "!="), " AND "),
    Query = string:concat(Pre_query, Last_query),
    {ok, _, Rows} = pgsql:equery(DB, Query, []),
    {ok, Rows}.

query_select(Acc, [[Eq_key, Eq_value] | Eq_list], Operator) ->
    query_select(lists:append(Acc, [string:join([Eq_key, Operator, string:join(["'", Eq_value, "'"], ""), " "], " ")]), Eq_list, Operator);
query_select(Acc, [], Operator) ->
    Acc.


%db_insert_peers(DB, Table_peers, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash) ->
%    Query = string:concat(string:concat("INSERT INTO ", Table_peers), " VALUES ($1, $2, $3, $4, $5, $6, $7, NOW());"),
%    pgsql:equery(DB, Query, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]),
%   {ok, DB}.

db_insert(DB, {into, Tablename}, {values, Values_list}) ->
    Query = string:join(["INSERT INTO", Tablename, "VALUES (", string:join(lists:map(fun(Values) -> string:join(["'", Values, "'"], "") end, Values_list), ", "), ", NOW())"], " "),
    io:format("insert: ~w~n", [Query]),
    pgsql:equery(DB, Query, []),
    {ok, DB}.

%db_update_peers(DB, Table_peers, Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash) ->
 %   Query = string:concat(string:concat("UPDATE ", Table_peers), " SET peer_ip = $2, peer_port = $3, peer_uploaded = $4, peer_downloaded = $5, peer_left = $6, peer_time = NOW() WHERE peer_id = $1 AND torrent_hash = $7"),
 %   pgsql:equery(DB, Query, [Client_id, Client_ip, Client_port, Client_uploaded, Client_downloaded, Client_left, Torrent_hash]),
 %   {ok, DB}.


db_update(DB, {table, Tablename}, {values, Values_list}) ->
    Query = string:join(["UPDATE", Tablename, "SET", string:join(query_update(Values_list, []), ",")], " "),
    pgsql:equery(DB, Query, []),
    {ok, DB}.

query_update([[Parameter_key, Parameter_value] | Values_list], Acc) ->
    query_update(Values_list, lists:append(Acc, string:join([Parameter_key, "=", Parameter_value], " ")));
query_update([], Acc) ->
    Acc.


db_delete_peers(DB, Tablename, Field, Minutes) ->
    Query = string:join(["DELETE FROM", Tablename, "WHERE", Field, "< localtime - interval '", Minutes, "minutes'"], " "),
    pgsql:equery(DB, Query, []),
    {ok, DB}.

db_check_tables(DB, Tablename) ->
    {ok, _, [{Tables}]} = pgsql:equery(DB, "SELECT COUNT(table_name) FROM information_schema.tables WHERE table_name=$1", [Tablename]),
    {ok, Tables}.

db_close(DB) ->
    pgsql:close(DB).
