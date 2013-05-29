-module(erlcloud_sdb_tests).
-include_lib("eunit/include/eunit.hrl").

create_chain(Response) ->
    add_response_to_chain([], Response).

add_response_to_chain(Chain, Response) ->
    Chain ++ [Response].

expect_chain([Response | Chain]) ->
    meck:expect(ibrowse, send_req,
                fun(_, _, _, _) ->
                        expect_chain(Chain),
                        Response
                end);
expect_chain([]) ->
    ok.

setup() ->
    erlcloud_sdb:configure("fake", "fake-secret"),
    meck:new(ibrowse).

cleanup() ->
    meck:unload(ibrowse).

single_result_response() ->
    "<SelectResponse>
  <SelectResult>
    <Item>
      <Name>item0</Name>
      <Attribute><Name>Color</Name><Value>Black</Value></Attribute>
    </Item>
  </SelectResult>
  <ResponseMetadata>
    <RequestId>b1e8f1f7-42e9-494c-ad09-2674e557526d</RequestId>
    <BoxUsage>0.1</BoxUsage>
  </ResponseMetadata>
</SelectResponse>".

select_single_response_test() ->
    setup(),
    expect_chain(create_chain({ok, "200", [], single_result_response()})),

    Result = erlcloud_sdb:select("select"),
    Items = proplists:get_value(items, Result),
    ?assertEqual(1, length(Items)),

    cleanup().

select_failure_test() ->
    setup(),
    expect_chain(create_chain({error, {conn_failed,{error,ssl_not_started}}})),

    {'EXIT', {Error, _Stack}} = (catch erlcloud_sdb:select("select")),
    ?assertEqual({aws_error,{socket_error,{conn_failed,{error,ssl_not_started}}}}, Error),

    cleanup().

select_503_test() ->
    setup(),
    Chain = create_chain({ok, "503", [], ""}),
    expect_chain(add_response_to_chain(Chain, {ok, "200", [], single_result_response()})),

    Result = erlcloud_sdb:select("select"),
    Items = proplists:get_value(items, Result),
    ?assertEqual(1, length(Items)),

    cleanup().
