-module(erlcloud_aws_tests).
-include_lib("eunit/include/eunit.hrl").

request_test_() ->
    {foreach,
     fun start/0,
     fun stop/1,
     [fun request_default_test/1,
      fun request_prot_host_port_str_test/1,
      fun request_prot_host_port_int_test/1]}.

start() ->
    meck:new(ibrowse),
    meck:expect(ibrowse, send_req, fun(_, _, _) -> {ok, "200", [], ok} end),
    ok.

stop(_) ->
    meck:unload(ibrowse).

request_default_test(_) ->
    ok = erlcloud_aws:aws_request(get, "host", "/", [], "id", "key"),
    Url = get_url_from_history(meck:history(ibrowse)),
    test_url(https, "host", 443, "/", Url).

request_prot_host_port_str_test(_) ->
    ok = erlcloud_aws:aws_request(get, "http", "host1", "9999", "/path1", [], "id", "key"),
    Url = get_url_from_history(meck:history(ibrowse)),
    test_url(http, "host1", 9999, "/path1", Url).

request_prot_host_port_int_test(_) ->
    ok = erlcloud_aws:aws_request(get, "http", "host1", 9999, "/path1", [], "id", "key"),
    Url = get_url_from_history(meck:history(ibrowse)),
    test_url(http, "host1", 9999, "/path1", Url).

% ==================
% Internal functions
% ==================

get_url_from_history([{_, {ibrowse, send_req, [Url, _, _]}, _}]) ->
    Url.

test_url(ExpScheme, ExpHost, ExpPort, ExpPath, Url) ->
    {ok, {Scheme, _UserInfo, Host, Port, Path, _Query}} = http_uri:parse(Url),
    [?_assertEqual(ExpScheme, Scheme),
     ?_assertEqual(ExpHost, Host),
     ?_assertEqual(ExpPort, Port),
     ?_assertEqual(ExpPath, Path)].
