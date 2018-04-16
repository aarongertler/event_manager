require 'csv'
require 'erb'
require 'active_support/core_ext/hash' # gives us the handy 'slice' method for hashes
# require 'sunlight/congress' # Now deprecated: https://sunlightfoundation.com/api/
require 'propublica' # https://github.com/omarcodex/propublica-gem
require 'certified' # Attempt to fix SSL error -- works now, may need to update certificate later

# Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def legislators_by_state state, congress, client # Would be quicker to load all legislators and their states once and then loop through that list for each attendee, but this is more proof-concept than anything else
  # for more on by_zipcode, see: https://github.com/steveklabnik/sunlight-congress/blob/master/lib/sunlight/congress/legislator.rb
  # legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)

  local_legislators = []

  results = client.get_senate_members(congress)

  results.each do |legislator|
    if legislator.has_value?(state)
      local_legislators.push(legislator)
    end
  end

  # states = result.select { |key, value| [:state].include?(key) }

  return local_legislators # We've successfully extracted the right legislators from the API!

end

def create_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename,"w") do |file|
    file.puts form_letter
  end
end


client = ProPublica.new("zxqNXNeekwfd9kyXLAEpKWLKLOnfsMHsSbxLBJHG")

congress = 115 # Use a recent congress

template_letter = File.read "../templates/form_letter.erb"
erb_template = ERB.new template_letter # Creating a new file based on the template above

# 'open' is the CSV class equivalent of 'readlines'
contents = CSV.open "../event_attendees.csv", headers: true, header_converters: :symbol

contents.each do |row|
  id = row[0]
  name = row[:first_name] # We're setting this, and the variables below, with the right names for them to bind correctly with our ERB template
  
  state = row[:state]

  puts "Found state: #{state}"

  legislators = legislators_by_state(state, congress, client)

  # The line below actually generates the letter and loops through the legislators
  # This is the best way to pass variables into an ERB file and get results back
  if legislators != nil # New API doesn't find legislators for everyone (some attendees lived in PR, DC, etc.)
    form_letter = erb_template.result(binding) 
    puts "Created letter"
  end

  create_thank_you_letters("#{id}_v2" ,form_letter)
end

