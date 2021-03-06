require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/dummy_class.rb')
require File.expand_path(File.dirname(__FILE__) + '/../fixtures/import_class1.rb')
describe Importex::Base do

  before(:each) do
    @xls_file = File.dirname(__FILE__) + '/../fixtures/simple.xls'
  end

  after(:each) do
    ImportClass1.columns.clear
  end

  it "should store translation options" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.translated_class.should == DummyClass
  end


  it "should initialize the translated object" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name, :initialize => Proc.new {|row| d = DummyClass.new; d.id = row["Age"]; d }

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"id" => 27}, # First row
      {"id" => 42}, # Second row
      {"id" => 28}, # Third row
      {"id" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end

  it "should translate all rows" do
    ImportClass1.column "Name"
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
      {"Name" => nil, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate only valid rows when required" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_valid

    rows = [
      {"Name" => "Foo", "Age" => 27}, # First row
      {"Name" => "Bar", "Age" => 42}, # Second row
      {"Name"=>"Blue", "Age"=>28}, # Third row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate only invalid rows when required" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_invalid

    rows = [
      {"Name" => nil, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate fields using the :field parameter" do
    ImportClass1.column "Rank", :translation => :name
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => 1, "Age" => 27}, # First row
      {"Name" => 2, "Age" => 42}, # Second row
      {"Name"=>nil, "Age"=>28}, # Third row
      {"Name" => 3, "Age" => 25} # Fourth row
    ]

    check_rows rows, dummy_objects

  end


  it "should translate fields by using a proc" do
    ImportClass1.column "Name", :translation => Proc.new{ |object, row| object.name = row.attributes["Name"].upcase}
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => "FOO", "Age" => 27}, # First row
      {"Name" => "BAR", "Age" => 42}, # Second row
      {"Name"=>"BLUE", "Age"=>28}, # Third row
      {"Name" => "", "Age" => 25} # Fourth row
    ]


    check_rows rows, dummy_objects

  end


  it "should use any field in the translation when using a proc" do
    ImportClass1.column "Name", :translation => Proc.new{ |object, row|
      object.name = row.attributes["Age"] > 27 ? row.attributes["Name"].upcase : row.attributes["Name"].downcase
    }
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_all

    rows = [
      {"Name" => "foo", "Age" => 27}, # First row
      {"Name" => "BAR", "Age" => 42}, # Second row
      {"Name"=>"BLUE", "Age"=>28}, # Third row
      {"Name" => "", "Age" => 25} # Fourth row
    ]


    check_rows rows, dummy_objects

  end

  it "should allow some postprocessing on the translation" do
    ImportClass1.column "Name", :validate_presence => true
    ImportClass1.column "Age", :type => Integer
    ImportClass1.translate_to DummyClass.name,
      :after => Proc.new{ |records|


        translated_records = records.map(&:translated_object)

        translated_records.each do |record|
          translated_records.each do |other_record|
            if record != other_record && !record.younger.include?(other_record) && !record.older.include?(other_record)

              older = record.age > other_record.age ? record : other_record
              younger = record.age <= other_record.age ? record : other_record

              younger.older << older
              older.younger << younger

            end
          end
        end

      }

    ImportClass1.import(@xls_file)

    dummy_objects = ImportClass1.translate_valid

    rows = [
      {"Name" => "Foo", "Age" => 27, "younger_count" => 0, "older_count" => 2}, # First row
      {"Name" => "Bar", "Age" => 42, "younger_count" => 2, "older_count" => 0}, # Second row
      {"Name"=>"Blue", "Age"=>28, "younger_count" => 1, "older_count" => 1}, # Third row
    ]

    check_rows rows, dummy_objects

  end


end

def check_rows rows, objects

    objects.length.should == rows.count

    objects.each_with_index do |dummy_object, i|
      rows[i].each do |name, value|
        dummy_object.send(name.downcase).should == value
      end
    end
end