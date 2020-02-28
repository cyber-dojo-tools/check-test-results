
# This scrapes data from two sources
# 0) The minitest stdout which is tee'd to test.log
# 1) The simplecov coverage index.html file.
#    It would be nice if simplecov saved the raw data to a json file
#    and created the html from that, but alas it does not.
#    At the moment its from simplecov 0.17.0
#    Simplecov will soon support branch-coverage.

require_relative 'metrics'

# - - - - - - - - - - - - - - - - - - - - - - -
def fatal_error(message)
  puts message
  exit(42)
end

# - - - - - - - - - - - - - - - - - - - - - - -
def coverage_code_group_name
  ENV['COVERAGE_CODE_GROUP_NAME']
end

# - - - - - - - - - - - - - - - - - - - - - - -
def coverage_test_group_name
  ENV['COVERAGE_TEST_GROUP_NAME']
end

# - - - - - - - - - - - - - - - - - - - - - - -
def test_log
  $test_log ||= begin
    path = ARGV[0] # eg /app/data/test.log
    cleaned(`cat #{path}`)
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -
def index_html
  $index_html = begin
    path = ARGV[1] # eg /app/data/index.html
    cleaned(`cat #{path}`)
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -
def cleaned(s)
  # guard against invalid byte sequence
  s = s.encode('UTF-16', 'UTF-8', :invalid => :replace, :replace => '')
  s = s.encode('UTF-8', 'UTF-16')
end

# - - - - - - - - - - - - - - - - - - - - - - -
def number
  '[\.|\d]+'
end

# - - - - - - - - - - - - - - - - - - - - - - -
def f2(s)
  result = ("%.2f" % s).to_s
  result += '0' if result.end_with?('.0')
  result
end

# - - - - - - - - - - - - - - - - - - - - - - -
def coloured(tf)
  red = 31
  green = 32
  colourize(tf ? green : red, tf)
end

# - - - - - - - - - - - - - - - - - - - - - - -
def colourize(code, word)
  "\e[#{code}m #{word} \e[0m"
end

# - - - - - - - - - - - - - - - - - - - - - - -
def get_index_stats(name)
  # It would be nice if simplecov saved the raw data to a json file
  # and created the html from that, but alas it does not.
  if index_html.include?('v0.17.0')
    return get_index_stats_gem_0_17_0(name)
  end
  if index_html.include?('v0.17.1')
    return get_index_stats_gem_0_17_0(name)
  end
  if index_html.include?('v0.18.1')
    return get_index_stats_gem_0_18_1(name)
  end
  fatal_error('Unknown simplecov version')
end

