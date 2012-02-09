require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class1.rb')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class2.rb')

describe Importex::Base do
  before(:each) do
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end

  after(:each) do
    ImportClass1.columns.clear
  end

  it "should import simple excel doc" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}]
  end

  it "should import only the column given and ignore others" do
    ImportClass1.column "Age", :type => Integer
    ImportClass1.column "Nothing"
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}, {"Age" => 25}]
  end

  it "should add restrictions through an array of strings or regular expressions" do
    ImportClass1.column "Age", :format => ["foo", /bar/]
    ImportClass1.import(@xls_file)
    ImportClass1.invalid.count.should be_equal 4
    ImportClass1.invalid.first.errors[:age].should be_include('format error: ["foo", /bar/]')
  end

  it "should support a lambda as a requirement" do
    ImportClass1.column "Age", :format => lambda { |age| age.to_i < 30 }
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 1
    ImportClass1.invalid.first.errors[:age].should be_include('format error: []')

  end

  it "should have some default requirements" do
    ImportClass1.column "Name", :type => Integer
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 3
    ImportClass1.invalid.first.errors[:name].should be_include('Not an Integer.')

  end

  it "should have a [] method which returns attributes" do
    simple = ImportClass1.new("Foo" => "Bar")
    simple["Foo"].should == "Bar"
  end

  it "should import if it matches one of the requirements given in array" do
    ImportClass1.column "Age", :type => Integer, :format => ["", /^[.\d]+$/]
    ImportClass1.import(@xls_file)
    ImportClass1.all.map(&:attributes).should == [{"Age" => 27}, {"Age" => 42}, {"Age" => 28}, {"Age" => 25}]
  end

  it "should raise an exception if required column is missing" do
    ImportClass1.column "Age", :required => true
    ImportClass1.column "Foo", :required => true
    lambda {
      ImportClass1.import(@xls_file)
    }.should raise_error(Importex::MissingColumn, "Columns Foo is/are required but it doesn't exist in Age.")
  end

  it "should raise an exception if required value is missing" do
    ImportClass1.column "Rank", :validate_presence => true
    ImportClass1.import(@xls_file)

    ImportClass1.invalid.count.should be_equal 1
    ImportClass1.invalid.first.errors[:rank].should be_include('can\'t be blank')

  end

  it "should import different classes with different settings " do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer

    ImportClass2.column "Name", :validate_presence => true
    ImportClass2.column "Rank", :type => Integer


    ImportClass1.import(@xls_file)
    ImportClass2.import(@xls_file)

    ImportClass1.valid.map(&:attributes).should == [{"Name" => "Foo", "Age" => 27}, {"Name" => "Bar", "Age" => 42}, {"Name"=>"Blue", "Age"=>28}, {"Name" => "", "Age" => 25}]

    ImportClass2.valid.map(&:attributes).should == [{"Name" => "Foo", "Rank" => 1}, {"Name" => "Bar", "Rank" => 2}, {"Name" => "Blue", "Rank" => nil}]
  end

end
