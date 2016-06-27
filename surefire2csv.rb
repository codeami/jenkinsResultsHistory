# Prerequisite - update and run 'ruby wget.rb' (update driver#, version# etc inside) to get ConsoleLogs "7XX0_128_DriverXX"
# 
# To run this script update driver#, version# etc below)  run 'ruby surefire2csv.rb'
# This script creates a csv (uploadable to google spreadsheet) 
# csv headers = "Drv#, TC#, Result, Error, Trace, Diff vs #{prev_run_no}, Diff Status, Result Trend\n"
# Temp "Buf" files created help count total Errors "wc -l *.buf" VS  total stackTraces 


# KNOWN  Limitation:  
  #  Scripts' Cleanup Methods' Errors' StackTraces are at times missing TestCase Name (Bug ID?) 
  #   ergo such StackTraces are too generic to match regex
  #   so the exact Line Number where trace begins in the Cleanup Method is needed
  #   Any new Cleanup StackTrace Line numbers need to be updated  MANUALLY in command at line number ~ 69  `egrep #{fn} -B #{trace_depth} ...
# WORKAROUND  for Issue #1 - Manual intervention
  #   ** How to Add new Cleanup StackTrace Line numbers **
  #   Note: Different "egrep + perl substitution" commands create + populate temp "buf" files per driverLog.
  #   run "wc -l *.buf" in Working Dir. Temp "Buf" files created help count total Lines of Errors "wc -l *.buf" VS  total Lines of stackTraces
  #   opErr_7700_193_20.log.buf -- List of Errors   = X
  #   opTrace_7700_193_8.log.buf  -- List of Stack Traces  = Y    
  #   IF X !=Y, The Script fails. Usally X >Y , 
  #      so diff out the Test(s) missing the "cleanup" stack trace(s)
  #      Find this Test(s)' Cleanup StackTrace Line number in Main DriverConsole.Log file
  #       Add this line munber to formula `egrep #{fn} -B #{trace_depth} .. 
  #       EX: (118|127|128|102|104|105|111|119|150| <ADD newLine number anywhere>)
  #        Re-run the script

 

#!/usr/bin/env ruby

require 'fileutils'
require "Tempfile"

# Run Details
version_name = '7700'
run_no = '198'
# Name Final CSV result file
fnAll = version_name+"_"+run_no+".csv"


# Previous run details for diff 
prev_run=true
prev_run_no=run_no.to_i-4

# Initialize Run variables
$drivers_count=20
$n=1

# Script Variables
trace_depth=6
sleep_between_drivers=0
debug_mode=false


# Create File Handle for Temp file 
t_file2 = Tempfile.new('csv_temp.txt')
# Add Header
t_file2.write("Drv#,TC#,Result,Error,Trace,Diff vs #{prev_run_no},Diff Status,Result Trend\n")

# Read  Previous Run's Final CSV files'  for generating diff
if (not debug_mode and prev_run)
  prev_run_fn="../#{prev_run_no}/#{version_name}_#{prev_run_no}.csv"
  fprev = IO.readlines("#{prev_run_fn}")
  l=1 # ignore first line of prev csv file is Column Header  # l = line Counter for prev CSV files
end


# TODO: Usage
def inc_prev_run_ctr(fprev,l)
  if (fprev[l+1])                               # increment prevRunCtr if not last line
    return l+1 
  else
    return l
  end
end

# TODO: Usage
def generate_diff_string(fprev,l,tcRes)
  tcResPrev = fprev[l].split(",")[2].to_s.chomp.strip       # extract prevRunResult from prevRunCSVLine
  tcResDiff=tcResPrev+"> "+tcRes                             # diff String
  l=inc_prev_run_ctr(fprev,l)
  return tcResDiff,l,tcResPrev
end

