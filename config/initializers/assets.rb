# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( user/* )
Rails.application.config.assets.precompile += %w( touch-fancy.css )
Rails.application.config.assets.precompile += %w( jquery.dataTables.min.css )
Rails.application.config.assets.precompile += %w( dataTables.bootstrap4.css )

Rails.application.config.assets.precompile += %w( jquery.js )
Rails.application.config.assets.precompile += %w( dataTables/* )
Rails.application.config.assets.precompile += %w( jquery.dataTables.min.js )
Rails.application.config.assets.precompile += %w( dataTables.bootstrap4.min.js )