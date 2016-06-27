# jenkinsResultsHistory
## Log Analysis script
*gets, parses, converts Jenkins run logs into compact csv report for analysis*


#### Advantages:- 
* Sort + Filterable columns of Errors and stackTrace (helps see failure/error patterns, esp when fail/error spike)
* Historical/Future results for each Test are listed (helps see intermittent failures "flapping results") 
(Using spreadsheet functions - TODO: move pastResults logic to script)
* Test Results are listed in order of execution (helps find root cause) 
(not easy to see order of execution in Surefire/Allure - need to refer to consoleLogs/Allure timeline hover-tooltip which is very slow)
* Diff vs Previous run is generated-(new result types for cleanup/setup error,fail+error etc)
* Easy to learn, maintain and add features


#### Issues:-
* Make script modular + read Jenkin run status and trigger + uploading csv ..
* Ruby script should use native regex,lib support (at present wget,egrep, and perl are being used)
* Improve usability (help text etc), avoid Anti-Patterns


### Enhancements:-
* Add new columns "Steps leading to Failure", "Failure step" (grep out the exact Line that failed, previous 5 lines ignoring blank ones) This will help narrow down root cause of failure faster. Also sorting/grouping by failedstep will help see patterns if any)
* Add new/update existing column in "skipped" TCs with @Ignore tag line containing Product/AutomationLibrary bug + get the status of this bug