# Main loop for each driver
while $n <= $drivers_count do 
  # Initialize  Input Console Log Per Driver File Name
  fn = version_name+"_"+run_no+"_"+$n.to_s+".log"
  $stdout.sync = true
  print $n
  # Initialize  Previous Run's perDriver CSV files'  for generating diff
  if debug_mode 
    prev_run_fn="../#{prev_run_no}/#{version_name}_#{prev_run_no}_"+$n.to_s+".log.csv"
    fprev = IO.readlines("#{prev_run_fn}")
    l=0
  end
  
  # The following 3 egrep + perl substitution commands create + populate 3 temp "buf" files per driverLog Ex::-
  # opErr_7700_193_20.log.buf -- List of Errors   = X
  # opTrace_7700_193_8.log.buf  -- List of Stack Traces  = Y    #### IF X !=Y, The Script fails.
  # opSkip_7700_193_8  -- List of skipped Cases
  `egrep #{fn} -A 30 -e"(< ERROR|< FAILURE)"| egrep -v ")$"| egrep -v "(Build|System|Driver) info:"|perl -pe 's/_execute.*\!/  /;' -pe 's/\t//;' -pe 's/\n/ /;' -e 's/--/\n/g;' -pe 's/(at |)com.sugarcrm.(sugar.|test.)//g;' -pe 's/Time.*<<<.*!//;' -pe 's/Tests run: ., //;' -pe 's/Failures: 0, //;' -pe 's/Skipped: 0, //;' -pe 's/Errors: 0, //;' -pe 's/Failures: 1, Errors: 1, /Failures: 1;Errors: 1;  /;' -pe 's/Errors: 2, /Errors: 2  /;' -pe 's/1,/1 /;' -pe s'/\\,/\\;/g;' -pe s'/^\s//g;' >opErr_#{fn}.buf`
  `printf "=\\"" >opTrace_#{fn}.buf`
  `egrep #{fn} -B #{trace_depth} -e"([_,\\.]\\w{3,10}\\(\\w.*_(\\d{5}|.*).*\\.java\\:\\d{1,3}\\)|SugarTest\\.(base|standard)(Setup|Cleanup|CleanUp)\\(SugarTest\\.java\\:(118|127|128|102|104|105|111|119|150|169|38|39|110|178|116|159|166|165|124|73|47)\\))"|perl -pe 's/\\"/\\"\\"/g;' -pe 's/\\t//;' -pe 's/^\\n//;' -pe 's/\\n/\"\\&CHAR(10)&\\"/;' -pe 's/--/\\n/g'|perl -pe 's/at com.sugarcrm.(sugar.|test.)//g;' -pe 's/\\"\\&/\\"\\=/;' -pe 's/\\&\\"$//;' -pe 's/\\!\\"\\=CHAR/\\"\\&CHAR/;' -pe s'/^\\"//;' -pe s'/\\,/\\;/g;' -pe s'/\\"\\=CHAR/\\"\\&CHAR/;' -pe s'/^\\=CHAR\\(10\\)\\&/\\=/g;' -pe s'/\\&CHAR\\(10\\)$//g;'>>opTrace_#{fn}.buf`
  `egrep #{fn} -B 1 -e 'Skipped\: 1'|perl -pe 's|\n||;' -pe 's/--/\n/;'>opSkip_#{fn}.buf`
  sleep sleep_between_drivers

  
  # Initialize line counters for Err,Trace,Skip files
  i=0
  j=0
  k=0
  ferr = IO.readlines("opErr_#{fn}.buf")
  fstack = IO.readlines("opTrace_#{fn}.buf")
  fskip = IO.readlines("opSkip_#{fn}.buf")
  
  # Regex pattern matching first line of each new testcase 
  pattern=Regexp.new("Running com.*")
  
  # Create Temp file handle
  t_file = Tempfile.new('csv2_temp.txt')
  # TODO: add Debug info:  t_file.write("Drv #{$n}, TCs,Error,Trace\n")
  # Open consoleLog files
  File.open("#{fn}" , 'r') do |f|
  f.each_line do |line|  # For each line
    unless (match = line.scan(pattern)).empty? # if it matches TC name pattern
    tcName = line.split(".").last.to_s.chomp # extract TC name
            
    if ferr[i] and ferr[i].to_str.chomp.include? tcName then # if current Err line has current TC name
      tcRes = ferr[i].split("   ")[0].to_s.chomp.strip        #extract Result from error
      tcErr = ferr[i].split("   ")[2].to_s.chomp #extract Error from error
       if prev_run and fprev[l] and fprev[l].to_str.chomp.include? tcName then  # if prevRunCSVLine has current TC name
          tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
        else
          # Sometimes TestCase(s) is removed, ergo check prevRunCSVLine +1 has current TC name
          if prev_run and fprev[l+1] and fprev[l+1].to_str.chomp.include? tcName then
            tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
          else
            if debug_mode then
              tcResDiff = "New4_"+"#{l}"+"__#{tcName}"+"__#{fprev[l]}"
            else
              tcResDiff = "New4"
            end
          end
        end
        if tcResPrev and tcRes and tcResPrev != tcRes then
          if (tcRes.include? "Error" or tcRes.include? "Fail") and (tcResPrev.include? "Error" or tcResPrev.include? "Fail") then
            tcResDiffStatus=",Warning"
          else
            tcResDiffStatus=",Severe"
          end
            
        else
          tcResDiffStatus=""
        end

        putStr = "#{$n}"+","+tcName+","+tcRes+","+tcErr+","+fstack[j].to_str.chomp+","+tcResDiff+tcResDiffStatus
        t_file.puts putStr

          if (ferr[i]!=ferr.last) then
            i+=1
            j+=1
            # Check if next error is for same TC  (2nd err is usually cleanuperr) 
            if ferr[i].to_str.chomp.include? tcName then
              tcRes = "Error: Cleanup" #ferr[i].split("   ")[0].to_s.chomp
              tcErr = ferr[i].split("   ")[1].to_s.chomp

                if prev_run and fprev[l] and fprev[l].to_str.chomp.include? tcName then
                  tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
                else
                  tcResDiff = "Cleanup"+"> "+tcRes
                end
              
              t_file.puts "#{$n}"+","+tcName+","+tcRes+","+tcErr+","+fstack[j].to_str.chomp+","+tcResDiff
              if (ferr[i]!=ferr.last)
                i+=1
                j+=1
              end

            end
          end

        else

          if fskip[k] and fskip[k].to_str.chomp.include? tcName then
            tcRes="Skipped: 1"

              if prev_run and fprev[l] and fprev[l].to_str.chomp.include? tcName then
                tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
              else # case NEVER happens - tested in debug version
                tcResDiff= "New3"+"> "+tcRes
              end


           t_file.puts "#{$n}"+","+tcName+","+tcRes+",,,"+tcResDiff
            if (fskip[k+1]!=fskip.last) 
              k+=1 
            end


          else
            tcRes="Passed"
            if prev_run and fprev[l] and fprev[l].to_str.chomp.include? tcName then # if prevRunCSVLine has TC
              tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
            else
              # Sometimes TestCase(s) is removed, ergo check prevRunCSVLine +1 has current TC name
              if prev_run and fprev[l+1] and fprev[l+1].to_str.chomp.include? tcName then
                l+=1 # if prevRunCSV Next Line macthes TC
                tcResDiff,l,tcResPrev = generate_diff_string(fprev,l,tcRes)
              else
                if debug_mode then
                  tcResDiff = "New4_"+"#{l}"+"__#{tcName}"+"__#{fprev[l]}"
                else
                  tcResDiff = "New4"
                end
              end
            end
            t_file.puts "#{$n}"+","+tcName+","+tcRes+",,,"+tcResDiff
        
            if prev_run and fprev[l] and fprev[l].to_str.chomp.include? tcName then # tcResPrev = "Error: 2"
              inc_prev_run_ctr(fprev,l)
            end
          end
        end
      end
    end
    t_file.close
    FileUtils.mv(t_file.path, "./#{fn}.csv")
    t_file.unlink

    t_file2.puts IO.read ("./#{fn}.csv") 
    FileUtils.rm("./opSkip_#{fn}.buf")

  end
  $n+=1
end
t_file2.close
FileUtils.mv(t_file2.path, "./#{fnAll}")
t_file2.unlink
