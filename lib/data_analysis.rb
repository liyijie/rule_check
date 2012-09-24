# encoding : utf-8

require "spreadsheet"
require "csv"
require_relative "ana_data"
require_relative "rule_engine"
require_relative "config_factory"




class DataAnalysis

	attr :rule_map, :book

	def initialize
		Spreadsheet.client_encoding = "UTF-8"
		@book = Spreadsheet::Workbook.new
	end

	#遍历文件夹下指定类型的文件
	def list_files(file_path, file_type)
		if (File.directory? file_path)
			Dir.foreach(file_path) do |file_name|
				if file_name=~/.#{file_type}$/i
					read_file(file_path, file_name)
				end
			end
		end 
		@book.write 'result.xls'
	end

	def read_file(file_path, file_name)
		type = file_name.split('_')[0]
		puts Time.now
		puts "process #{file_path}/#{file_name} ....." 
		CSV.open("#{file_path}/#{file_name}", "r:GBK") do |file|
			ana_file file,type
		end 
	end

	def ana_file(file, type)
		sheet = @book.create_worksheet :name => type
		row_idx = 0
		header = ""
		static_map = {}
		# result = ResultModule::AnaResultFile.new(type)
		file.each_with_index do |row, idx|
			if idx == 0
				header = convert_array row
				sheet.row(row_idx).concat header
				row_idx += 1
			else
				source = convert_array row
				anadata = AnaData.new type, header, source
				rule_set = @rule_map[type]
				result = rule_set.check(anadata)
				static_map = static_result!(static_map, source[1], result)
				unless result.check?
					attr_results = result.results
					attr_results.each_with_index do |attr_result, i|
						unless attr_result.check?
							if attr_result.errors[0] == "empty"
								format = Spreadsheet::Format.new( :size => 10, 
								                             :color=>"black",  :border=>:hair,
								                             :border_color=>"black", :pattern => 1 ,
								                             :pattern_fg_color => "red" )
							else
								format = Spreadsheet::Format.new( :size => 10, 
								                             :color=>"black",  :border=>:hair,
								                             :border_color=>"black", :pattern => 1 ,
								                             :pattern_fg_color => "yellow" )
							end
							sheet.row(row_idx).set_format(i+3, format)
						end
					end
					sheet.row(row_idx).concat source
					row_idx += 1
				end
			end
		end
		write_static static_map
	end

	def write_static static_map
		sheet = @book.create_worksheet :name => "汇总统计"
		col_idx = 0
		sheet.row(0).push "城市"
		static_map.each do |attr_name, city_count|
			row_idx = 0
			sheet.row(row_idx).push attr_name
			col_idx += 1
			row_idx += 1
			citys = city_count.keys
			citys.each do |city|
				sheet[row_idx, 0] = city
				count = city_count[city]
				# value = "#{count.error}-#{count.empty}-#{count.all}"
				value = "完整率：#{(count.all-count.empty)*100.0/count.all}%,合理率：#{(count.all-count.error)*100.0/count.all}%"
				sheet[row_idx, col_idx] = value
				row_idx += 1
			end
		end
	end

	def static_result!(state_map, city, result)
		#if (result.check?)
			attr_results = result.results
			whole = "统计"
			attr_results.each_with_index do |attr_result, idx|
				attr_name = attr_result.name
				# next if attr_name.nil?
				state_map[attr_name] ||= {}
				state_map[attr_name][whole] ||= Count.new
				state_map[attr_name][city] ||= Count.new
				if attr_result.check?
					state_map[attr_name][city].add_suc
					state_map[attr_name][whole].add_suc
				else 
					if attr_result.errors[0] == "empty"
						state_map[attr_name][city].add_empty
						state_map[attr_name][whole].add_empty
					else
						state_map[attr_name][city].add_error
						state_map[attr_name][whole].add_error
					end
				end	
			end
		#end
		state_map
	end

	def convert_array(array)
		array_new = []
		array.each do |value|
			value = value.nil? ? "" : value.to_utf8
			array_new.push value
		end
		array_new
	end

	def load_rules
		@rule_map = RuleEngine::RuleFactory.load
	end
end

class Count
	attr_accessor :error, :empty, :all
	def initialize
		@error, @empty, @all = 0, 0, 0

		def add_error
			@error += 1
			@all += 1
		end

		def add_empty
			@empty += 1
			@all += 1
		end

		def add_suc
			@all += 1
		end
	end
end

data_analysis = DataAnalysis.new
data_analysis.load_rules
data_analysis.list_files("./data", "csv")
