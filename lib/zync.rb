require 'eventmachine'
require 'rack'
require 'active_support/core_ext'

module Zync
  autoload :Application,  'zync/application'
  autoload :Logger,       'zync/logger'
  autoload :Logging,      'zync/logging'
  autoload :Router,       'zync/router'
  autoload :Util,         'zync/util'

  autoload :Controller,   'zync/controller'
  autoload :Callbacks,    'zync/callbacks'
  autoload :Body,         'zync/body'

  class << self
    attr_accessor :application, :logger, :settings

    def config
      application && application.config
    end
    
    def logger
      # Use synchronous Logger by default
      @logger ||= ::Logger.new(File.join(Zync.root, 'log', "#{Zync.env}.log"))
    end

    def root
      # application && application.config.root
      ZYNC_ROOT
    end

    def env
      @env ||= ENV['RACK_ENV'] || 'development'
    end
  end
end
