% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This file is part of Webtalk <https://github.com/sandogeorge/webtalk>.
% Copyright (c) 2017 Sando George <sando.csc AT gmail.com>
%
% Webtalk is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.
%
% Webtalk is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
% A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with
% Webtalk. If not, see <http://www.gnu.org/licenses/>.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load application.
%
% This code:
% 1. Loads all applications source files.
% 2. Determines the deployment environment to be used and gets the appropriate
% configuration object.
% 3. Starts the HTTP server, listening on the configured server port.
% 4. Makes the correct configuration object available to the rest of the
% application.
:- initialization((
    logtalk_load([basic_types(loader), meta(loader)]),
    logtalk_load([
        'app_settings',
        'core/model/model',
        'core/lib/extend/extend',
        'core/lib/extend/extension',
        'core/lib/extend/extension_manager',
        'core/lib/extend/theme',
        'core/lib/extend/theme_manager',
        'core/lib/form/validator',
        'core/lib/form/widget',
        'core/lib/form/field',
        'core/lib/form/form',
        'core/lib/templating/templating',
        'core/lib/blueprint/blueprint'
    ]),
    extension_manager::install_default_extensions,
    logtalk_load([
        'core/lib/routing/routing',
        'core/blueprint/static/static',
        'core/blueprint/wellknown/wellknown',
        'core/blueprint/install/install',
        'core/blueprint/auth/auth',
        'core/blueprint/config/config',
        'core/blueprint/main/main',
        'core/blueprint/api/api'
    ]),
    blueprint::autoload_custom_blueprints,
    user:app_prefix(AppPrefix),
    atom_concat(AppPrefix, 'SETTINGS', Envar),
    (getenv(Envar, Settings) -> true ; Settings = 'development'),
    atom_concat(Settings, '_settings', AppSettings),
    AppSettings::new(Instance, []),
    assertz(user:app_settings(Instance)),
    theme_manager::install_default_themes,
    templating::init,
    use_module(library(http/http_log)),
    use_module(library(settings)),
    set_setting(http:logfile, '/tmp/httpd.log'),
    ( Instance::daemonize(true) ->
        findall(X, (Instance::daemon_option(O, V), X =.. [O, V]), Options),
        use_module(library(http/http_unix_daemon)),
        http_daemon(Options)
    ;
        Instance::config_property(server_port, ServerPort),
        use_module(library(http/thread_httpd)),
        use_module(library(http/http_dispatch)),
        threaded_ignore(http_server(http_dispatch, [port(ServerPort)])))
)).
