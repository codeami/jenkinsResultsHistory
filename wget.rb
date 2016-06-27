#!/usr/bin/env ruby
# Usage - run 'ruby wget.rb' (update driver#, version# etc inside) to get ConsoleLogs "7XX0_128_DriverXX"
# Check if logs are complete run "grep Finished: *.log|tee /dev/tty| wc" should return total of 20 lines
version_no = '7.7.0.0'
version_name = '7700'
run_no = '194'

if ARGV[1] then
	$drivers_count = ARGV[1].to_i
	$i=ARGV[0].to_i
else
	if ARGV[0] then
		$drivers_count = ARGV[0].to_i
		$i=ARGV[0].to_i
	else
		$drivers_count = 20
		$i=1
	end
end

while $i <= $drivers_count do 
	op = "#{version_name}_#{run_no}_#{$i}.log"
	url = "http://<>/job/#{version_name}_<>_Tests/#{run_no}/driver=#{$i},label=driver/consoleText"
	puts url
	`echo #{url}| xargs -n 1 -P 20 wget -b -O #{op}`
	$i+=1
end
