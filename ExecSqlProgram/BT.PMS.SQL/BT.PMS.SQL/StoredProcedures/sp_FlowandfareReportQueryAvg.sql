if(exists(select 1 from sysobjects where id = object_id('sp_FlowandfareReportQueryAvg')))
   begin
      drop PROCEDURE [dbo].[sp_FlowandfareReportQueryAvg]
   end
/****** Object:  StoredProcedure [dbo].[sp_FlowandfareReportQueryAvg]    Script Date: 7/8/2021 9:57:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-1-26,,>
-- Description:	<Description,,sp_FlowandfareReportQueryAvg '1','2021-02-02',1,1,'dd-MM-yyyy',1>
-- =============================================
create PROCEDURE [dbo].[sp_FlowandfareReportQueryAvg]
   @searchtype varchar(max),
   @selectday varchar(max),
   @isshowpeople int,
   @isshowfee int,
   @dateformat varchar(max),
   @lotid int = 0
AS
BEGIN
	create table #QueryAvg
	(
	    occupancyrate  decimal(18,2),
		parkedvehicles decimal(18,2),
		parkedvechiclescars  decimal(18,2),
		parkedvechiclesbuses  decimal(18,2),
		parkedvechiclesspvs  decimal(18,2),

		exitedvehicles  decimal(18,2),
		exitedvehiclesMembers  decimal(18,2),
		exitedvehiclesEmp  decimal(18,2),
		exitedvehiclesGuests  decimal(18,2),

		arrivals   decimal(18,2),
		collectedfees  decimal(18,2)
	)

	
		   declare @begindate datetime = null,@enddate datetime= null,@dayscount decimal(18,2);

		   set @selectday = convert(varchar(10),@selectday,120)
		   select @begindate = dateadd(month, datediff(month, 0,@selectday), 0)

		   select @enddate =  dateadd(month, datediff(month, 0, dateadd(month, 1, @selectday)), -1);

		   select @dayscount = datediff(day,@begindate,@enddate)+1

		
	      declare  @occupancyrate decimal(18,2) = 0,@totalincurrent decimal(18,2);


			
             select platenumber,time, type,enter as PassType into #temptotal　
			 from　V_DeviceUserEventInfo_top_Golf  with (nolock)
			   where time>=@begindate  and time <= @enddate and lotid = @lotid and autoadd!=2


			  if( datediff(day,@begindate,getdate())>30 )
					 begin
						 insert into #temptotal
						 select platenumber,time,iif(ISNUMERIC(type) = 1,type,0) as  type,enter as PassType 　
						 from　tb_DeviceUserEventInfo_Top_old  as a with (nolock)
						inner join tb_LotPass as c on c.id = a.LotID
						 where  (isnull(a.isMain,0) = 1 or enter !=1 ) and time>=@begindate  and time <= @enddate and c.lotid = @lotid and autoadd !=2
				 end


			  	select distinct platenumber,time,[Type] 
				into #tempinpark
				from #temptotal 
				 where PassType = 1 
	


				  	select distinct platenumber,time,[Type] 
				into #tempoutpark
				from #temptotal 
				 where PassType != 1



	select  @occupancyrate = isnull(avg(occupancyrate),0) from tb_cs_car_current where LotID = @lotid and inserttime >=@begindate and inserttime <@enddate
	  declare @totalparkedvehicles decimal(18,2) =1,@totalparkedvechiclescars decimal(18,2) = 0,@totalparkedvechiclesbuses decimal(18,2) = 0,@totalparkedvechiclesspvs decimal(18,2) = 0,@perodenddate datetime,@totalexitedvehicles decimal(18,2) = 1,@totalexitedvehiclesMembers decimal(18,2) = 1,@totalexitedvehiclesEmp decimal(18,2) = 1,@totalexitedvehiclesGuests decimal(18,2) = 1,@inpeople decimal(18,2) = 1,@totalPaidAmount decimal(18,2) = 1;


			   SELECT  @totalparkedvehicles =   isnull(round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)  from (
					 select 1 as counts from 	#tempinpark

				) as a

				--SELECT  @totalparkedvechiclescars =  REPLACE(CONVERT(VARCHAR(20),CAST(  round(CONVERT(decimal(18,2),count(1)/@dayscount),2) AS MONEY),1),'.00','')  from (
				--	 select 1 from 	#tempinpark where type not in (1,18,2,5,7,8,15,16,17,19,20,21,22)

				--) as a

				SELECT  @totalparkedvechiclesbuses = isnull(round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)  from (
					 select 1 as counts from 	#tempinpark where  type in (1,10)
				) as a

				SELECT  @totalparkedvechiclesspvs =  isnull( round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)   from (
					
					 select 1 as counts from 	#tempinpark where  type in (2,5,7,8,15,16,17,19,20,21,22)
			
				) as a

				--set @totalparkedvechiclescars = @totalparkedvehicles - @totalparkedvechiclesbuses - @totalparkedvechiclesspvs;

				SELECT  @totalparkedvechiclescars = isnull( round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0) from (
					
					 select 1 as counts from 	#tempinpark where  type not in (1,10,2,5,7,8,15,16,17,19,20,21,22)
			
				) as a

				SELECT  @totalexitedvehicles =    isnull(round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)  from (
						 select 1 as counts from 	#tempoutpark
					
				) as a

				 SELECT  @totalexitedvehiclesMembers = isnull( round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)   from (
						select 1 as counts from #tempoutpark
						 where PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member')
				) as a

				 SELECT  @totalexitedvehiclesEmp =    isnull(round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)  from (
				     	select 1 as counts from #tempoutpark
						 where PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee')
				) as a


				select @totalexitedvehiclesGuests =  isnull( round(CONVERT(decimal(18,2),convert(decimal(18,2),count(1))/@dayscount),2),0)  from (
				     	select 1 as counts from #tempoutpark
						 where PlateNumber not in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 )
				) as a

				-- SELECT  @totalexitedvehiclesGuests =  REPLACE(CONVERT(VARCHAR(20),CAST(  round(CONVERT(decimal(10,2),count(1)/@dayscount),2) AS MONEY),1),'.00','')  from (
				--		select distinct platenumber,time from 
				--		tb_DeviceUser as a
				--		inner join tb_LotPass as c on c.id = a.LotID
				--		inner join tb_lot as lot on lot.LotID = c.LotID
				--		inner join tb_DeviceUserEventInfo_top as b on  b.lotid = c.id 

				--		 where time>=@begindate and time <=@enddate and c.PassType = 3 
				--		 --and PlateNumber !='unknown' 
				--		  and a.isMain = 1 and lot.LotID = @lotid 
				--			and PlateNumber not in ( select car_code from vi_car where isnull(card_status,0) = 0)

				--		select * from #tempoutpark
				--		 where PlateNumber in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工')
					 
				--) as a

				
				 select  @inpeople =  isnull(round(CONVERT(decimal(18,2),convert(decimal(18,2),sum(incount))/@dayscount,2) ,2),0) from [dbo].[BT_FlowData] where StartTime>=@begindate and endtime <=@enddate

				 select  @totalPaidAmount =isnull(  round(CONVERT(decimal(18,2),convert(decimal(18,2),sum(PaidAmount))/@dayscount,2) ,2),0)  from tb_Transaction where [TransactionTime] between @begindate and @enddate


	insert into #QueryAvg( occupancyrate,
		parkedvehicles,
		parkedvechiclescars,
		parkedvechiclesbuses,
		parkedvechiclesspvs,

		exitedvehicles,
		exitedvehiclesMembers,
		exitedvehiclesEmp,
		exitedvehiclesGuests,

		arrivals ,
		collectedfees )
	select @occupancyrate,
	@totalparkedvehicles,
	@totalparkedvechiclescars,
	@totalparkedvechiclesbuses,
	@totalparkedvechiclesspvs,
	@totalexitedvehicles,
	@totalexitedvehiclesMembers,
	@totalexitedvehiclesEmp,
	@totalexitedvehiclesGuests,
	@inpeople,
	@totalPaidAmount


	select * from #QueryAvg


END














