# Below is a labor-intensive way to deal with CSV:

# contents = File.readlines '../event_attendees.csv'
# contents.each_with_index do |line,index|
#   next if index = 0 # Skip the header line with column titles
#   columns = line.split(',')
#   name = columns[2]
#   puts name
# end

# Let's use a parser instead!

require 'csv'
require 'erb'
require 'sunlight/congress'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode zipcode
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode zipcode
  # for more on by_zipcode, see: https://github.com/steveklabnik/sunlight-congress/blob/master/lib/sunlight/congress/legislator.rb
  legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def create_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,"w") do |file|
    file.puts form_letter
  end
end

# 'open' is the CSV class equivalent of 'readlines'
contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "../templates/form_letter.erb"
erb_template = ERB.new template_letter # Creating a new file based on the template above

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  # The line below actually generates the letter and loops through the legislators
  form_letter = erb_template.result(binding) 

  create_thank_you_letters(id,form_letter)

end

