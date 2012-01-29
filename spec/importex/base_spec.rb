# encoding: UTF-8
require 'spec_helper'

describe Importex::Base do
  before(:each) do
    @simple_class = Class.new(Importex::Base)
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end
  
  
  it "should import simple excel doc" do
    @simple_class.column "Name"
    @simple_class.column "Age", :type => Integer
    @simple_class.import(@xls_file)
    @simple_class.all.map(&:attributes).should == [{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}]
  end
  
  it "should import columns with strange characters" do
    @simple_class.column "Såøæk", :required => true, :type => Integer
    @simple_class.import(@xls_file)
    @simple_class.all.map(&:attributes).should == [{"Såøæk" => 1}, {"Såøæk" => 2}, {"Såøæk" => 3} ]
  end
  
  it "should import columns with values that contain strange characters" do
    @simple_class.column "strange", :required => true
    @simple_class.import(@xls_file)
    @simple_class.all.map(&:attributes).should == [{"strange" => "æøå"}, {"strange" => "ÆØÅ"}, {"strange" => "ufo"}]
  end
  
  it "should import only the column given and ignore others" do
    @simple_class.column "Age", :type => Integer
    @simple_class.column "Nothing"
    @simple_class.import(@xls_file)
    @simple_class.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}]
  end
  
  it "should add restrictions through an array of strings or regular expressions" do
    @simple_class.column "Age", :format => ["foo", /bar/]
    lambda {
      @simple_class.import(@xls_file)
    }.should raise_error(Importex::InvalidCell, '27 (column Age, row 2) does not match required format: ["foo", /bar/]')
  end
  
  it "should support a lambda as a requirement" do
    @simple_class.column "Age", :format => lambda { |age| age.to_i < 30 }
    lambda {
      @simple_class.import(@xls_file)
    }.should raise_error(Importex::InvalidCell, '42 (column Age, row 3) does not match required format: []')
  end
  
  it "should have some default requirements" do
    @simple_class.column "Name", :type => Integer
    lambda {
      @simple_class.import(@xls_file)
    }.should raise_error(Importex::InvalidCell, 'Foo (column Name, row 2) does not match required format: Not a number.')
  end
  
  it "should have a [] method which returns attributes" do
    simple = @simple_class.new("Foo" => "Bar")
    simple["Foo"].should == "Bar"
  end
  
  it "should import if it matches one of the requirements given in array" do
    @simple_class.column "Age", :type => Integer, :format => ["", /^[.\d]+$/]
    @simple_class.import(@xls_file)
    @simple_class.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}]
  end
  
  it "should raise an exception if required column is missing" do
    @simple_class.column "Age", :required => true
    @simple_class.column "Foo", :required => true
    lambda {
      @simple_class.import(@xls_file)
    }.should raise_error(Importex::MissingColumn, "Column Foo is required but it doesn't exist.")
  end

  it "should raise an exception if required value is missing" do
    @simple_class.column "Rank", :validate_presence => true
    lambda {
      @simple_class.import(@xls_file)
    }.should raise_error(Importex::InvalidCell, "(column Rank, row 4) can't be blank")
  end

  describe "self.reset" do
    it "resets the columns" do
      @simple_class.reset
      @simple_class.all.should be_nil
    end
  end
end