# - - - - - - - - - - - - - - - - - - - - - - -
def get_index_stats_gem_0_17_0(name)
  pattern = /<div class=\"file_list_container\" id=\"#{name}\">
  \s*<h2>\s*<span class=\"group_name\">#{name}<\/span>
  \s*\(<span class=\"covered_percent\"><span class=\"\w+\">([\d\.]*)\%<\/span><\/span>
  \s*covered at
  \s*<span class=\"covered_strength\">
  \s*<span class=\"\w+\">
  \s*(#{number})
  \s*<\/span>
  \s*<\/span> hits\/line\)
  \s*<\/h2>
  \s*<a name=\"#{name}\"><\/a>
  \s*<div>
  \s*<b>#{number}<\/b> files in total.
  \s*<b>(#{number})<\/b> relevant lines./m

  r = index_html.match(pattern)
  fatal_error('REGEX match failed...') if r.nil?

  h = {}
  h[:coverage]      = f2(r[1])
  h[:hits_per_line] = f2(r[2])
  h[:line_count]    = r[3].to_i
  h[:name] = name
  h
end

# - - - - - - - - - - - - - - - - - - - - - - -
def get_index_stats_gem_0_18_1(name)
  pattern = /<div class=\"file_list_container\" id=\"#{name}\">
  \s*<h2>\s*<span class=\"group_name\">#{name}<\/span>
  \s*\(<span class=\"covered_percent\">
  \s*<span class=\"\w+\">
  \s*([\d\.]*)\%\s*<\/span>\s*<\/span>
  \s*covered at
  \s*<span class=\"covered_strength\">
  \s*<span class=\"\w+\">
  \s*(#{number})
  \s*<\/span>
  \s*<\/span> hits\/line
  \s*\)
  \s*<\/h2>\s*
  \s*<a name=\"#{name}\"><\/a>\s*
  \s*<div>\s*
  \s*<b>#{number}<\/b> files in total.\s*
  \s*<\/div>\s*
  \s*<div class=\"t-line-summary\">\s*
  \s*<b>(#{number})<\/b> relevant lines./m

  r = index_html.match(pattern)
  fatal_error('REGEX match failed...') if r.nil?

  h = {}
  h[:coverage]      = f2(r[1])
  h[:hits_per_line] = f2(r[2])
  h[:line_count]    = r[3].to_i
  h[:name] = name
  h
end

# - - - - - - - - - - - - - - - - - - - - - - -
def get_test_log_stats
  stats = {}

  warning_regex = /: warning:/m
  stats[:warning_count] = test_log.scan(warning_regex).size

  finished_pattern = "Finished in (#{number})s, (#{number}) runs/s"
  m = test_log.match(Regexp.new(finished_pattern))
  stats[:time]               = f2(m[1])
  stats[:tests_per_sec]      = m[2].to_i

  summary_pattern =
    %w(runs assertions failures errors skips)
    .map{ |s| "(#{number}) #{s}" }
    .join(', ')
  m = test_log.match(Regexp.new(summary_pattern))
  stats[:test_count]      = m[1].to_i
  stats[:assertion_count] = m[2].to_i
  stats[:failure_count]   = m[3].to_i
  stats[:error_count]     = m[4].to_i
  stats[:skip_count]      = m[5].to_i

  stats
end

# - - - - - - - - - - - - - - - - - - - - - - -
log_stats = get_test_log_stats
test_stats = get_index_stats(coverage_test_group_name)
app_stats = get_index_stats(coverage_code_group_name)

# - - - - - - - - - - - - - - - - - - - - - - -
test_count    = log_stats[:test_count]
failure_count = log_stats[:failure_count]
error_count   = log_stats[:error_count]
warning_count = log_stats[:warning_count]
skip_count    = log_stats[:skip_count]
test_duration = log_stats[:time].to_f

app_coverage  = app_stats[:coverage].to_f
test_coverage = test_stats[:coverage].to_f

line_ratio = (test_stats[:line_count].to_f / app_stats[:line_count].to_f)

#puts " app_stats[:hits_per_line] == #{app_stats[:hits_per_line].to_f}"
#puts "test_stats[:hits_per_line] == #{test_stats[:hits_per_line].to_f}"

hits_ratio = (app_stats[:hits_per_line].to_f / test_stats[:hits_per_line].to_f)

table = [
  [ 'failures',               failure_count,  '<=',  MAX[:failures] ],
  [ 'errors',                 error_count,    '<=',  MAX[:errors] ],
  [ 'warnings',               warning_count,  '<=',  MAX[:warnings] ],
  [ 'skips',                  skip_count,     '<=',  MAX[:skips] ],
  [ 'duration(test)[s]',      test_duration,  '<=',  MAX[:duration] ],
#  [ 'tests',                  test_count,     '>=',  MIN[:test_count] ],
  [ 'coverage(tested)[%]',    app_coverage,   '>=',  MIN[:app_coverage] ],
  [ 'coverage(tester)[%]',    test_coverage,  '>=',  MIN[:test_coverage] ],
  [ 'lines(tester/tested)',   f2(line_ratio), '>=',  MIN[:line_ratio] ],
  [ 'hits(tested/tester)',    f2(hits_ratio), '>=',  MIN[:hits_ratio] ],
]

# - - - - - - - - - - - - - - - - - - - - - - -
done = []
puts
table.each do |name,value,op,limit|
  result = eval("#{value} #{op} #{limit}")
  puts "%s | %s %s %s | %s" % [
    name.rjust(25), value.to_s.rjust(7), "  #{op}", limit.to_s.rjust(5), coloured(result)
  ]
  done << result
end
puts
exit done.all?
