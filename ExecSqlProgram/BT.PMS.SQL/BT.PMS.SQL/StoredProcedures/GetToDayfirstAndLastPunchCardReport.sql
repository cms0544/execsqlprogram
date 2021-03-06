IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'GetToDayfirstAndLastPunchCardReport') and xtype='P')  DROP PROCEDURE [dbo].[GetToDayfirstAndLastPunchCardReport]
GO
/****** Object:  StoredProcedure [dbo].[GetToDayfirstAndLastPunchCardReport]    Script Date: 2021/5/24 10:11:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- 2020-03-05
-- 上下班時間報表  --exec GetToDayfirstAndLastPunchCardReport '',0,0,'2021-05-24 00:00:00','2021-05-30 23:59:00',1,0,0,''
-- =============================================
create PROCEDURE [dbo].[GetToDayfirstAndLastPunchCardReport]
    @employee nvarchar(max),
	@rows int,
	@page int ,
	@starttime  nvarchar(20),
	@endtime  nvarchar(20),
	@ismanage int = 0,
	@yzid int = 0,
	@memberid int = 0,
	@searchyzid varchar(max) = '0'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Create table #temp(
	 sys_ID int  PRIMARY KEY not null,
	 sys_Ownername varchar(max) COLLATE Chinese_PRC_CI_AS ,
	 sys_CardNO nvarchar(125) COLLATE Chinese_PRC_CI_AS,
	 sys_UserID nvarchar(125) COLLATE Chinese_PRC_CI_AS,
	 sys_UserName nvarchar(400),
	 sys_date nvarchar(20),
	 sys_first_dateTime datetime,
	 sys_first_area nvarchar(max) COLLATE Chinese_PRC_CI_AS,
	 sys_last_dateTime datetime,
	 sys_last_area nvarchar(max) COLLATE Chinese_PRC_CI_AS
	)
  
   declare @StartDate DATETIME = cast(@starttime as datetime)
   declare @EndDate DATETIME =cast(@endtime as datetime)
   --select @StartDate,@EndDate
   SELECT
   CONVERT (VARCHAR (100),dateadd(day,n.number,@StartDate),23) AS every_time, CONVERT (VARCHAR (100),dateadd(day,n.number,@StartDate),23)+' 04:00:00' as start_every_time
   , CONVERT (VARCHAR (100),dateadd(day,n.number+1,@StartDate),23)+' 04:00:00' as end_every_time,ROW_NUMBER() OVER (ORDER BY n.number DESC) AS RowNum into #every_time
   FROM
   master..spt_values n
   WHERE
   n.type = 'p'
   AND n.number <= DATEDIFF(day, @StartDate, @EndDate);

   create table #CardManagement(
      code nvarchar(125)  COLLATE Chinese_PRC_CI_AS
   )
   --Declare @sqlCardManagement nvarchar(max)='insert #CardManagement select col_CardID  from VI_col_CardManagement where 1=1 '
   Declare @sqlCardManagement nvarchar(max)='insert #CardManagement select code from zh_members where 1=1 '
   if @employee<>'' and @employee is not null
   begin
       set @sqlCardManagement  +=' and code in('+@employee+')'
   end 

   if @searchyzid!='-1' and @searchyzid!='0' and @searchyzid!=''
     begin
	    set @sqlCardManagement  +=' and ownerid in('+@searchyzid+')'
	 end

  
   if (@yzid!=0)
       begin

	         if(@ismanage = '1')
                begin
				      set @sqlCardManagement  +=' 	 and id in (select id from zh_members where ownerid =  '+convert(varchar(max),@yzid)+')'
				end
			 else
				begin	
				     set @sqlCardManagement  +=' 	 and id in (select id from zh_members where id =  '+convert(varchar(max),@memberid)+')'
				end

	   end

   exec(@sqlCardManagement)

   create table #BT_sys_RawDataLogForReader
   (
          sys_ID int,
		  sys_Ownername varchar(max) COLLATE Chinese_PRC_CI_AS ,
		  sys_CardNO varchar(max) COLLATE Chinese_PRC_CI_AS ,
		  sys_DeviceName varchar(max) COLLATE Chinese_PRC_CI_AS ,
		  sys_UserCode varchar(max) COLLATE Chinese_PRC_CI_AS ,
		  sys_EventTime varchar(max) COLLATE Chinese_PRC_CI_AS ,
		  sys_UserName   varchar(max) COLLATE Chinese_PRC_CI_AS
   )



	 insert into #BT_sys_RawDataLogForReader(sys_ID,sys_Ownername,sys_CardNO,sys_DeviceName,sys_UserCode,sys_EventTime,sys_UserName)
	  select sys_ID,isnull(nullif(c.alias,''),c.name),a.sys_CardNO,a.sys_DeviceName,a.sys_UserCode,convert(varchar(max),a.sys_EventTime,120),isnull(b.name,a.sys_UserName)  from BT_sys_RawDataLogForReader as a 
	  left join ZH_Members as b on a.sys_userid = b.id
	  left join ZH_Owner as c on c.ID = b.ownerid
	  where  sys_UserCode in (select code from #CardManagement) and sys_EventTime between @starttime and @endtime 
	



   Declare @every_time_count int =0
   select @every_time_count=count(*)from #every_time
   while @every_time_count>0
   begin
        Declare @startDateTime nvarchar(50),@endDateTime nvarchar(50)
		select top 1  @startDateTime=start_every_time,@endDateTime=end_every_time from #every_time where RowNum=@every_time_count
		set @every_time_count=@every_time_count-1

		insert into #temp(sys_ID,sys_Ownername,sys_CardNO,sys_date,sys_first_dateTime,sys_last_dateTime) 
		select max(sys_ID),max(sys_Ownername),sys_UserCode,CONVERT(varchar(100), min(sys_EventTime), 103) ,cast(min(sys_EventTime) as datetime),cast(max(sys_EventTime)as datetime) from #BT_sys_RawDataLogForReader 
		where sys_EventTime between @startDateTime and @endDateTime and isnull(sys_UserCode,'')!='' group by sys_UserCode
   
   end

   update #temp set sys_first_area=sys_DeviceName from #temp,#BT_sys_RawDataLogForReader
   where  #temp.sys_first_dateTime =#BT_sys_RawDataLogForReader.sys_EventTime and #temp.sys_CardNO=#BT_sys_RawDataLogForReader.sys_UserCode

   
   update #temp set sys_last_area=sys_DeviceName from #temp,#BT_sys_RawDataLogForReader
   where   #temp.sys_last_dateTime =#BT_sys_RawDataLogForReader.sys_EventTime and #temp.sys_CardNO=#BT_sys_RawDataLogForReader.sys_UserCode
  
   update #temp set #temp.sys_UserID=#BT_sys_RawDataLogForReader.sys_UserCode,#temp.sys_UserName=#BT_sys_RawDataLogForReader.sys_UserName from #temp,#BT_sys_RawDataLogForReader
   where #temp.sys_ID=#BT_sys_RawDataLogForReader.sys_ID



   if @rows<>0
   begin
   SELECT TOP (@rows) * FROM 
   (
    SELECT TOP (@page*@rows) ROW_NUMBER() OVER (ORDER BY sys_date DESC) AS RowNum, * FROM #temp 
   ) AS tempTable
   WHERE RowNum BETWEEN (@page-1)*@rows+1 AND @page*@rows
   ORDER BY RowNum
   end
   else
   begin
		SELECT  sys_Ownername as 公司名 ,sys_CardNO  as 卡號,sys_UserID as [員工編號], sys_UserName as [員工名稱],sys_first_dateTime as [第一次打卡時間],sys_first_area as [第一次打卡位置], sys_last_dateTime as  [最後一次打卡時間],sys_last_area as [最後一次打卡位置]
		 from #temp
   end

   select count(*) from #temp
   drop table #temp
   drop table #every_time
   drop table #BT_sys_RawDataLogForReader
   drop table #CardManagement
END


