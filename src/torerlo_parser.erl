-module(torerlo_parser).

-import(string, [tokens/2]).

-export([parser/2]).

parser(Request, Pid) ->
    [URL, URLReqPairs] = tokens(Request, "?"),
    ReqPairs = tokens(URLReqPairs, "&"),
    Pairs = lists:map(fun(Pair) -> list_to_tuple(string:tokens(Pair, "=")) end, ReqPairs),
    ReqDict = dict:from_list(Pairs),
    {ok, ReqDict}.

