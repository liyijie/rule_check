# encoding: utf-8

require "singleton"
require "yaml"

class ConfigFactory
	include Singleton
	RULE_CONFIG_FILE = "./config/rule_config.yml"
	SYS_CONFIG_FILE = "./config/sys_config.yml"

	def initialize
		@config_context = {}
		@rule_config = {}
	end

	def load()
		open(SYS_CONFIG_FILE) do |f|
			@config_context = YAML.load(f)
		end
		open(RULE_CONFIG_FILE) do |f|
			@rule_config = YMAL.load(f)
		end
	end

	def get_sysconfig(config_name)
		@config_context[config_name]
		@rule_config
	end

end

# ConfigFactory.instance.load("./config/config.ini")
# puts ConfigFactory.instance.get("test")
# puts ConfigFactory.instance.get(ConfigFactory::PATHEN_FILE)