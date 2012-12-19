%% @author Maas-Maarten Zeeman <mmzeeman@xs4all.nl>
%% @copyright 2012 Maas-Maarten Zeeman
%%
%% @doc Process Pool for Tasks.
%%
%% Copyright 2012 Maas-Maarten Zeeman
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%% 
%%     http://www.apache.org/licenses/LICENSE-2.0
%% 
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.


-module(tubby_server).
-behaviour(gen_server).

%%
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         code_change/3, terminate/2]).

-export([
    start/4, 
    start_link/3,
    start_link/4, 
    run/2, 
    queue_wait/2, queue_wait/3,
    queue/2, 
    stop/1
]).

-record(state, {
    limit=0,            % The number of tasks which can be started. 
    task_sup,           % The task supervisors.
    refs,               % References to currently running tasks.
    waiting=queue:new()   % waiting
}).

-record(task, {
    from=undefined,
    args=undefined
}).

start(Name, Sup, MFA, Limit) when is_atom(Name), is_integer(Limit) ->
    start({local, Name}, Sup, MFA, Limit);
start(Name, Sup, MFA, Limit) when is_integer(Limit) ->
    gen_server:start(Name, ?MODULE, {Sup, MFA, Limit}, []).

start_link(Name, MFA, Limit) ->
    start_link(Name, self(), MFA, Limit).

start_link(Name, Sup, MFA, Limit) when is_atom(Name), is_integer(Limit) ->
    start_link({local, Name}, Sup, MFA, Limit);
start_link(Name, Sup, MFA, Limit) when is_integer(Limit) ->
    gen_server:start_link(Name, ?MODULE, {Sup, MFA, Limit}, []).

% @doc Start a task on pool Name with Args. When there is no room in the
% pool the task is not started.
run(Name, Args) ->
    gen_server:call(Name, {run, Args}).

% @doc Start a task on pool Name with Args and wait until it is started.
queue_wait(Name, Args) ->
    queue_wait(Name, Args, infinity).

% @doc Start a task on pool Name with Args and wait until it is started.
% Times out after Timout milliseconds.
queue_wait(Name, Args, Timeout) ->
    gen_server:call(Name, {sync, Args}, Timeout).

% @doc Start a task on pool Name with Args, continue immediately.
queue(Name, Args) ->
    gen_server:cast(Name, {async, Args}).

% @doc Stop the pool. Also stops all currently running tasks.
stop(Name) ->
    gen_server:call(Name, stop).

%% Gen server callbacks
init({Sup, MFA, Limit}) ->
    self() ! {start_task_supervisor, Sup, MFA},
    {ok, #state{limit=Limit, refs=sets:new()}}.

handle_call({run, Args}, _From, #state{limit=N, task_sup=Sup, refs=Refs}=State) when N > 0 ->
    {Pid, NewRefs} = start_and_monitor(Sup, Args, Refs),
    {reply, {ok, Pid}, State#state{limit=N-1, refs=NewRefs}};
handle_call({run, _Args}, _From, S=#state{limit=N}) when N =< 0 ->
    {reply, {error, full}, S};

handle_call({sync, Args}, _From, #state{limit=N, task_sup=Sup, refs=Refs}=State) when N > 0 ->
    {Pid, NewRefs} = start_and_monitor(Sup, Args, Refs),
    {reply, {ok, Pid}, State#state{limit=N-1, refs=NewRefs}};
handle_call({sync, Args}, From, #state{waiting=Waiting}=State) ->
    Waiting1 = queue:in(#task{from=From, args=Args}, Waiting),
    {noreply, State#state{waiting=Waiting1}};

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};
handle_call(Msg, _From, State) ->
    {stop, {unknown_call, Msg}, State}.

% @doc 
handle_cast({async, Args}, #state{limit=N, task_sup=Sup, refs=Refs}=State) when N > 0 ->
    {_Pid, NewRefs} = start_and_monitor(Sup, Args, Refs),
    {noreply, State#state{limit=N-1, refs=NewRefs}};
handle_cast({async, Args}, #state{limit=N, waiting=Waiting}=State) when N =< 0 ->
    Waiting1 = queue:in(#task{args=Args}, Waiting),
    {noreply, State#state{waiting=Waiting1}};
handle_cast(Msg, State) ->
    {stop, {unknown_cast, Msg}, State}.
    

% @doc
handle_info({'DOWN', Ref, process, _Pid, _}, #state{}=State) ->
    NewState = case sets:is_element(Ref, State#state.refs) of
        true -> handle_task_down(Ref, State);
        false -> State
    end,
    {noreply, NewState};
handle_info({start_task_supervisor, Sup, MFA}, #state{}=State) ->
    Spec = {tubby_task_sup,
         {tubby_task_sup, start_link, [MFA]},
          permanent, 10000, supervisor, [tubby_worker_sup]},
    {ok, Pid} = supervisor:start_child(Sup, Spec),
    {noreply, State#state{task_sup=Pid}};
handle_info(_Msg, State) ->
    {noreply, State}.

% @doc
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

terminate(_Reason, _State) ->
    ok.

handle_task_down(Ref, #state{limit=L, task_sup=Sup, refs=Refs}=State) ->
    RefsDel = sets:del_element(Ref, Refs),

    %% There is room to start a task from the queue
    case queue:out(State#state.waiting) of
        {{value, #task{from=From, args=Args}}, Waiting1} ->
            {Pid, NewRefs} = start_and_monitor(Sup, Args, RefsDel),
            case From of
                undefined -> ok;
                _ -> gen_server:reply(From, {ok, Pid})
            end,
            State#state{refs=NewRefs, waiting=Waiting1};
        {empty, _} ->
            State#state{limit=L+1, refs=RefsDel}
    end.

start_and_monitor(Sup, Args, Refs) ->
    {ok, Pid} = supervisor:start_child(Sup, Args),
    NewRef = erlang:monitor(process, Pid),
    {Pid, sets:add_element(NewRef, Refs)}.
