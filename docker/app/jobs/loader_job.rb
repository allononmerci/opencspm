# Add lib to the load path
$:.unshift(File.expand_path('lib', __dir__))
require 'config/config_loader'
require 'batch_importer'
require 'pry'

class LoaderJob < ApplicationJob
  queue_as :default

  TYPE = :load

  def perform(args)
    unless args.has_key?(:guid)
      logger.info 'Loader job not running without a GUID.'
      return nil
    end

    # shared GUID
    guid = args[:guid]
    logger.info "#{guid} Loader job started"

    # Track the job
    job = Job.create(status: :running, kind: TYPE, guid: guid)

    config_file = 'load_config/config.yaml'

    logger.info 'Loading configuration'
    config = ConfigLoader.new(config_file).parsed_config

    logger.info 'Loading data...'
    BatchImporter.new(config).import

    job.complete!
    logger.info "#{guid} Loader job finished"
  end
end
