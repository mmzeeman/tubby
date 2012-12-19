%% Some tests

-module(tubby_test).

-include_lib("eunit/include/eunit.hrl").

setup() ->
    application:start(tubby).

teardown(_) ->
    application:stop(tubby).

application_start_stop_test() ->
    ?assertEqual(ok, setup()),
    ?assertEqual(ok, teardown([])).

tubby_test_() ->
    {foreach, local, fun setup/0, fun teardown/1,
     [ ?_test(start_stop_t()),
       ?_test(run_task_t())
     ]
    }.

start_stop_t() ->
	{ok, _Pid} = tubby:start(tobbe, {tubby_test_task, start_link, []}),
	tubby:stop(tobbe).

run_task_t() ->
	{ok, _Pid} = tubby:start(tobbe, {tubby_test_task, start_link, []}, 3),

	%% Start a task 
	{ok, Pid1} = tubby:run(tobbe, ["data 1"]),
	{ok, Pid2} = tubby:run(tobbe, ["data 2"]),
	{ok, Pid3} = tubby:run(tobbe, ["data 3"]),

	%% And use its services.
	{ok, "data 1"} = gen_server:call(Pid1, get_data),
	{ok, "data 2"} = gen_server:call(Pid2, get_data),
	{ok, "data 3"} = gen_server:call(Pid3, get_data),

	%% Trying to run a task fails...
	{error, full} = tubby:run(tobbe, ["data 4"]),

	%% All tasks are still there
	{ok, "data 1"} = gen_server:call(Pid1, get_data),
	{ok, "data 2"} = gen_server:call(Pid2, get_data),
	{ok, "data 3"} = gen_server:call(Pid3, get_data),

	%% Stop one task.
	gen_server:call(Pid1, stop),
	
	%% And I can start a new one
	{ok, Pid4} = tubby:run(tobbe, ["data 4"]),
	{ok, "data 2"} = gen_server:call(Pid2, get_data),
	{ok, "data 3"} = gen_server:call(Pid3, get_data),	
	{ok, "data 4"} = gen_server:call(Pid4, get_data),

	tubby:stop(tobbe).



