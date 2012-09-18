#encoding : utf-8

require "yaml"
require "parseexcel"
require "spreadsheet"

class ConfigConvert

	def self.excel_to_yml(excel_name, yml_name)
		dump_yml(load_excel(excel_name), yml_name)
	end

	def self.load_excel(excel_name)
		Spreadsheet.client_encoding = "UTF-8"
		workbook = Spreadsheet::ParseExcel.parse(excel_name)
		sheet_count = workbook.sheet_count
		rule_config = {}
		(0..sheet_count-1).each do |count|
			ws = workbook.worksheet count
			rule_setname = ws.name.to_s.gsub(/\x00/, '')
			rule_names = []
			name_row = -1
			rule_type = ""
			rule_config.store rule_setname, {} 
			ws.each_with_index do |row, row_idx|
				row.each_with_index do |cell, col_idx|
					next if cell.nil?
					content = cell.to_s('utf-8').strip
					# puts "#{col_idx}, #{row_idx}, #{name_row}"
					if (content == '指标名称')
						name_row = row_idx
					elsif (row_idx == name_row)
						rule_names[col_idx] = content
						rule_config[rule_setname].store content, {}
					elsif (col_idx == 0 && row_idx > name_row && name_row >= 0)
						rule_type = content
					elsif (col_idx > 0 && row_idx > name_row && name_row >= 0)
						rule = content unless content.empty?
						rule_config[rule_setname][rule_names[col_idx]].store rule_type, rule
					end
				end
			end
		end
		puts rule_config
		rule_config
	end

	def self.dump_yml(config, yml_name)
		open(yml_name, 'w') { |f| YAML.dump(config, f) }
	end
end

ConfigConvert.excel_to_yml("./config/重点数据核查规则0806.xls", "config.yml")


