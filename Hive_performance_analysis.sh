#!/bin/bash

HIVE_LOG_DIR=/var/log/hive/
HIVESERVER2_PORT=10000

if [ $# -eq 1 ];
then
LOGFILE=$1
#LOGFILE=$HIVE_LOG_DIR/$1
else
LOGFILE = $HIVE_LOG_DIR/hiveserver2.log
fi

if [[ ! -r "$LOGFILE" ]]; then
echo "File $LOGFILE does not exist"
exit
fi

awk '
/^2018/ {
	if (NR == 1) {
		split($0, start_time, ",")
	}

  switch ($6) {
    case "parse.ParseDriver":
      if (match("Parsing", $9) && match("command:", $10)) {
        if (!match("show", $11) && !match("set", $11) && !match("use", $11) && !match("describe", $11)) {
          number_of_queries_total += 1;
          number_of_queries[toupper($11)] += 1;
          last_query_time = $1 " "$2
        }
      }
      break
    case "HiveMetaStore.audit":
      if ( $9 ~ "ugi=") {
        split($9,metastore_user,"=")
        split($11,metastore_command,"=")
        metastore_hits_user[metastore_user[2]] += 1
        total_metastore_hits += 1
        metastore_hits_command[metastore_command[2]] += 1
      }
      break
    case "session.SessionState":
      if (match("Created", $9)) {
        if (match("HDFS", $10) && match("directory:", $11) && ( $12 ~ "/tmp/hive/")) {
          if (!match("ambari-qa", $NF) && !match("space.db", $NF) && !match("rangerlookup", $NF) && !match("main", $NF)) {
            split($12,beeline_user,"/")
            beeline_sessions_by_user[beeline_user[4]] += 1;
            number_of_beeline_sessions += 1;
          }
        }
      }
      break
    }

    if ((match("log.PerfLogger", $6)) && ( $(NF-1) ~ "duration") ) {
      split($(NF-1), duration_current_query, "=")
      split($10,x,"=")
      method=x[2]

    duration_per_method[method] += duration_current_query[2]
    if (length(max_duration_per_method[method]) == 0){
      max_duration_per_method[method]=duration_current_query[2]
    }
    else {
      if(duration_current_query[2]>max_duration_per_method[method]){
        max_duration_per_method[method]=duration_current_query[2]
      }
    }

    if (length(min_duration_per_method[method]) == 0){
      min_duration_per_method[method]=duration_current_query[2]
    }
    else{
      if(duration_current_query[2]<min_duration_per_method[method]){
        min_duration_per_method[method]=duration_current_query[2]
      }
    }

    count_per_method[method] += 1
  }

  date_time = $1 " " $2;
  split(date_time, stop_time, ",")
}
END {
    print "========================================="
    print "Log_start_time : " start_time[1]
    print "Log_end_time : "   stop_time[1]
    print "Last_query_parsed_at : "  last_query_time
    print "\nTotal_Number_of_Queries_Parsed : " number_of_queries_total
    print "Total_number_of_Beeline_sessions : " number_of_beeline_sessions
    print "Total_Number_of_Metastore_hits : " total_metastore_hits
    print "========================================="
    print "\nTop_3_beeline_users"
    print "========================================="
    cntr=0;
    PROCINFO["sorted_in"] = "@val_num_desc"
    for (b_user in beeline_sessions_by_user)
      if(cntr<3){
        print b_user " : "beeline_sessions_by_user[b_user]
        cntr++
        }

    print "========================================="
    print "\nTop_3_metastore_users"
    print "========================================="
    user_cntr=0
    PROCINFO["sorted_in"] = "@val_num_desc"
    for (m_user in metastore_hits_user)
      if(user_cntr<3){
        print m_user " : "metastore_hits_user[m_user]
        user_cntr++
        }

    print "========================================="
    print "\nTop_3_metastore_commands"
    print "========================================="
    cmd_cntr=0
    PROCINFO["sorted_in"] = "@val_num_desc"
    for (m_cmd in metastore_hits_command)
      if(cmd_cntr<3){
        print m_cmd " : "metastore_hits_command[m_cmd]
        cmd_cntr++
        }

    print "========================================="
    print "\nTime_spent_per_phase_of_execution"
    print "Method_name Total Min Max Average"
    print "========================================="
		print "Driver.run " duration_per_method["Driver.run"] min_duration_per_method["Driver.run"],max_duration_per_method["Driver.run"],\
		 duration_per_method["Driver.run"]/count_per_method["Driver.run"]
		print "|=Driver.execute " duration_per_method["Driver.execute"] min_duration_per_method["Driver.execute"],max_duration_per_method["Driver.execute"],\
		  duration_per_method["Driver.execute"]/count_per_method["Driver.execute"]
		print "|==compile " duration_per_method["compile"] min_duration_per_method["compile"],max_duration_per_method["compile"],\
		  duration_per_method["compile"]/count_per_method["compile"]
		print "|====parse " duration_per_method["parse"] min_duration_per_method["parse"],max_duration_per_method["parse"],\
		  duration_per_method["parse"]/count_per_method["parse"]
		print "|====semanticAnalyze " duration_per_method["semanticAnalyze"] min_duration_per_method["semanticAnalyze"],max_duration_per_method["semanticAnalyze"],\
		  duration_per_method["semanticAnalyze"]/count_per_method["semanticAnalyze"]
		print "|======partition-retrieving " duration_per_method["partition-retrieving"] min_duration_per_method["partition-retrieving"],max_duration_per_method["partition-retrieving"],\
		  duration_per_method["partition-retrieving"]/count_per_method["partition-retrieving"]
		print "|======getInputSummary " duration_per_method["getInputSummary"] min_duration_per_method["getInputSummary"],max_duration_per_method["getInputSummary"],\
		  duration_per_method["getInputSummary"]/count_per_method["getInputSummary"]
		print "|======doAuthorization " duration_per_method["doAuthorization"] min_duration_per_method["doAuthorization"],max_duration_per_method["doAuthorization"],\
		  duration_per_method["doAuthorization"]/count_per_method["doAuthorization"]
		print "|======serializePlan " duration_per_method["serializePlan"] min_duration_per_method["serializePlan"],max_duration_per_method["serializePlan"],\
		  duration_per_method["serializePlan"]/count_per_method["serializePlan"]
		print "|======deserializePlan " duration_per_method["deserializePlan"] min_duration_per_method["deserializePlan"],max_duration_per_method["deserializePlan"],\
		  duration_per_method["deserializePlan"]/count_per_method["deserializePlan"]
		print "|===releaseLocks " duration_per_method["releaseLocks"] min_duration_per_method["releaseLocks"],max_duration_per_method["releaseLocks"],\
		  duration_per_method["releaseLocks"]/count_per_method["releaseLocks"]
		print "|==PreHook.o.a.h.h.ql.h.ATSHook " duration_per_method["PreHook.org.apache.hadoop.hive.ql.hooks.ATSHook"] min_duration_per_method["PreHook.org.apache.hadoop.hive.ql.hooks.ATSHook"],max_duration_per_method["PreHook.org.apache.hadoop.hive.ql.hooks.ATSHook"],\
		  duration_per_method["PreHook.org.apache.hadoop.hive.ql.hooks.ATSHook"]/count_per_method["PreHook.org.apache.hadoop.hive.ql.hooks.ATSHook"]
		print "|==PreHook.o.a.h.h.ql.s.a.p.DisallowTransformHook " duration_per_method["PreHook.org.apache.hadoop.hive.ql.security.authorization.plugin.DisallowTransformHook"] min_duration_per_method["PreHook.org.apache.hadoop.hive.ql.security.authorization.plugin.DisallowTransformHook"],max_duration_per_method["PreHook.org.apache.hadoop.hive.ql.security.authorization.plugin.DisallowTransformHook"],\
		  duration_per_method["PreHook.org.apache.hadoop.hive.ql.security.authorization.plugin.DisallowTransformHook"]/count_per_method["PreHook.org.apache.hadoop.hive.ql.security.authorization.plugin.DisallowTransformHook"]
		print "|==TimeToSubmit " duration_per_method["TimeToSubmit"] min_duration_per_method["TimeToSubmit"],max_duration_per_method["TimeToSubmit"],\
		  duration_per_method["TimeToSubmit"]/count_per_method["TimeToSubmit"]
		print "|==runTasks " duration_per_method["runTasks"] min_duration_per_method["runTasks"],max_duration_per_method["runTasks"],\
		  duration_per_method["runTasks"]/count_per_method["runTasks"]
		print "|==PostHook.o.a.h.h.ql.hooks.ATSHook " duration_per_method["PostHook.org.apache.hadoop.hive.ql.hooks.ATSHook"] min_duration_per_method["PostHook.org.apache.hadoop.hive.ql.hooks.ATSHook"],max_duration_per_method["PostHook.org.apache.hadoop.hive.ql.hooks.ATSHook"],\
		  duration_per_method["PostHook.org.apache.hadoop.hive.ql.hooks.ATSHook"]/count_per_method["PostHook.org.apache.hadoop.hive.ql.hooks.ATSHook"]
print "========================================="

}
' "$LOGFILE"
