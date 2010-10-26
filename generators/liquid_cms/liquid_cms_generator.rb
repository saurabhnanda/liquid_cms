require File.join(File.dirname(File.expand_path(__FILE__)), 'lib', 'insert_commands')

class LiquidCmsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # migrations
      m.migration_template 'migration.rb', File.join('db', 'migrate'), :migration_file_name => 'create_liquid_cms_setup'

      # initializers
      m.directory File.join('config', 'initializers', 'cms')
      %w(liquid_cms.rb simple_form.rb simple_form_updates.rb vestal_versions.rb remote_indicator.rb).each do |file|
        m.file File.join('config', 'initializers', 'cms', file), File.join('config', 'initializers', 'cms', file)
      end

      # cms controllers
      m.directory File.join('app', 'controllers', 'cms')
      m.file 'setup_controller.rb', File.join('app', 'controllers', 'cms', 'setup_controller.rb')

      # liquid files
      m.directory File.join('app', 'liquid')
      %w(filters tags drops).each do |liquid_dir|
        m.directory File.join('app', 'liquid', liquid_dir)
      end

      # locales
      m.directory File.join('config', 'locales', 'cms')
      m.file File.join('config', 'locales', 'cms', 'en.yml'), File.join('config', 'locales', 'cms', 'en.yml')

      # plugins
      m.copy_files File.join('vendor', 'plugins'), 'cms_plugins'

      # user generated assets
      m.directory File.join('public', 'cms')
      %w(assets components).each do |asset_dir|
        m.directory File.join('public', 'cms', asset_dir)
      end
      
      # main assets
      Dir[File.join(source_root, 'public', 'cms', '*')].each do |asset_dir|
        m.copy_files File.join('public', 'cms'), File.basename(asset_dir)
      end

      # add the global cms route to the apps main route file... this must be the last route in the file (lowest priority)
      logger.route "Cms.global_route map"
      sentinel = 'end'
      line = "\n\t# This must be the last defined route in order for the cms to load pages properly.\n\tCms.global_route map\n#{sentinel}"
      unless m.file_contains?('config/routes.rb', line)
        m.gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)}\Z)/mi do |match|
          line
        end
      end
    end
  end
end