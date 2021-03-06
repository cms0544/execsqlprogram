if(exists(select 1 from sysobjects where id = object_id('sp_SignScreennewData')))
   begin
        drop PROCEDURE [dbo].[sp_SignScreennewData] 
   end
/****** Object:  StoredProcedure [dbo].[sp_SignScreennewData]    Script Date: 6/17/2021 1:37:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-01-25,,   sp_SignScreennewData>
-- Description:	<看板,,>
-- =============================================
create PROCEDURE [dbo].[sp_SignScreennewData] 
		@lotid int = 0

AS
BEGIN
	 if(@lotid = 0)
	    begin
		   select top 1 @lotid =lotid from tb_lot order by lotid

		end
	create table  #tempdata
	(
	   title varchar(max) collate Chinese_PRC_CI_AS,
	   imgsrc varchar(max)  collate Chinese_PRC_CI_AS,
	   vacantlots decimal(18,2) ,
	   occupancyrate decimal(18,2),
	   estimatedarrivals decimal(18,2),

	   parkedvehiclescurrent decimal(18,2),
	   parkedvehiclestoday int,

	   parkedvehiclesmembercurrent int,
	   parkedvehiclesemployeecurrent int,
	   parkedvehiclesguestcurrent int,

	   parkedvehiclesmembertoday int,
	   parkedvehiclesemployeetoday int,
	   parkedvehiclesguesttoday int,


	   parkedvehiclescarscurrent int,
	   parkedvehiclesbusescurrent int,
	   parkedvehiclesspvscurrent int,

	
	   parkedvehiclescarstoday int,
	   parkedvehiclesbusestoday int,
	   parkedvehiclesspvstoday int,

	   exitedvehicles int,
	   exitedvehiclesmember int,
	   exitedvehiclesemployee int,
	   exitedvehiclesguest int,
	   exitedvehiclescars int,
	   exitedvehiclesbuses int,
	   exitedvehiclesspvs int,
	   collectedparkingfees decimal(18,2),
	   whitelistedvehiclesmember int,
	   whitelistedvehiclesemployee int,
	   whitelistedvehiclesguest int,
	   abnormalevents int,
	   devicestatus varchar(max) COLLATE Chinese_PRC_CI_AS ,
	   flowhoststatus varchar(max) COLLATE Chinese_PRC_CI_AS ,
	   feestatus int,
	   ledstatus varchar(max)  COLLATE Chinese_PRC_CI_AS,
	   retrogradeabnormalevents int,
	   iostatus  varchar(max)  COLLATE Chinese_PRC_CI_AS,
	   otherstatus  varchar(max)  COLLATE Chinese_PRC_CI_AS
	)
	/*镜头状态*/
	declare @deviceststus varchar(max) = '';
	SELECT @deviceststus =  STUFF((SELECT ','+case when devicename like '%防%' then 'Re' when devicename like '%出%' then 'O' when devicename like '%右%' then 'R' when devicename like '%左%' then 'L' end+';'+convert(varchar(max),iif(DATEDIFF(MINUTE,updatestatusTime,getdate())>2 or isnull(updatestatusTime,'')='',0,1) ) FROM tb_deviceuser with(nolock) where isDelete = 0  for xml path('')),1,1,'') 
	
	 	/*客流状态*/
	declare @flowhoststatus varchar(max) = '';
	select @flowhoststatus = STUFF((SELECT ','+case when [HostName] like '%左%' then 'L' when [HostName] like '%右%' then 'R' END
	+';'+ convert(varchar(max),iif(DATEDIFF(MINUTE,OnlineStateUpdatedTime,getdate())>1 or isnull(OnlineStateUpdatedTime,'')='',0,1) )
	 FROM [BT_PMS].[dbo].[BT_FlowHostDevice] Device with(nolock)
	 LEFT join [dbo].[BT_FlowHostDevice_State]  DeviceState with(nolock) on Device.[FlowHostDeviceID]=DeviceState.[FlowHostDeviceID]
	 for xml path('')),1,1,'') 

	declare @LedStatus varchar(max) = '';
 	select  @LedStatus =STUFF((SELECT ','+case when b.DeviceName like '%左%' then 'L' when b.DeviceName like '%右%' then 'R' when b.DeviceName like '%出%' then 'O' end +';'+convert(varchar(max),iif(DATEDIFF(MINUTE,a.LastamendTime,getdate())>2 or isnull(a.LastamendTime,'')='',0,1) )  
	FROM tb_DeviceDisplay as a with(nolock)  
	left join tb_DeviceUser  as b with(nolock)  on b.DeviceID = a.DeviceID  for xml path('')),1,1,'') 

	declare @iostatus   varchar(max) = '';
	select @iostatus =  STUFF((
	
	 SELECT 
	 ','+ 
	 case when  a.type = 1 then 'GATE'
	 when a.type = 2 then 'IT' end + ';'+

	case when b.devicename like '%防%' then 'Re' when b.devicename like '%出%' then 'O' when b.devicename like '%右%' then 'R' when b.devicename like '%左%' then 'L' end +';'
	+convert(varchar(max),iif(DATEDIFF(MINUTE,a.LastamendTime,getdate())>2 or isnull(a.LastamendTime,'')='',0,1) )


	 from tb_IODeviceStatus as a  with(nolock)
	 left join tb_DeviceUser as b  with(nolock) on a.deviceid = b.DeviceID

	  for xml path('')),1,1,'') 


	 	/*车费状态*/
	 -- SELECT tb_FeePavilion.name 

  --        ,cast(case when isnull(OctopusReadersState.FeePavilionID,0)<1 or OctopusReadersState.[OnlineState]!=1 OR DATEDIFF(day,OctopusReadersState.[OnlineStateUpdatedTime],GETDATE())>1 THEN 0 
  --        ELSE 1 
  --         END as bit) as IsOnline--用這個來判斷
		--into #tempFee
		-- FROM [dbo].[tb_FeePavilion] WITH(nolock)
		-- INNER JOIN [dbo].[BT_CarPark_Used_OctopusReaders] OctopusReaders WITH(nolock) ON tb_FeePavilion.ID=OctopusReaders.FeePavilionID 
		-- LEFT JOIN [dbo].[tb_LotPass] WITH(nolock)     ON OctopusReaders.LotPassID=tb_LotPass.ID               
		-- LEFT JOIN [dbo].[BT_CarPark_Used_OctopusReaders_State] OctopusReadersState WITH(nolock) ON OctopusReaders.FeePavilionID=OctopusReadersState.FeePavilionID AND  OctopusReaders.[LotPassID]=OctopusReadersState.[LotPassID]
		-- WHERE (OctopusReaders.[LotPassID]=-1 OR  (OctopusReaders.[LotPassID]>-1 AND OctopusReaders.[LotPassID]=tb_LotPass.ID))
	
		-- declare @feestatus int = 0;
		-- if(not exists(select 1 from #tempFee where IsOnline = 1))
		--    begin
		--	   /*全部为0是离线*/
		--	   set @feestatus = 0
		--	end
		----else if(not exists(select 1 from #tempFee where IsOnline = 0) )
		----    begin
		----	    /*全部为1是正常*/
		----	    set @feestatus = 1
		----	end
		--else 
		--    begin
			     /*废除 换表*/
		declare @feestatus int = 0;
		set @feestatus = 1
			--end

		declare @otherstatus varchar(max) = '';
 		select   @otherstatus=
		STUFF((
		select ','+
		 case when CarParkDeviceType=0  then 'OC'
		  when CarParkDeviceType=1  then 'EFT'
		  when CarParkDeviceType=2  then 'PR' 
		  end
		 +';'+
		case when name like '%防%' then 'Re' when name like '%出%' then 'O' when name like '%右%' then 'R' when name like '%左%' then 'L'  END
		+';'+
		 convert(varchar(max),min(convert(int,IsOnline))) 
	   
	   		FROM V_CarPark_Used_Devcie_State as a with(nolock)  
			group by name,CarParkDeviceType
		 for xml path('')),1,1,'')  




	    declare @totalparkedvehicles int =1,@totalparkedvechiclescars int = 0,@totalparkedvechiclesbuses int = 0,@totalparkedvechiclesspvs int = 0,@perodenddate datetime,@totalexitedvehicles int = 1,@totalexitedvehiclesMembers int = 1,@totalexitedvehiclesEmp int = 1,@totalexitedvehiclesGuests int = 1,@inpeople int = 1,@totalPaidAmount decimal(18,2) =0;

		declare @begindatetime datetime ,@enddatetime datetime;
		select @begindatetime = convert(varchar(10), getdate(), 120)+' 00:00:00';
		set @enddatetime = getdate();


		declare @title varchar(max) = '',@imgsrc varchar(max) = '';

		select @title= title,@imgsrc=imgsrc  from tb_screenSetting


		declare @lotcount int = 0,@occupancyrate decimal(18,2),@totalincurrent varchar(max) ='1',@totalincurrenMember varchar(max) ='1',@totalincurrenEmployee varchar(max) ='1',@totalincurrenGuest varchar(max) ='1',@totalincurrenCars varchar(max) ='1',@totalincurrenBuses varchar(max) ='1',@totalincurrenSPVs varchar(max) ='1',
		@totalparkedvehiclesMembers varchar(max) ='1',@totalparkedvehiclesEmp varchar(max) ='1',@totalparkedvehiclesGuests varchar(max) ='1',@totalexitedvehiclesCars varchar(max) ='1',@totalexitedvehiclesBuses varchar(max) ='1',@totalexitedvehiclesSpvs varchar(max) ='1',
		@LastAmendTime datetime = '2021-01-01',@lotFull int;

		select @lotFull= LotFull,@totalincurrent = LotCount,@lotcount=LotCount,@LastAmendTime = LastAmendTime from tb_lot where lotid = @lotid

		

		--exec sp_GetInParkNum @lotid,@totalincurrent out,null,@enddatetime



		--select @lotcount = @lotcount - @totalincurrent;

		--exec sp_GetInParkNum @lotid,@totalincurrenMember out,null,@enddatetime,'Member'

			

		--exec sp_GetInParkNum @lotid,@totalincurrenEmployee out,null,@enddatetime,'Employee'

		--exec sp_GetInParkNum @lotid,@totalincurrenGuest out,null,@enddatetime,'Guest'

		--exec sp_GetInParkNum @lotid,@totalincurrenCars out,null,@enddatetime,'Cars'

		--exec sp_GetInParkNum @lotid,@totalincurrenBuses out,null,@enddatetime,'Buses'

		--exec sp_GetInParkNum @lotid,@totalincurrenSPVs out,null,@enddatetime,'SPVs'
	

		select @totalincurrenMember = totalincurrenMember,@totalincurrenEmployee = totalincurrenEmployee,@totalincurrenGuest = totalincurrenGuest,@totalincurrenCars = totalincurrenCars,@totalincurrenBuses = totalincurrenBuses,@totalincurrenSPVs = totalincurrenSPVs
		from  bt_lotcount_distribution
		where @lotid = lotid


		
		exec  sp_FlowandfareNum @begindatetime,@enddatetime,@LastAmendTime,@totalparkedvehicles out,@totalparkedvechiclescars out,@totalparkedvechiclesbuses out,@totalparkedvechiclesspvs out,@totalexitedvehicles out,@totalexitedvehiclesMembers out,@totalexitedvehiclesEmp out,@totalexitedvehiclesGuests out,@inpeople out,@totalPaidAmount out,@totalparkedvehiclesMembers out,
		@totalparkedvehiclesEmp out,@totalparkedvehiclesGuests out,@totalexitedvehiclesCars out,@totalexitedvehiclesBuses out,@totalexitedvehiclesSpvs out,
		@totalincurrent out,@totalincurrenMember out,@totalincurrenEmployee out,@totalincurrenGuest out,@totalincurrenCars out,@totalincurrenBuses out,
		@totalincurrenSPVs out,@lotid




		--set @totalincurrent = @totalincurrent+@lotcount;


		 select @occupancyrate =  round((@totalincurrent/ convert(decimal(18,2),@LotFull) )*100,0) 
		select @lotFull = @lotFull - @totalincurrent;
		if(@lotFull<0)
		  begin
		     set @lotFull = 0
		  end


		

		declare @abnormalevents int = 0;

		select @abnormalevents = count(1) from tb_DeviceUserEventInfo_Top where (isnull(ExceptionType,0) >0 ) and (isnull(ExceptionType,0) != 3 ) and time > @begindatetime

		declare @whitelistEdvehiclesMember int = 0,@whitelistEdvehiclesEmp int = 0,@whitelistedVehiclesGuest int = 0;

		select @whitelistEdvehiclesMember = count(1) from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member' and card_endtime>getdate()
			
		
		select @whitelistEdvehiclesEmp = count(1) from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee' and card_endtime>getdate()

	
		select @whitelistedVehiclesGuest = count(1) from tb_CouponWhitelist where Enable = 1 and IsDelete =0  and Expiredate >getdate()
			

			declare @retrogradeabnormalevents int = 0;

		select @retrogradeabnormalevents = count(1) from tb_DeviceUserEventInfo_Top as i where (isnull(ExceptionType,0) = 3 ) and not exists( select 1 from tb_DeviceUserEventInfo_top  with(nolock) where ExceptionType=0  and  DATEDIFF(SS,CreateDate,i.CreateDate)<=3 and  DATEDIFF(SS,CreateDate,i.CreateDate)>=0 )  and time > @begindatetime
		
	insert into #tempdata(
	   title,
	   imgsrc,

	   vacantlots,
	   occupancyrate ,
	   estimatedarrivals ,

	   parkedvehiclescurrent,
	   parkedvehiclestoday ,

	   parkedvehiclesmembercurrent ,
	   parkedvehiclesemployeecurrent ,
	   parkedvehiclesguestcurrent ,

	   parkedvehiclesmembertoday ,
	   parkedvehiclesemployeetoday ,
	   parkedvehiclesguesttoday ,


	   parkedvehiclescarscurrent ,
	   parkedvehiclesbusescurrent ,
	   parkedvehiclesspvscurrent ,

	
	   parkedvehiclescarstoday ,
	   parkedvehiclesbusestoday ,
	   parkedvehiclesspvstoday ,

	   exitedvehicles ,
	   exitedvehiclesmember ,
	   exitedvehiclesemployee ,
	   exitedvehiclesguest ,

	   exitedvehiclescars ,
	   exitedvehiclesbuses ,
	   exitedvehiclesspvs ,

	   collectedparkingfees ,

	   whitelistedvehiclesmember ,
	   whitelistedvehiclesemployee ,
	   whitelistedvehiclesguest ,

	   abnormalevents,
	   devicestatus,
	   flowhoststatus,
	   feestatus,
	   ledstatus,
	   retrogradeabnormalevents,
	   iostatus,
	   otherstatus
	)

	select 
	  @title,
	  @imgsrc,
	   @lotFull,
	   @occupancyrate,
	   @inpeople,

	   @totalincurrent,
	   @totalparkedvehicles,

	  @totalincurrenMember,
	   @totalincurrenEmployee,
	   @totalincurrenGuest,

	   @totalparkedvehiclesMembers,
	   @totalparkedvehiclesEmp,
	   @totalparkedvehiclesGuests,


	   @totalincurrenCars,
	   @totalincurrenBuses,
	   @totalincurrenSPVs,

	
	   @totalparkedvechiclescars ,
	   @totalparkedvechiclesbuses ,
	   @totalparkedvechiclesspvs ,

	   @totalexitedvehicles,

	   @totalexitedvehiclesMembers ,
	   @totalexitedvehiclesEmp ,
	   @totalexitedvehiclesGuests ,

	   @totalexitedvehiclesCars,
	   @totalexitedvehiclesBuses,
	   @totalexitedvehiclesSpvs,

	   @totalPaidAmount,

	   @whitelistEdvehiclesMember ,
	   @whitelistEdvehiclesEmp,
	   @whitelistedVehiclesGuest,

	   @abnormalevents,
	   @deviceststus,
	   @flowhoststatus,
	   @feestatus,
	   @LedStatus,
	   @retrogradeabnormalevents,

	   @iostatus,
	   @otherstatus

	   select * from #tempdata
END
