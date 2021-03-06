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

-module(tubby_sup).
-behaviour(supervisor).

% api
-export([start_link/3]).

% supervisor callback.
-export([init/1]).

% @doc Start the supervisor of the tubby_server and the tubby task supervisor.
-spec start_link(Name, MFA, Limit) -> {ok, pid()} | {error, _} | ignore when
	Name :: atom() | {local, atom()} | {global, atom()} | {via, module(), atom()},
	MFA :: mfa(),
	Limit :: pos_integer().
start_link(Name, MFA, Limit) ->
	supervisor:start_link(?MODULE, {Name, MFA, Limit}).

%
init({Name, MFA, Limit}) ->
	{ok, {{one_for_all, 1, 3600},
	[{tubby_server,
	 {tubby_server, start_link, [Name, MFA, Limit]},
	  permanent, 5000, worker, [tubby_server]}]}}.
