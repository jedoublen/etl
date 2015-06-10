###############################################################################
# Copyright (C) 2015 Chuck Smith
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

require 'rails_helper'

require 'etl/core'

# Test reading and writing basic CSV file
class TestCsvCreate1 < ETL::Job::CSV
  def initialize
    super
    @feed_name = "test_1"
    @input_file = "#{Rails.root}/spec/data/simple1.csv"
    @schema = ETL::Schema::Table.new(
      "day" => :date,
      "condition" => :string,
      "value_int" => :int,
      "value_num" => ETL::Schema::Type.new(:numeric, 10, 1),
      "value_float" => :float
    )
  end
end


# Test reading in pipe-separated file and outputting @ separated
class TestCsvCreate2 < ETL::Job::CSV
  def initialize
    super
    @feed_name = "test_2"
    @input_file = "#{Rails.root}/spec/data/simple1.psv"
    @schema = ETL::Schema::Table.new(
      "day" => :date,
      "condition" => :string,
      "value_int" => :int,
      "value_num" => ETL::Schema::Type.new(:numeric, 10, 1),
      "value_float" => :float
    )
  end

  def csv_input_options
    # file does not have headers
    return super.merge({headers: false, col_sep: '|'})
  end

  def csv_output_options
    return super.merge({col_sep: '@'})
  end
end



RSpec.describe Job, :type => :job do

  it "csv - simple overwrite" do

    # remove old file
    outfile = "/var/tmp/etl_test_output/test_1/2015-03-31.csv"
    File.delete(outfile) if File.exist?(outfile)
    expect(File.exist?(outfile)).to be false

    job = TestCsvCreate1.new
    batch = ETL::Job::DateBatch.new(2015, 3, 31)

    expect(job.output_file(batch)).to eq(outfile)

    jr = job.run(batch)

    expect(jr.status).to eq(:success)
    expect(jr.num_rows_success).to eq(3)
    expect(jr.num_rows_error).to eq(0)
    expect(jr.message).to include(outfile)
    expect(File.exist?(outfile)).to be true

    contents = IO.read(outfile)
    expect_contents = <<END
day,condition,value_int,value_num,value_float
2015-04-01,rain,0,12.3,59.3899
2015-04-02,snow,1,13.1,60.2934
2015-04-03,sun,-1,0.4,-12.83
END
    expect(contents).to eq(expect_contents)
  end


  it "psv - simple overwrite" do

    # remove old file
    outfile = "/var/tmp/etl_test_output/test_2/2015-03-31.csv"
    File.delete(outfile) if File.exist?(outfile)
    expect(File.exist?(outfile)).to be false

    job = TestCsvCreate2.new
    batch = ETL::Job::DateBatch.new(2015, 3, 31)

    expect(job.output_file(batch)).to eq(outfile)

    jr = job.run(batch)

    expect(jr.status).to eq(:success)
    expect(jr.num_rows_success).to eq(3)
    expect(jr.num_rows_error).to eq(0)
    expect(jr.message).to include(outfile)
    expect(File.exist?(outfile)).to be true

    contents = IO.read(outfile)
    expect_contents = <<END
day@condition@value_int@value_num@value_float
2015-04-01@rain@0@12.3@59.3899
2015-04-02@snow@1@13.1@60.2934
2015-04-03@sun@-1@0.4@-12.83
END
    expect(contents).to eq(expect_contents)
  end
end