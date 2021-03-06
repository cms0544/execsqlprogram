IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_FlowandfareReport') and xtype='P') 
 DROP PROCEDURE [dbo].[sp_FlowandfareReport]
GO
/****** Object:  StoredProcedure [dbo].[sp_FlowandfareReport]    Script Date: 2021/5/8 19:12:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-01-25,,>
-- Description:	<流量及車費總報表,,sp_FlowandfareReport 0,'2021-02-08',1,1,'dd-MM-yyyy',1
--sp_FlowandfareReport 1,'2021-02-09',1,1,'dd-MM-yyyy',1
-- =============================================
create PROCEDURE [dbo].[sp_FlowandfareReport]
	-- Add the parameters for the stored procedure here
	@searchtype varchar(max),
	@selectday varchar(max),
	@isshowpeople int,
	@isshowFee int,
	@dateformat varchar(max),
	@lotid int = 0
AS
BEGIN
    declare @totalparkedvehicles  int = 1,@totalparkedvechiclescars int = 1,@totalparkedvechiclesbuses  int = 1,@totalparkedvechiclesspvs  int =  1,@perodenddate datetime,@totalexitedvehicles  int =  1,@totalexitedvehiclesMember  int =  1,@totalexitedvehiclesEmp  int =  1,@totalexitedvehiclesGuests  int =  1,@inpeople  int = 1,@totalPaidAmount decimal(18,2) =1;
	   SET LANGUAGE US_ENGLISH
	if(@searchtype = 0)
	   begin
	   /*按月*/

	       create table #monthdata
		   (
		        [period] varchar(max) COLLATE Chinese_PRC_CS_AS,
				[totalparkedvehicles] int,
			    [totalparkedvechiclescars] int,
				[totalparkedvechiclesbuses] int,
				[totalparkedvechiclesspvs] int,
				[totalexitedvehicles] int,
				[totalexitedvehiclesMembers] int,
				[totalexitedvehiclesEmp] int,
				[totalexitedvehiclesGuests] int,
				[totalarrivals]  int,
				[totalcollectedfees] decimal(18,2)
		   )

		   declare @begindate datetime = null,@enddate datetime= null;

		   set @selectday = convert(varchar(10),@selectday,120)
		   select @begindate = dateadd(month, datediff(month, 0,@selectday), 0)

		   select @enddate =  dateadd(month, datediff(month, 0, dateadd(month, 1, @selectday)), -1);



		  exec  sp_FlowandfareNum @begindate,@enddate,@begindate,@totalparkedvehicles out,@totalparkedvechiclescars out,@totalparkedvechiclesbuses out,@totalparkedvechiclesspvs out,@totalexitedvehicles out,@totalexitedvehiclesMember out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,'-1','-1','-1','-1','-1','-1','-1','-1','-1','-1','-1','-1','-1',@lotid



		     insert into #monthdata(
			  [period],
			   [totalparkedvehicles],
			    [totalparkedvechiclescars] ,
				[totalparkedvechiclesbuses] ,
				[totalparkedvechiclesspvs] ,
				[totalexitedvehicles] ,
				[totalexitedvehiclesMembers] ,
				[totalexitedvehiclesEmp] ,
				[totalexitedvehiclesGuests] ,
				[totalarrivals],
				[totalcollectedfees]
			 
			 )
			 select  [dbo].[dateformatter] (@begindate,'MM-yyyy'),
			 @totalparkedvehicles,
			 @totalparkedvechiclescars,
			 @totalparkedvechiclesbuses,
			 @totalparkedvechiclesspvs,
			 @totalexitedvehicles,
			 @totalexitedvehiclesMember,
			 @totalexitedvehiclesEmp,
			 @totalexitedvehiclesGuests,
			 @inpeople,
			 @totalPaidAmount

		   while(@begindate <= @enddate)
		      begin

				set @totalparkedvehicles = 1;
			    set @totalparkedvechiclescars= 1;
			    set @totalparkedvechiclesbuses= 1;
			    set @totalparkedvechiclesspvs= 1;
			    set @totalexitedvehicles= 1;
			    set @totalexitedvehiclesMember= 1;
			    set @totalexitedvehiclesEmp= 1;
			    set @totalexitedvehiclesGuests= 1;
			    set @inpeople = 1;
			    set @totalPaidAmount= 1;

				 set @perodenddate = dateadd(day,1,@begindate)

			   		 exec  sp_FlowandfareNum @begindate,@perodenddate,@begindate,@totalparkedvehicles out,@totalparkedvechiclescars out,@totalparkedvechiclesbuses out,@totalparkedvechiclesspvs out,@totalexitedvehicles out,@totalexitedvehiclesMember out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,@lotid

					

				  insert into #monthdata(
			  [period],
			   [totalparkedvehicles],
			    [totalparkedvechiclescars] ,
				[totalparkedvechiclesbuses] ,
				[totalparkedvechiclesspvs] ,
				[totalexitedvehicles] ,
				[totalexitedvehiclesMembers] ,
				[totalexitedvehiclesEmp] ,
				[totalexitedvehiclesGuests] ,
				[totalarrivals],
				[totalcollectedfees]
			 
			 )
				 select  
				 [dbo].[dateformatter] (@begindate,'dd-MM-yyyy'),
				 @totalparkedvehicles,
				 @totalparkedvechiclescars,
				 @totalparkedvechiclesbuses,
				 @totalparkedvechiclesspvs,
				 @totalexitedvehicles,
				 @totalexitedvehiclesMember,
				 @totalexitedvehiclesEmp,
				 @totalexitedvehiclesGuests,
				 @inpeople,
				 @totalPaidAmount


			       set @begindate =dateadd(day,1,@begindate);
			  end

			  select * from #monthdata
	   end
	else 
	   begin
	   /*按日*/

	       create table #daydata
		   (
		        [period] varchar(max) COLLATE Chinese_PRC_CS_AS,
				[totalparkedvehicles] int,
			    [totalparkedvechiclesMembers] int,
				[totalparkedvechiclesEmp] int,
				[totalparkedvechiclesGuests] int,
				[totalexitedvehicles] int,
				[totalexitedvehiclesMembers] int,
				[totalexitedvehiclesEmp] int,
				[totalexitedvehiclesGuests] int,
				[averageoccupancyrate] int,
				[totalarrivals]  int,
				[totalcollectedfees] int
		   )


		  declare @begintime datetime = null,@endtime datetime= null;

		     SELECT @begintime = CONVERT(DATETIME,CONVERT(VARCHAR(10),@selectday,120)+' 00:00')

				SELECT @endtime = DATEADD(SS,-1,DATEADD(DD,1,CONVERT(DATETIME,CONVERT(VARCHAR(10),@selectday,120))))

			declare @totalparkedvehiclesmembers int = 1,@totalparkedvehiclesEmp int = 1,@totalparkedvehiclesGuests int = 1
			
			  exec  sp_FlowandfareNum @begintime,@endtime,@begintime,@totalparkedvehicles out,-1,-1,-1,@totalexitedvehicles out,@totalexitedvehiclesMember out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,@totalparkedvehiclesmembers out,@totalparkedvehiclesEmp out ,@totalparkedvehiclesGuests out,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,@lotid


		
		    declare @averageoccupancyrate decimal(18,2);

			select @averageoccupancyrate = isnull(avg(occupancyrate),0) from tb_cs_car_current where LotID = @lotid
			and inserttime >=@begintime and inserttime < @endtime

		     insert into #daydata(
			  [period],
				[totalparkedvehicles],
			    [totalparkedvechiclesMembers],
				[totalparkedvechiclesEmp],
				[totalparkedvechiclesGuests],
				[totalexitedvehicles],
				[totalexitedvehiclesMembers] ,
				[totalexitedvehiclesEmp],
				[totalexitedvehiclesGuests],
				[averageoccupancyrate],
				[totalarrivals],
				[totalcollectedfees] 
			 
			 )
			 select  [dbo].[dateformatter] (@begintime,'dd-MM-yyyy'),
			        @totalparkedvehicles,
					@totalparkedvehiclesmembers,
					@totalparkedvehiclesEmp,
					@totalparkedvehiclesGuests,
					@totalexitedvehicles,
					@totalexitedvehiclesMember,
					@totalexitedvehiclesEmp,
					@totalexitedvehiclesGuests,
					@averageoccupancyrate,
					@inpeople,
					@totalPaidAmount


			   SELECT @begintime = convert(datetime,convert(varchar(10),@selectday,120)+' 00:00')

			   select @endtime = convert(datetime,convert(varchar(10),@selectday,120)+' 06:00')


		  exec  sp_FlowandfareNum @begintime,@endtime,@begintime,@totalparkedvehicles out,-1,-1,-1,@totalexitedvehicles out,@totalexitedvehiclesMember out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,@totalparkedvehiclesmembers out,@totalparkedvehiclesEmp out ,@totalparkedvehiclesGuests out,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,@lotid


			--declare @totalincurrent int ;

			--exec sp_GetInParkNum @lotid,@totalincurrent out,@begintime,@endtime

					--select @averageoccupancyrate = @totalincurrent /LotFull from tb_lot where LotID = @lotid

			select @averageoccupancyrate = isnull(avg(occupancyrate),0) from tb_cs_car_current where LotID = @lotid
			and inserttime >=@begintime and inserttime < @endtime


			   insert into #daydata(
			  [period],
				[totalparkedvehicles],
			    [totalparkedvechiclesMembers],
				[totalparkedvechiclesEmp],
				[totalparkedvechiclesGuests],
				[totalexitedvehicles],
				[totalexitedvehiclesMembers] ,
				[totalexitedvehiclesEmp],
				[totalexitedvehiclesGuests],
				[averageoccupancyrate],
				[totalarrivals],
				[totalcollectedfees] 
			 
			 )
			 select   '0000~0559',
			   @totalparkedvehicles,
					@totalparkedvehiclesmembers,
					@totalparkedvehiclesEmp,
					@totalparkedvehiclesGuests,					
					@totalexitedvehicles,
					@totalexitedvehiclesMember,
					@totalexitedvehiclesEmp,
					@totalexitedvehiclesGuests,
					@averageoccupancyrate,
					@inpeople,@totalPaidAmount

				  SELECT @begintime = convert(datetime,convert(varchar(10),@selectday,120)+' 06:00')

				SELECT @endtime = DATEADD(SS,-1,DATEADD(DD,1,CONVERT(DATETIME,CONVERT(VARCHAR(10),@selectday,120))))

		   while(@begintime <= @endtime)
		      begin
			  --set @totalincurrent = 1
			   declare @periodendtime datetime= dateadd(hour,1,@begintime);
			 
		       		 
				  exec  sp_FlowandfareNum @begintime,@periodendtime,@begintime,@totalparkedvehicles out,-1,-1,-1,@totalexitedvehicles out,@totalexitedvehiclesMember out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,@totalparkedvehiclesmembers out,@totalparkedvehiclesEmp out ,@totalparkedvehiclesGuests out,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,@lotid

				--exec sp_GetInParkNum @lotid,@totalincurrent out,@begintime,@periodendtime
			


					--select @averageoccupancyrate = @totalincurrent /LotFull from tb_lot where LotID = @lotid

					select @averageoccupancyrate =  isnull(avg(occupancyrate),0) from tb_cs_car_current where LotID = @lotid
			and inserttime >=@begintime and inserttime < @periodendtime
				

		
				insert into #daydata(
			    [period],
				[totalparkedvehicles],
			    [totalparkedvechiclesMembers],
				[totalparkedvechiclesEmp],
				[totalparkedvechiclesGuests],
				[totalexitedvehicles],
				[totalexitedvehiclesMembers] ,
				[totalexitedvehiclesEmp],
				[totalexitedvehiclesGuests],
				[averageoccupancyrate],
				[totalarrivals],
				[totalcollectedfees] 
			 
			 )
			 select  [dbo].[dateformatter](@begintime,'HHmm')+'~'+[dbo].[dateformatter](@begintime,'HH59'),  @totalparkedvehicles,
					@totalparkedvehiclesmembers,
					@totalparkedvehiclesEmp,
					@totalparkedvehiclesGuests,
				
					@totalexitedvehicles,
					@totalexitedvehiclesMember,
					@totalexitedvehiclesEmp,
					@totalexitedvehiclesGuests,
					@averageoccupancyrate,
					@inpeople,@totalPaidAmount

			       set @begintime =dateadd(hour,1,@begintime);
			  end

			  select * from #daydata


	   end
END


