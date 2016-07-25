
# Helpline MI reports listing.
get '/helpline-mi' do
  authenticate!
  Dir.chdir(settings.helpline_mi_directory)

  # Sort the list of files by creation time, newest first.
  names = Dir['*.csv'].sort_by { |f| File.ctime(f) }.reverse
  erb :helpline_mi, layout: :simple_layout, locals: { title: 'Helpline MI Reports',
                                                      names: names }
end

# Download an individual Helpline MI report.
get '/helpline-mi/:report' do |report|
  authenticate!
  file = "#{settings.helpline_mi_directory}/#{report}"
  send_file(file, type: 'text/csv', disposition: :attachment) if File.exist?(file)
end
