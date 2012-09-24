# encoding : utf-8

require_relative "rule_engine"

class AnaData
	attr_accessor :type, :source, :data

	def initialize(type, header, source)
		@type = type
		@source = ""
		@data = {}
		parse(header, source)
	end

	def parse(header, source)
		data_set = source
		header_set = header
		header_set.each_with_index do |head, idx|
			data_set[idx] ||= ""
			@data[head.strip] = data_set[idx].strip
			@source << data_set[idx] << ","
		end
	end

	def get(head)
		@data[head] ||= ""
	end

	def to_s
		@data.inspect
	end
end

# header = "时间,地市,CGI,最小接入电平,QSEARCH_I,TDD_OFFSET,下行功率控制,上行功率控制,BSS侧链路故障的计数器最大值,MS侧链路故障的计数器最大值,Bss侧检验无线链路故障的计数器S的最大值（AMRFR）,Bss侧检验无线链路故障的计数器S的最大值（AMRHR）"
# source = "2012-08-23,江汉,460-00-28914-52003,10,7,8,1,1,7,7,7,7"
# anadata = AnaData.new header, source

# puts "test:'#{anadata.get("test")}'"
# puts "时间:'#{anadata.get("时间")}'"