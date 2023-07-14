#
# This file is part of Edgehog.
#
# Copyright 2022 SECO Mind Srl
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

defmodule Edgehog.Mocks.Astarte.Device.BaseImage do
  @behaviour Edgehog.Astarte.Device.BaseImage.Behaviour

  alias Astarte.Client.AppEngine
  alias Edgehog.Astarte.Device.BaseImage

  @impl true
  def get(%AppEngine{} = _client, _device_id) do
    base_image = %BaseImage{
      name: "esp-idf",
      version: "0.1.0",
      build_id: "2022-01-01 12:00:00",
      fingerprint: "b14c1457dc10469418b4154fef29a90e1ffb4dddd308bf0f2456d436963ef5b3"
    }

    {:ok, base_image}
  end
end
