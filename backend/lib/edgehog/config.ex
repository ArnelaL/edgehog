#
# This file is part of Edgehog.
#
# Copyright 2022-2023 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.Config do
  @moduledoc """
  This module handles the configuration of Edgehog
  """
  use Skogsra

  alias Edgehog.Config.GeocodingProviders
  alias Edgehog.Config.GeolocationProviders
  alias Edgehog.Config.JWTPublicKeyPEMType
  alias Edgehog.Geolocation
  alias Edgehog.Geolocation.Providers.GoogleGeocoding

  @envdoc """
  Disables admin authentication. CHANGING IT TO TRUE IS GENERALLY A REALLY BAD IDEA IN A PRODUCTION ENVIRONMENT, IF YOU DON'T KNOW WHAT YOU ARE DOING.
  """
  app_env :disable_admin_authentication, :edgehog, :disable_admin_authentication,
    os_env: "DISABLE_ADMIN_AUTHENTICATION",
    type: :boolean,
    default: false

  @envdoc "The Admin API JWT public key."
  app_env :admin_jwk, :edgehog, :admin_jwk,
    os_env: "ADMIN_JWT_PUBLIC_KEY_PATH",
    type: JWTPublicKeyPEMType

  @envdoc "Whether edgehog should use a tls connection with the database or not."
  app_env :database_enable_ssl, :edgehog, :database_enable_ssl,
    os_env: "DATABASE_ENABLE_SSL",
    type: :boolean,
    default: false

  @envdoc "The certificate file to use to verify the ssl connection with the database."
  app_env :database_ssl_cacertfile, :edgehog, :database_ssl_cacertfile,
    os_env: "DATABASE_SSL_CACERTFILE",
    type: :binary,
    default: ""

  @envdoc "Whether to use the os certificates to communicate with the database over ssl."
  app_env :database_use_os_certs, :edgehog, :database_use_os_certs,
    os_env: "DATABASE_USE_OS_CERTS",
    type: :boolean,
    default: false

  @envdoc "Whether to verify the ssl connection with the database or not."
  app_env :database_ssl_verify, :edgehog, :database_ssl_verify,
    os_env: "DATABASE_SSL_VERIFY",
    type: :boolean,
    default: false

  @envdoc """
  Disables tenant authentication. CHANGING IT TO TRUE IS GENERALLY A REALLY BAD IDEA IN A PRODUCTION ENVIRONMENT, IF YOU DON'T KNOW WHAT YOU ARE DOING.
  """
  app_env :disable_tenant_authentication, :edgehog, :disable_tenant_authentication,
    os_env: "DISABLE_TENANT_AUTHENTICATION",
    type: :boolean,
    default: false

  @envdoc "The API key for the ipbase.com geolocation provider."
  app_env :ipbase_api_key, :edgehog, :ipbase_api_key,
    os_env: "IPBASE_API_KEY",
    type: :binary

  @envdoc "The API key for the Google geolocation provider."
  app_env :google_geolocation_api_key, :edgehog, :google_geolocation_api_key,
    os_env: "GOOGLE_GEOLOCATION_API_KEY",
    type: :binary

  @envdoc "The API key for the Google geocoding provider."
  app_env :google_geocoding_api_key, :edgehog, :google_geocoding_api_key,
    os_env: "GOOGLE_GEOCODING_API_KEY",
    type: :binary

  @envdoc """
  A comma separated list of preferred geolocation providers.
  Possible values are: device, google, ipbase.
  """
  app_env :preferred_geolocation_providers, :edgehog, :preferred_geolocation_providers,
    os_env: "PREFERRED_GEOLOCATION_PROVIDERS",
    type: GeolocationProviders,
    default: [
      Geolocation.Providers.DeviceGeolocation,
      Geolocation.Providers.GoogleGeolocation,
      Geolocation.Providers.IPBase
    ]

  @envdoc """
  A comma separated list of preferred geocoding providers.
  Possible values are: google
  """
  app_env :preferred_geocoding_providers, :edgehog, :preferred_geocoding_providers,
    os_env: "PREFERRED_GEOCODING_PROVIDERS",
    type: GeocodingProviders,
    default: [GoogleGeocoding]

  @doc """
  Returns true if admin authentication is disabled.
  """
  @spec admin_authentication_disabled?() :: boolean()
  def admin_authentication_disabled?, do: disable_admin_authentication!()

  @doc """
  Returns true if edgehog should use an ssl connection with the database.
  """
  @spec database_enable_ssl?() :: boolean()
  def database_enable_ssl?, do: database_enable_ssl!()

  @doc """
  Reutrns whether to verify the ssl connection witht he database or not.
  """
  @spec database_ssl_verify?() :: boolean()
  def database_ssl_verify?, do: database_ssl_verify!()

  @doc """
  Returns true if edgehog should use the operative system certificates.
  """
  @spec database_use_os_certs?() :: boolean()
  def database_use_os_certs?, do: database_use_os_certs!()

  defp database_ssl_cert_config do
    use_os_certs = database_use_os_certs?()

    certfile = System.get_env("DATABASE_SSL_CACERTFILE")

    case {certfile, use_os_certs} do
      {nil, false} ->
        raise """
        invalid database SSL configuration:
        either set DATABASE_USE_OS_CERTS true to use system's certificates
        or provide a CA certificate file with DATABASE_SSL_CACERTFILE.
        The latter will take precedence.
        """

      {nil, true} ->
        {:cacerts, :public_key.cacerts_get()}

      {file, _} ->
        # Assuming `file` is a file path
        {:cacertfile, file}
    end
  end

  @doc """
  Returns the Ecto configuration for the ssl connection to the database.
  """
  @spec database_ssl_config_opts() :: list(term())
  def database_ssl_config_opts do
    if database_ssl_verify?(),
      do: [{:verify, :verify_peer}, database_ssl_cert_config()],
      else: [verify: :verify_none]
  end

  @doc """
  Returns the database configuration for the database connection.
  """
  @spec database_ssl_config() :: false | list(term())
  def database_ssl_config do
    if database_enable_ssl?(),
      do: database_ssl_config_opts(),
      else: false
  end

  @doc """
  Returns true if tenant authentication is disabled.
  """
  @spec tenant_authentication_disabled?() :: boolean()
  def tenant_authentication_disabled?, do: disable_tenant_authentication!()

  @doc """
  Returns the list of geolocation modules to use.
  """
  @spec geolocation_providers!() :: list(atom())
  def geolocation_providers! do
    disabled_providers = %{
      Edgehog.Geolocation.Providers.IPBase => is_nil(ipbase_api_key!()),
      Edgehog.Geolocation.Providers.GoogleGeolocation => is_nil(google_geolocation_api_key!())
    }

    Enum.reject(preferred_geolocation_providers!(), &disabled_providers[&1])
  end

  @doc """
  Returns the list of geocoding modules to use.
  """
  @spec geocoding_providers!() :: list(atom())
  def geocoding_providers! do
    disabled_providers = %{
      GoogleGeocoding => is_nil(google_geocoding_api_key!())
    }

    Enum.reject(preferred_geocoding_providers!(), &disabled_providers[&1])
  end

  @doc """
  Validates admin authentication config, raises if invalid.
  """
  @spec validate_admin_authentication!() :: :ok | no_return()
  def validate_admin_authentication! do
    if admin_authentication_disabled?() do
      :ok
    else
      admin_jwk!()
      :ok
    end
  end
end
