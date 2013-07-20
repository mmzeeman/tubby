%% @author Maas-Maarten Zeeman <mmzeeman@xs4all.nl>
%% @copyright 2012, 2013 Maas-Maarten Zeeman
%%
%% @doc Process Pool for Tasks.
%%
%% Copyright 2012, 2013 Maas-Maarten Zeeman
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

-module(tubby_app_sup).
-behaviour(supervisor).

-export([
	start_link/0, 
	start_child/1, 
	stop_child/1
]).

% supervisor callback.
-export([init/1]).

% @doc The module is a supervisor. 
-spec start_link() -> {ok, pid()} | {error, _} | ignore.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

% @doc Start a dynamic child.
start_child(ChildSpec) ->
    supervisor:start_child(?MODULE, ChildSpec).

% @doc Stop a child of the app supervisor. This terminates, and
% delete's it.
stop_child(Name) ->
    case supervisor:terminate_child(?MODULE, Name) of
        ok -> supervisor:delete_child(?MODULE, Name);
        {error, _}=Error -> Error
    end.

% supervisor api 
init(_Args) ->
    {ok, {{one_for_one, 20, 3600}, []}}.