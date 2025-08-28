# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincExecutor.BundlexProject do
  use Bundlex.Project

  def project do
    [
      nifs: nifs()
    ]
  end

  defp nifs do
    [
      aria_minizinc_native: [
        sources: ["aria_minizinc_native.cpp", "minizinc_wrapper.cpp"],
        includes: ["bundled/libminizinc/include"],
        libs: ["bundled/libminizinc/lib/libminizinc", "stdc++"],
        pkg_configs: [],
        language: :cpp,
        cpp_std: 17,
        export_only_nif?: true
      ]
    ]
  end
end
