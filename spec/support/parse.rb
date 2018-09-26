require "yaml"

def parse_initialize(logger_level = Logger::ERROR)
  config = YAML::load(File.open("config/application.yml"))
  # puts "config: #{config}"
  ParseModel.initialize(
    application_id: config['TEST_PARSE_APPLICATION_ID'], host: config['TEST_PARSE_HOST'], master_key: config['TEST_PARSE_MASTER_KEY'],
    logger_level: logger_level)
end

def parse_destroy_objects(class_name)
  widgets = ParseModel.client.query(class_name).get
  batch = ParseModel.client.batch
  widgets.each do |widget|
    batch.delete_object(widget)
  end
  batch.run!
end

def _t(time_str)
  SynapseBlueDb.seconds_from_beginning_of_day(time_str)
end
