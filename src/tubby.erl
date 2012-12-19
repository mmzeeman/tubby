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

-module(tubby).

-export([
	start/2, start/3, 
	stop/1, 
	run/2, 
	queue_wait/2, 
	queue/2
]).


% @doc Start a new process pool.
start(Name, MFA) ->
	start(Name, MFA, 100).

start(Name, MFA, Limit) ->
    ChildSpec = {Name, 
    	{tubby_sup, start_link, [Name, MFA, Limit]},
    	 permanent, 11000, supervisor, [tubby_sup]},

    tubby_app_sup:start_child(ChildSpec).

% @doc Stop a process pool.
stop(Name) ->
	tubby_app_sup:stop_child(Name).

% @doc Run a task on pool Name
run(Name, Args) ->
    tubby_server:run(Name, Args).

% @doc Queue a task on pool Name and wait for it to start.
queue_wait(Name, Args) ->
	queue_wait(Name, Args, infinity).

% @doc Queue a task on pool Name and wait for it to start.
queue_wait(Name, Args, Timeout) ->
    tubby_server:queue_wait(Name, Args, Timeout).

% @doc Queue task on pool Name and continue immediately.
queue(Name, Args) ->
    tubby_server:queue(Name, Args).


