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

%% @doc Session Object Syntax
-module(nkadmin_session_obj_syntax).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-export([api/3]).

-include("nkadmin.hrl").


%% ===================================================================
%% Syntax
%% ===================================================================


%% @doc
api('', find, Syntax) ->
    Syntax#{
        user_id => binary
    };

api('', create, Syntax) ->
    Syntax#{
        user_id => binary,
        domain_id => binary,
        language => {atom, [en, es]},
        events => {list, binary}
    };

api('', start, Syntax) ->
    Syntax#{
        id => binary,
        domain_id => binary,
        language => {atom, [en, es]},
        events => {list, binary}
    };

api('', stop, Syntax) ->
    Syntax#{
        id => binary,
        reason => binary
    };

api('', switch_domain, Syntax) ->
    Syntax#{
        id => binary,
        domain_id => binary,
        '__mandatory' => [domain_id]
    };

api('', element_action, Syntax) ->
    Syntax#{
        id => binary,
        action => {atom, [selected]},
        element_id => binary,
        value => any,
        '__mandatory' => [element_id, action]
    };

api(Sub, Cmd, Syntax) ->
    nkdomain_obj_syntax:syntax(Sub, Cmd, ?DOMAIN_ADMIN_SESSION, Syntax).