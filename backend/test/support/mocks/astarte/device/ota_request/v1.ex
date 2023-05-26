#
# This file is part of Edgehog.
#
# Copyright 2023 SECO Mind Srl
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

defmodule Edgehog.Mocks.Astarte.Device.OTARequest.V1 do
  @behaviour Edgehog.Astarte.Device.OTARequest.V1.Behaviour

  alias Astarte.Client.AppEngine

  @impl true
  def update(%AppEngine{} = _client, _device_id, _uuid, _url) do
    :ok
  end

  @impl true
  def cancel(%AppEngine{} = _client, _device_id, _uuid) do
    :ok
  end
end
