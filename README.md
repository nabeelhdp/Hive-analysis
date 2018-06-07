# Hive-analysis

To execute, simply run the script with an HS2 log as the argument. 
Eg.
```bash
[nmoidu@HW15016 Downloads]$ sh Hive_stage_analysis.sh HaaS_Jan_2018/hiveserver2.log
=========================================
Log_start_time : 2018-01-25 00:00:00
Log_end_time : 2018-01-25 22:34:45
Last_query_parsed_at : 2018-01-25 22:00:36,767

Total_Number_of_Queries_Parsed : 45207
Total_number_of_Beeline_sessions : 2528
Total_Number_of_Metastore_hits : 381746
=========================================

Top_3_beeline_users
=========================================
anonymous : 882
app.user.001 : 592
user2 : 254
=========================================

Top_3_metastore_users
=========================================
g.user.001  : 184188
g.user2.001 : 104713
g.user1.001 : 39657
=========================================

Top_3_metastore_commands
=========================================
get_table : 157370
get_partition_with_auth : 116156
partition_name_has_valid_characters : 20029
=========================================

Time_spent_per_phase_of_execution
Method_name Total Min Max Average
=========================================
Driver.run 29346524292 17477067 65330.6
|=Driver.execute 29609454462 17477066 65725.8
|== compile 788925331 2527057 1750.13
|==== parse 266140 630 0.590582
|==== semanticAnalyze 774334310 2527053 1719.67
|====== partition-retrieving 6566680 10756 19.521
|====== getInputSummary 3009136 601 300.9
|====== doAuthorization 13539110 4787 30.0682
|====== serializePlan 2380 7 1.20202
|====== deserializePlan 3010 7 1.54359
|=== releaseLocks 82300 22 0.090896
|== PreHook.o.a.h.h.ql.h.ATSHook 270770 34 0.601484
|== PreHook.o.a.h.h.ql.s.a.p.DisallowTransformHook 24310 21 0.0540018
|== TimeToSubmit 811130 892 1.80183
|== runTasks 29421104600 17477064 65483.6
|== PostHook.o.a.h.h.ql.hooks.ATSHook 224830 41 0.500512
=========================================
```
Piping it to column -t normally gives a cleaner output.

Eg.
```bash
[nmoidu@HW15016 Downloads]$ sh Hive_stage_analysis.sh HaaS_Jan_2018/hiveserver2.log |column -t

=========================================
Log_start_time                                     :            2018-01-25  00:00:00
Log_end_time                                       :            2018-01-25  22:34:45
Last_query_parsed_at                               :            2018-01-25  22:00:36,767
Total_Number_of_Queries_Parsed                     :            45207
Total_number_of_Beeline_sessions                   :            2528
Total_Number_of_Metastore_hits                     :            381746
=========================================
Top_3_beeline_users
=========================================
anonymous                                          :            882
app.user.001                                       :            592
user2                                              :            254
=========================================
Top_3_metastore_users
=========================================
g.user.001                                         :            184188
g.user1.001                                        :            104713
g.user2.001                                        :            39657
=========================================
Top_3_metastore_commands
=========================================
get_table                                          :            157370
get_partition_with_auth                            :            116156
partition_name_has_valid_characters                :            20029
=========================================
Time_spent_per_phase_of_execution
Method_name                                        Total        Min         Max           Average
=========================================
Driver.run                                         29346524292  17477067    65330.6
|=Driver.execute                                   29609454462  17477066    65725.8
|==compile                                         788925331    2527057     1750.13
|====parse                                         266140       630         0.590582
|====semanticAnalyze                               774334310    2527053     1719.67
|======partition-retrieving                        6566680      10756       19.521
|======getInputSummary                             3009136      601         300.9
|======doAuthorization                             13539110     4787        30.0682
|======serializePlan                               2380         7           1.20202
|======deserializePlan                             3010         7           1.54359
|===releaseLocks                                   82300        22          0.090896
|==PreHook.o.a.h.h.ql.h.ATSHook                    270770       34          0.601484
|==PreHook.o.a.h.h.ql.s.a.p.DisallowTransformHook  24310        21          0.0540018
|==TimeToSubmit                                    811130       892         1.80183
|==runTasks                                        29421104600  17477064    65483.6
|==PostHook.o.a.h.h.ql.hooks.ATSHook               224830       41          0.500512
=========================================
```
