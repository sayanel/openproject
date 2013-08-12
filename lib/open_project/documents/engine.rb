module OpenProject::Documents
  class Engine < ::Rails::Engine
    engine_name :openproject_documents

    config.autoload_paths += Dir["#{config.root}/lib/"]

    spec = Bundler.environment.specs['openproject-documents'][0]
    initializer 'documents.register_plugin' do
      Redmine::Plugin.register :openproject_documents do

        name 'OpenProject Documents'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url spec.homepage
        description spec.description
        version spec.version
        url 'https://www.openproject.org/projects/documents'

        requires_openproject ">= 3.0.0pre10"

        menu :project_menu, :documents, { :controller => '/documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural

        permission :manage_documents, {:documents => [:new, :create, :edit, :update, :destroy, :add_attachment]}, :require => :loggedin
        permission :view_documents, :documents => [:index, :show, :download]

        #settings Engine.settings
      end

      Redmine::Search.register :documents
      #Redmine::Activity.register :documents, :class_name => %w(Document)

    end



    #initializer 'landing_page.precompile_assets' do
    #  Rails.application.config.assets.precompile += %w(landing_page.css landing_page.js)
    #end

    #initializer 'landing_page.register_test_paths' do |app|
    #  app.config.plugins_to_test_paths << self.root
    #end

    #initializer 'landing_page.register_hooks' do
    #  # don't use require_dependency to not reload hooks in development mode
    #  require 'open_project/landing_page/hooks'
    #end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "remove_duplicate_documents_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    # adds our factories to factory girl's load path
    initializer "documents.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    config.to_prepare do
      require_dependency 'open_project/documents/patches/project_patch'
    end

  end
end
