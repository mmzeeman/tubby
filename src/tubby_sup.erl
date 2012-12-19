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

-module(tubby_sup).

-export([start_link/3, init/1]).

-behaviour(supervisor).
 
start_link(Name, MFA, Limit) ->
	supervisor:start_link(?MODULE, {Name, MFA, Limit}).
 
init({Name, MFA, Limit}) ->
	{ok, {{one_for_all, 1, 3600},
	[{tubby_server,
	 {tubby_server, start_link, [Name, MFA, Limit]},
	  permanent, 5000, worker, [tubby_server]}]}}.
