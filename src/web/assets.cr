require "baked_file_system"

module Crybot
  module Web
    # BakedAssets contains all static files embedded in the binary
    class BakedAssets
      extend BakedFileSystem

      # Bake all static files from src/static into the binary
      # Path is relative to project root (go up one level from src/web to src)
      bake_folder "../static", __DIR__
    end
  end
end
