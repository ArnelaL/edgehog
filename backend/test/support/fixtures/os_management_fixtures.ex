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

defmodule Edgehog.OSManagementFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Edgehog.OSManagement` context.
  """

  alias Edgehog.BaseImagesFixtures

  @doc """
  Generate a manual ota_operation.
  """
  def manual_ota_operation_fixture(device) do
    fake_image = %Plug.Upload{path: "test/fixtures/image.bin", filename: "image.bin"}

    {:ok, ota_operation} =
      device
      |> Edgehog.Devices.preload_astarte_resources_for_device()
      |> Edgehog.OSManagement.create_manual_ota_operation(fake_image)

    ota_operation
  end

  @doc """
  Generate a managed ota_operation.
  """
  def managed_ota_operation_fixture(device) do
    base_image = BaseImagesFixtures.base_image_fixture()

    {:ok, ota_operation} =
      device
      |> Edgehog.Devices.preload_astarte_resources_for_device()
      |> Edgehog.OSManagement.create_managed_ota_operation(base_image)

    ota_operation
  end
end
