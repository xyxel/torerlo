-module(torerlo_config).

-export([gets/1]).

gets(Filename) ->
    io:format("Reading configuration file...~n", []),
    {ok, Settings} = file:consult(Filename),
    {value, {_, Servername}} = lists:keysearch(server, 1, Settings),
    io:format("Server: ~p~n", [Servername]),
    {value, {_, Port}} = lists:keysearch(port, 1, Settings),
    io:format("Port: ~p~n", [Port]),
    {value, {_, Database_server}} = lists:keysearch(database, 1, Settings),
    io:format("Database: ~p~n", [Database_server]),
    {value, {_, Database_user}} = lists:keysearch(dbuser, 1, Settings),
    io:format("DB User: ~p~n", [Database_user]),
    {value, {_, Database_passwd}} = lists:keysearch(dbpass, 1, Settings),
    {ok, Servername, Port, Database_server, Database_user, Database_passwd}.
