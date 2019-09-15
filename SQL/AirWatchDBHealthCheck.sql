DECLARE @Interval CHAR(8) = '00:00:15'
DECLARE @interval_Seconds INT = (SELECT Sum(Left(@Interval,2) * 3600 + substring(@Interval, 4,2) * 60 + substring(@Interval, 7,2)))

DECLARE @SprocsScoped INT = 1000
DECLARE @TopSprocCountReturned INT = (SELECT @SprocsScoped*0.05)

IF OBJECT_ID('tempdb.dbo.#Landing1') IS NOT NULL
	DROP TABLE dbo.#Landing1

IF OBJECT_ID('tempdb.dbo.#Landing2') IS NOT NULL
	DROP TABLE dbo.#Landing2

SELECT TOP (@SprocsScoped)
		qs.database_id
	   ,qs.object_id
       ,DB_NAME(qs.database_id) [DB Name]
	   ,QUOTENAME(DB_NAME(qs.database_id))   
		+ N'.'   
		+ QUOTENAME(OBJECT_SCHEMA_NAME(qs.object_id, qs.database_id))   
		+ N'.'   
		+ QUOTENAME(OBJECT_NAME(qs.object_id, qs.database_id)) AS [SP Name]
	   ,qs.execution_count
	   ,qs.cached_time
       ,qs.total_worker_time
       ,qs.total_elapsed_time
       ,qs.min_elapsed_time
       ,qs.max_elapsed_time
       ,qs.min_logical_reads
       ,qs.max_logical_reads
       ,qs.min_logical_writes
       ,qs.max_logical_writes
       ,qs.plan_handle
       ,qs.sql_handle
INTO dbo.#Landing1
FROM sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
--WHERE qs.database_id = DB_ID()
ORDER BY total_worker_time DESC
OPTION (RECOMPILE);

WAITFOR DELAY @Interval --Two tenths of a second

DECLARE @AggSum2 BIGINT 
SET @AggSum2 =	(SELECT SUM(total_worker_time)
				FROM(
					SELECT TOP (@SprocsScoped) qs.total_worker_time 
       				FROM sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
					--WHERE qs.database_id = DB_ID()
					ORDER BY total_worker_time DESC	
					)AS T
					)

SELECT TOP (@SprocsScoped)
		qs.database_id
	   ,qs.object_id
       ,DB_NAME(qs.database_id) [DB Name]
	   ,QUOTENAME(DB_NAME(qs.database_id))   
		+ N'.'   
		+ QUOTENAME(OBJECT_SCHEMA_NAME(qs.object_id, qs.database_id))   
		+ N'.'   
		+ QUOTENAME(OBJECT_NAME(qs.object_id, qs.database_id)) AS [SP Name]
	   ,qs.execution_count
	   ,qs.cached_time
       ,qs.total_worker_time
       ,qs.total_elapsed_time
       ,qs.min_elapsed_time
       ,qs.max_elapsed_time
       ,qs.min_logical_reads
       ,qs.max_logical_reads
       ,qs.min_logical_writes
       ,qs.max_logical_writes
       ,qs.plan_handle
       ,qs.sql_handle
INTO dbo.#Landing2
FROM sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
--WHERE qs.database_id = DB_ID()
ORDER BY total_worker_time DESC
OPTION (RECOMPILE);

DECLARE @AggSum3 INT 
SET @AggSum3 = (SELECT SUM(WorkTime)
				FROM(
					SELECT (l2.total_worker_time - l1.total_worker_time) WorkTime
       				FROM dbo.#Landing1 l1
					FULL JOIN dbo.#Landing2 l2 ON l2.database_id = l1.database_id AND l2.[object_id] = l1.[object_id] AND l1.Cached_time = l2.Cached_time
					)AS T
					)

SELECT TOP (@TopSprocCountReturned)
	@interval_Seconds Interval_Seconds,
	l1.[DB Name], l1.[SP Name],
	(l2.execution_count - l1.execution_count) ExecutionCounts_Delta,
	((l2.execution_count - l1.execution_count)/@interval_Seconds) [CallsPerSec_InWindow],
	(l2.total_worker_time - l1.total_worker_time) TotalWorkerTime_Delta,
	
	CASE
		WHEN (l2.execution_count - l1.execution_count) = 0 THEN 0
		ELSE ((l2.total_worker_time - l1.total_worker_time)/((l2.execution_count - l1.execution_count))) 
	END AS AvgWorkerTime_InWindow,

	(l2.total_elapsed_time - l1.total_elapsed_time) TotalElapsedTime_Delta,
	
	CASE
		WHEN (l2.execution_count - l1.execution_count) = 0 THEN 0
		ELSE ((l2.total_elapsed_time - l1.total_elapsed_time)/((l2.execution_count - l1.execution_count))) 
	END AS AvgElapsed_InWindow,
	
	CASE
		WHEN (l2.execution_count - l1.execution_count) = 0 THEN 0
		ELSE 100 *(1.0 - ((l2.total_worker_time - l1.total_worker_time)) * 1.0 / ((l2.total_elapsed_time - l1.total_elapsed_time)) * 1.0)
	END AS Percent_Waiting,

	CASE
		WHEN (l2.execution_count - l1.execution_count) = 0 THEN 0
		ELSE 100 * ((l2.total_worker_time - l1.total_worker_time)) *1.0 / @AggSum3 * 1.0
	END AS 'PctOfTotal',
	
	l2.cached_time,
	l2.plan_handle, 
	l2.[sql_handle],
	l2.min_elapsed_time,
	l2.max_elapsed_time,
	l2.min_logical_reads,
	l2.max_logical_reads,
	l2.min_logical_writes,
	l2.max_logical_writes
FROM dbo.#Landing1 l1
FULL JOIN dbo.#Landing2 l2 ON l2.database_id = l1.database_id AND l2.[object_id] = l1.[object_id] AND l1.Cached_time = l2.Cached_time
ORDER BY TotalWorkerTime_Delta DESC

SELECT TOP (@TopSprocCountReturned)
	 [DB Name]
    ,[SP Name]
    ,execution_count
    ,CASE
		WHEN DATEDIFF(second, cached_time, GETDATE()) = 0 THEN 0
		ELSE execution_count/DATEDIFF(second, cached_time, GETDATE()) 
		END AS [Calls/Second]
    ,total_worker_time
    ,CASE
		WHEN execution_count = 0 THEN 0
		ELSE total_worker_time/execution_count
		END AS [avg_worker_time]
    ,total_elapsed_time
    ,CASE
		WHEN execution_count = 0 THEN 0
		ELSE total_elapsed_time/execution_count
		END AS [avg_elapsed_time]
    ,CASE
		WHEN total_elapsed_time = 0 THEN 0
		ELSE 100 *(1.0 - total_worker_time*1.0 / total_elapsed_time*1.0) 
		END AS percent_waiting
	,CASE
		WHEN total_elapsed_time = 0 THEN 0
		ELSE 100 * total_worker_time*1.0 / @AggSum2*1.0 
		END AS 'PctOfTotal'
	,cached_time
    ,min_elapsed_time
    ,max_elapsed_time
    ,min_logical_reads
    ,max_logical_reads
    ,min_logical_writes
    ,max_logical_writes
    ,plan_handle
    ,sql_handle
FROM dbo.#Landing2