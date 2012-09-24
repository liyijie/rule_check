# encoding : utf-8
require "spec_helper"

describe ConfigConvert do
	it "should not be nil" do
		rule_config = ConfigConvert.load_excel("../config/重点数据核查规则0806.xls")
		rule_config.should_not be_nil
	end
end