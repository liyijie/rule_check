# encoding: utf-8

require 'iconv'
# require 'parseexcel'
require "yaml"
require_relative "result_module"

class String
	def to_gb
		Iconv.conv("gb2312//IGNORE","UTF-8//IGNORE",self)
	end
	def utf8_to_gb
		Iconv.conv("gb2312//IGNORE","UTF-8//IGNORE",self)
	end
	def gb_to_utf8
		Iconv.conv("UTF-8//IGNORE","GB18030//IGNORE",self)
	end
	def to_utf8
		Iconv.conv("UTF-8//IGNORE","GB18030//IGNORE",self)
	end
end

module RuleEngine

	class Rule
		attr_reader :type, :name, :rule
		def initialize(type, name, rule)
			@type, @name, @rule = type, name, rule
			parse(@rule)
		end

		def check?(ana_data)
			true
		end

		def error
			"default"
		end

		def parse(rule)
			
		end

		def to_s
			"#{@type}-#{@name}-#{@rule}"
		end
	end

	class RuleAttr
		attr_reader :type, :name, :rules

		def initialize(type, name)
			@type = type
			@name = name
			@rules = []
		end

		def << rule
			@rules << rule
		end

		def check(ana_data)
			result = ResultModule::AnaResultAttr.new(@type, @name)
			@rules.each do |rule|
				unless (rule.check? ana_data)
					result.value = ana_data.get(@name)
					result.add_error("#{rule.error}")
					break
				end
			end
			result
		end
	end

	class RuleSet
		attr_reader :type
		attr :rules_attr, :validate

		def initialize(type)
			@rules_attr = {}
			@type = type
			@validate = true
			@source = ""
		end

		def check(ana_data)
			result_set = ResultModule::AnaResult.new(@type)
			if @type == ana_data.type
				@rules_attr.each do |attr_name, rule_attr|
					result = rule_attr.check(ana_data)
					result_set << result
					@validate = false unless result.check?
				end
			end
			result_set.source = ana_data.source unless validate?
			result_set
		end

		def validate?
			validate
		end

		def << rule
			return unless @type == rule.type
			@rules_attr[rule.name] ||= RuleAttr.new(rule.type, rule.name)
			@rules_attr[rule.name] << rule
		end

		def to_s
			@rules_attr.inspect
		end
	end

	class RuleEmpty < Rule
		def check?(ana_data)
			!ana_data.get(@name).empty?
		end

		def error
			"empty"
		end
	end

	class RuleScope < Rule
		attr_reader :rule_range, :rule_enum

		class Range
			attr_accessor :min, :max

			def initialize min, max
				@min = min
				@max = max
			end

			def to_s
				"Range is: #{min}-#{max}"
			end
		end

		class Enum
			attr_accessor :enums

			def initialize enums
				@enums = enums
			end

			def to_s
				"Enums is :#{@enums}"
			end
		end

		def parse(rule)
			rule = rule.gsub(' ','')
			@rule_range = []
			@rule_enum = []
			if (rule =~ /^\[-?\d+,-?\d+(;-?\d+,-?\d+)*\]$/)
				# puts "#{rule}-#{$~.string}"
				rule = rule.gsub(/\[|\]/, '')
				@rule_range << to_range(rule.split(/,|;/))
			elsif (rule =~ /^\{.*\}$/)
				rule = rule.gsub(/\{|\}/, '')
				@rule_enum = rule.split(',')
			end
		end

		def to_range(range_arr)
			min, max = 0, 0
			range_arr.each_with_index do |arr, idx|
				if (idx % 2 == 0)
					min = arr
				else
					max = arr
					@rule_range << Range.new(min, max)
				end
			end
		end

		def check?(ana_data)
			return true if (@rule_range.size == 0 && @rule_enum.size == 0)
			result = false
			@rule_range.each do |range|
				min = range.min.to_f
				max = range.max.to_f
				data = ana_data.get(@name).to_f
				if (data >= min && data <= max)
					result = true 
					break
				end
			end
			@rule_enum.each do |enum|
				if (enum == ana_data.get(@name))
					result = true
					break
				end
			end
			###############################
			###########调试打印#############
			# unless result
			# 	puts "#{ana_data.source}"
			# 	puts "process rule: #{error}-#{@rule}-#{@name}-#{ana_data.get(@name).to_f}-#{result}"	
			# end
			result
		end

		def error
			"scope"
		end
	end

	class RuleRelate < Rule

		attr :attrnames

		def error
			"relate"
		end	

		def parse(rule)
			@attrnames = rule.split(/\<|\>|\=|\+/)
		end

		def check?(ana_data)
			result = false
			return result if (ana_data.get(@name).empty?)
			eval_string = ""
			eval_string << @rule
			datas = ana_data.data
			@attrnames.each do |attrname|
				next if attrname.empty?
				return result if ana_data.get(attrname).empty?
				eval_string = eval_string.sub(attrname, ana_data.get(attrname))
			end
			eval_string = ana_data.get(@name) + eval_string
			begin
				result = eval(eval_string)
			rescue Exception => e
			end
			result
		end
	end

	class RuleFactory
		RULE_NAME= "指标名称"
		SCOPE_TYPE = "范围规则"
		RELATE_TYPE = "字段关联规则"

		def self.create(ruletype, type, name, rule)
			case ruletype
			when SCOPE_TYPE
				RuleScope.new(type, name, rule)
			when RELATE_TYPE
				RuleRelate.new(type, name, rule)
			end
		end

		# def self.load(excel)
		# 	rule_map = {}
		# 	workbook = Spreadsheet::ParseExcel.parse(excel)
		# 	sheet_count = workbook.sheet_count

		# 	(0..sheet_count-1).each do |count|
		# 		ws = workbook.worksheet count
		# 		rule_setname = ws.name.to_s.gsub(/\x00/, '')
		# 		rule_set = RuleSet.new(rule_setname)
		# 		rule_names = []
		# 		rule_strings = []
		# 		rule_type = ""
		# 		name_row = -1;
		# 		ws.each_with_index do |row, row_idx|
		# 			row.each_with_index do |cell, col_idx|
		# 				next if cell.nil?
		# 				content = cell.to_s('utf-8').strip
		# 				if (content == RULE_NAME)
		# 					name_row = row_idx
		# 				elsif (row_idx == name_row)
		# 					rule_names[col_idx] = content
		# 					rule = RuleEmpty.new(rule_setname, rule_names[col_idx], "")
		# 					rule_set << rule
		# 				elsif (col_idx == 0 && row_idx > name_row && name_row >= 0)
		# 					rule_type = content
		# 				elsif (col_idx > 0 && row_idx > name_row && name_row >= 0)
		# 					rule = create(rule_type, rule_setname, rule_names[col_idx], content) unless content.empty?
		# 					rule_set << rule
		# 				end
		# 			end
		# 		end
		# 		rule_map[rule_setname.to_sym] = rule_set
		# 	end
		# 	#返回rulemap
		# 	rule_map
		# end

		def self.load
			rule_config = {}
			open("./config/rule_config.yml") {|f| rule_config = YAML.load(f)}
			rule_map = {}
			rule_config.each do |rule_setname, rule_attrs|
				rule_set = RuleSet.new(rule_setname)
				unless rule_attrs.nil?
					rule_attrs.each do |attrname, rule_strings|
						rule_empty = RuleEmpty.new(rule_setname, attrname, "")
						rule_set << rule_empty
						rule_strings.each do |rule_type, rule_string|
							rule = create(rule_type, rule_setname, attrname, rule_string)
							rule_set << rule
						end
					end
				end
				rule_map[rule_setname] = rule_set
			end
			rule_map
		end

	end

end

# params = ["type", "name", "[0,9]"]
# # rule = RuleEngine::RuleRelate.new(params)
# # rule = RuleEngine::RuleFactory.create("范围规则", params)
# # rule = RuleEngine::RuleFactory.create("字段关联规则", params)
# # RuleEngine::RuleFactory.load "./config/重点数据核查规则0806.xls"
# rule = RuleEngine::RuleScope.new(params)
# rule.parse("[0,10;15,18]")
# rule.parse "[0-10]"
# rule.parse "[0,199 ; -89, 98]"
# rule_map = RuleEngine::RuleFactory.load
# puts rule_map

