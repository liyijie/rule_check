# encoding : utf-8

module ResultModule
	class Error
		attr_accessor :error_string, :error_attrs

		def initialize(error_string, error_attrs)
			@error_string = error_string
			@error_attrs = error_attrs
		end
	end

	class StatCount
		attr :count_map

		class Count
			attr_accessor :error_cnt, :miss_cnt, :suc_cnt, :all_cnt
			def initialize
				@error_cnt, @miss_cnt, @suc_cnt, @all_cnt = 0
			end

			def add_error
				@error_cnt += 1
				@all_cnt += 1
			end

			def add_miss
				@miss_cnt += 1
				@all_cnt += 1
			end

			def add_suc
				@suc_cnt += 1
				@all_cnt += 1
			end
		end

		def initialize
			@count_map = {}
		end

		def add_error(attr_name)
			count = get_count(attr_name)
			count.add_error
		end

		def add_miss(attr_name)
			count = get_count(attr_name)
			count.add_miss
		end

		def add_suc(attr_name)
			count = get_count(attr_name)
			count.add_suc
		end

		def get_count(attr_name)
			@count_map[attr_name] ||= Count.new
			count = @count_map[attr_name]
			count
		end
	end

	class StatKey
		attr_accessor :type, :city

		def initialize(type, city)
			@type = type
			@city = city
		end

		def ==(o)
			if o.is_a? StaKey
				@type.eql?(o.type) && @city.eql?(o.city)
			elsif
				false
			end	
		end

		alias eql? ==

		def hash
			code = 17
			code = 37*code + @type.hash
			code = 37*code + @city.hash
			code
		end
	end

	class AnaResultAttr
		attr_reader :errors, :type, :name
		attr_accessor :value

		def initialize(type, name)
			@errors = []
			@type, @name = type, name		
		end

		def check?
			@errors.size == 0
		end

		def add_error(error)
			@errors << error
		end

		def to_s
			"#{@type}-#{@name}-#{@value}:errors is #{@errors}"
		end
	end

	class AnaResult
		attr_reader :type, :results
		attr_accessor :source

		def initialize(type)
			@type = type
			@results = []
			@source = ""
		end

		def << result
			@results << result
		end

		def check?
			check_result = true
			@results.each do |result|
				next if result.errors[0] == 'empty'
				unless result.check?
					check_result = false
					break
				end
			end
			check_result
		end

		def to_s
			display = ""
			unless check?
				display << "#{@source}\n"
				@results.each do |result|
					display << "#{result.to_s}\n" unless result.check?
				end
			end
			display
		end
	end

	class AnaResultFile
		attr_reader :file, :type, :results

		def initialize(type)
			@type = type
			@results = []
		end

		def << result
			@results << result
		end

		def clear
			@results.clear
		end

		def size
			@results.size
		end

		def to_s
			display = ""
			@results.each do |result|
				display << result.to_s
			end
			display
		end
	end

	# class AnaResult
	# 	attr_reader :errors, :stat_result, :type_attrs

	# 	def initialize
	# 		@errors = []
	# 		@stat_result = {}
	# 		@type_attrs = {}
	# 	end

	# 	def add_error(type, city, error_string, error_attrs)
	# 		stat_count = get_stat_count(type, city)
	# 		error_attrs.each do |attr_name|
	# 			stat_count.add_error(attr_name)
	# 		end

	# 		error = Error.new(error_string, error_attrs)
	# 		@errors << error
	# 	end

	# 	def add_suc(type, city, suc_attrs)
	# 		stat_count = get_stat_count(type, city)
	# 		suc_attrs.each do |attr_name|
	# 			stat_count.add_suc(attr_name)
	# 		end
	# 	end

	# 	def add_miss(type, city, miss_attrs)
	# 		stat_count = get_stat_count(type, city)
	# 		miss_attrs.each do |attr_name|
	# 			stat_count.add_miss(attr_name)
	# 		end
	# 	end

	# 	def get_stat_count(type, city)
	# 		stat_key = StatKey.new(type, city)
	# 		stat_result[stat_key] ||= StatCount.new
	# 		stat_count = stat_result[stat_key]
	# 		stat_count
	# 	end

	# 	def add_type_attrs(type, attrs)
	# 		type_attrs[type] = attrs
	# 	end
	# end

	class ResultHandle

		def self.write_stat_result(ana_result)
			stat_result = ana_result.stat_result
			type_attrs = ana_result.type_attrs
			stat_result.each do |key, counts|
				city = key.city
				type_attrs.values.each do |attr_name|
					count = counts.get_count(attr_name)
					puts "#{city},#{attr_name},#{count.error_cnt},#{count.suc_cnt},#{count.miss_cnt},#{count.all_cnt}"
				end
			end
		end

		def self.write_error_strings
			
		end
	end
end

result_attr = ResultModule::AnaResultAttr.new("type", "name")
result_attr.add_error("empty")
result_attr.add_error("scope")
puts result_attr.to_s


