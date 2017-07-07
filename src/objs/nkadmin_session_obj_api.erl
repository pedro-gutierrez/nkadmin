%% -------------------------------------------------------------------
%%
%% Copyright (c) 2017 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc Session Object API
-module(nkadmin_session_obj_api).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([cmd/2]).

-include("nkadmin.hrl").
-include_lib("nkdomain/include/nkdomain.hrl").
-include_lib("nkevent/include/nkevent.hrl").
-include_lib("nkservice/include/nkservice.hrl").


-define(ADMIN_DEF_EVENT_TYPES, [
    <<"update_elements">>,
    <<"unloaded">>
]).


%% ===================================================================
%% API
%% ===================================================================

%% @doc
cmd(<<"find">>, _Req) ->
    {error, session_not_found};

cmd(<<"create">>, Req) ->
    cmd(<<"start">>, Req);

cmd(<<"start">>, #nkreq{session_module=nkapi_server}=Req) ->
    #nkreq{data=Data, session_pid=Pid, user_id=UserId, srv_id=SrvId} = Req,
    case nkdomain_api_util:get_id(?DOMAIN_DOMAIN, domain_id, Data, Req) of
        {ok, DomainId} ->
            Opts1 = maps:with([domain_id, url, language], Data),
            Opts2 = Opts1#{session_link => {nkapi_server, Pid}},
            case nkadmin_session_obj:start(SrvId, DomainId, UserId, Opts2) of
                {ok, #{session_id:=SessId}=Reply} ->
                    Types = maps:get(events, Data, ?ADMIN_DEF_EVENT_TYPES),
                    Subs = #{
                        srv_id => SrvId,
                        class => ?DOMAIN_EVENT_CLASS,
                        subclass => ?DOMAIN_ADMIN_SESSION,
                        type => Types,
                        obj_id => SessId
                    },
                    ok = nkapi_server:subscribe(Pid, Subs),
                    Req2 = nkdomain_api_util:add_id(?DOMAIN_ADMIN_SESSION, SessId, Req),
                    Req3 = nkdomain_api_util:add_meta(nkadmin_session_types, Types, Req2),
                    {ok, Reply, Req3};
                {error, Error} ->
                    {error, Error}
            end;
        {error, Error} ->
            {error, Error}
    end;

cmd(<<"stop">>, #nkreq{data=Data, session_pid=Pid, srv_id=SrvId, user_state=UserState}=Req) ->
    case nkdomain_api_util:get_id(?DOMAIN_ADMIN_SESSION, Data, Req) of
        {ok, SessId} ->
            Req2 = case UserState of
                #{nkadmin_session_types:=Types} ->
                    Subs = #{
                        srv_id => SrvId,
                        class => ?DOMAIN_EVENT_CLASS,
                        subclass => ?DOMAIN_ADMIN_SESSION,
                        type => Types,
                        obj_id => SessId
                    },
                    nkapi_server:unsubscribe(Pid, Subs),
                    nkdomain_api_util:remove_meta(nkadmin_session_types, Req);
                _ ->
                    Req
            end,
            case nkdomain:unload(SrvId, SessId, user_stop) of
                ok ->
                    {ok, #{}, Req2};
                {error, Error} ->
                    {error, Error}
            end;
        {error, Error} ->
            {error, Error}
    end;

cmd(<<"switch_domain">>, #nkreq{data=#{domain_id:=DomId}=Data, srv_id=SrvId}=Req) ->
    case nkdomain_api_util:get_id(?DOMAIN_ADMIN_SESSION, Data, Req) of
        {ok, SessId} ->
            case nkadmin_session_obj:switch_domain(SrvId, SessId, DomId) of
                {ok, Reply} ->
                    {ok, Reply};
                {error, Error} ->
                    {error, Error}
            end;
        {error, Error} ->
            {error, Error}
    end;

cmd(<<"element_action">>, #nkreq{data=Data, srv_id=SrvId}=Req) ->
    #{element_id:=ElementId, action:=Action} = Data,
    Value = maps:get(value, Data, <<>>),
    case nkdomain_api_util:get_id(?DOMAIN_ADMIN_SESSION, Data, Req) of
        {ok, SessId} ->
            case nkadmin_session_obj:element_action(SrvId, SessId, ElementId, Action, Value) of
                {ok, Reply} ->
                    {ok, Reply};
                {error, Error} ->
                    {error, Error}
            end;
        {error, Error} ->
            {error, Error}
    end;

cmd(<<"get_data">>, #nkreq{data=Data, srv_id=SrvId}=Req) ->
    #{element_id:=ElementId} = Data,
    case nkdomain_api_util:get_id(?DOMAIN_ADMIN_SESSION, Data, Req) of
        {ok, SessId} ->
            case nkadmin_session_obj:get_data(SrvId, SessId, ElementId, Data) of
                {ok, Reply} ->
                    {ok, Reply};
                {error, Error} ->
                    {error, Error}
            end;
        {error, Error} ->
            {error, Error}
    end;

cmd(Cmd, Req) ->
    nkdomain_obj_api:api(Cmd, ?DOMAIN_ADMIN_SESSION, Req).



%% ===================================================================
%% Internal
%% ===================================================================

