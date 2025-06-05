Rails.application.config.assets.version = "1.0"

require 'pathname'

Rails.application.config.assets.paths << Pathname(Gem.loaded_specs['bootstrap'].full_gem_path).join('assets', 'stylesheets', 'bootstrap', 'scss') # <-- LINHA CORRIGIDA

Rails.application.config.assets.precompile += %w( application.css )