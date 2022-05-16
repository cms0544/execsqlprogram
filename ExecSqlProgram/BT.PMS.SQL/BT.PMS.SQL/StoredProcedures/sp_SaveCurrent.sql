if(exists(select 1 from sysobjects where id = object_id('sp_SaveCurrent')))
   begin
      drop PROCEDURE [dbo].[sp_SaveCurrent]
   end
/****** Object:  StoredProcedure [dbo].[sp_SaveCurrent]    Script Date: 6/4/2021 5:25:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Mason>
-- Create date: <2021-02-20,,>
-- Description:	<保存在場車輛,, sp_SaveCurrent 'MA3383@@私家車 Car;;TH4234@@私家車 Car;;XD3160@@私家車 Car',1,'admin','2021-03-03 04:30'>
-- =============================================
create PROCEDURE [dbo].[sp_SaveCurrent]
	@saveStr varchar(max),
	@LotID int,
	@upuser varchar(max),
	@time datetime = ''
AS
BEGIN
	if(@time = '' )
	   begin

	      set @time = getdate();
	   end

	truncate table tb_RealCurrentPark
	if(charindex('@@',@saveStr)!=0)
	   begin
			insert into tb_RealCurrentPark(lotid,platenumber,type,updatetime,upuser)
			select @lotid,dbo.[GetSplitOfIndex](col,'@@',1) as platenumber,dbo.[GetSplitOfIndex](col,'@@',2)  as type,getdate(),@upuser
			from fn_split(@saveStr,';;')
	 end

	declare @count int = 0,@totalincurrenMember int  = 0 ,@totalincurrenEmployee int = 0,@totalincurrenGuest int = 0,@totalincurrenCars int = 0,@totalincurrenBuses int = 0,@totalincurrenSPVs int = 0,@totalincurrent int = 0;
	

	select @count = count(1) from tb_RealCurrentPark

	select @totalincurrenMember = count(1) from tb_RealCurrentPark where platenumber  in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '會員 Member'  and card_endtime>getdate())

	select @totalincurrenEmployee = count(1) from tb_RealCurrentPark where platenumber  in ( select car_code from vi_car_vip where isnull(card_status,0) = 0 and isnull(card_name,'')= '員工 Employee'  and card_endtime>getdate())

	select @totalincurrenGuest = @count - @totalincurrenMember - @totalincurrenEmployee;

	select @totalincurrenCars = count(1) from tb_RealCurrentPark where type='私家車 Car'

	select @totalincurrenBuses = count(1) from tb_RealCurrentPark where type='巴士 Bus'

	select @totalincurrenSPVs = count(1) from tb_RealCurrentPark where type='其它 Others'


	update tb_lot set LotCount = @count,LastAmendTime = @time,LastAmendUser = @upuser where lotid = @LotID


	update bt_lotcount_distribution set totalincurrent = @count,totalincurrenMember = @totalincurrenMember,totalincurrenEmployee= @totalincurrenEmployee,totalincurrenGuest= @totalincurrenGuest,
	totalincurrenCars = @totalincurrenCars,totalincurrenBuses= @totalincurrenBuses,totalincurrenSPVs= @totalincurrenSPVs where lotid = @LotID



	 
	select * into #tb_DeviceUserEventInfo_top　from　V_DeviceUserEventInfo_top_Golf  where time < = @time


	 select LotID,platenumber,time,type
	 into #tempin_top
	 from (
	 select LotID,time, PlateNumber,type, ROW_NUMBER() over(partition by PlateNumber order by Time desc) num,enter from V_DeviceUserEventInfo_top_Golf with(nolock)
	 where lotid = @lotid 
	  --where PlateNumber<>'unknown'
	  ) t
	  where t.num=1 and enter = 1 --最后一条记录


	declare @outdeviceid int=0,@outlotid int;
	select  top 1 @outdeviceid = DeviceID,@outlotid = lotid from tb_Deviceuser where enter = 3 and isnull(isDelete,0) = 0 and isnull(isMain,0) = 1
		 declare @intdeviceid int=0,@inlotid int;
	select  top 1 @intdeviceid = DeviceID,@inlotid = lotid from tb_Deviceuser where enter =1 and isnull(isDelete,0) = 0 and isnull(isMain,0) = 1


	/*不在範圍內的出場*/
	 INSERT INTO tb_DeviceUserEventInfo_Top  ([DeviceID],[ID],[Time],[Type],[GroupID],[Index],[Count],[PlateNumber],[PlateType],[PlateColor],[VehicleType],[VehicleColor],[VehicleSize],[LaneNumber],[Address],[AttachImageUrl],[PicImageUrl],[Guid],[Enter],[LotID],[CreateDate],[AutoAdd],[OpenDoor])
	 select @outdeviceid,0,dateadd(mi,-10,@time),'',0,0,1,PlateNumber,'Unknown','Unknow','','','',1,'','','',newid(),3,@outlotid,getdate(),2,1
	 from  #tempin_top
	 where PlateNumber not in (
	 
	     select PlateNumber from  tb_RealCurrentPark
	 )


	/*在範圍內的入場*/
	 INSERT INTO tb_DeviceUserEventInfo_Top([DeviceID],[ID],[Time],[Type],[GroupID],[Index],[Count],[PlateNumber],[PlateType],[PlateColor],[VehicleType],[VehicleColor],[VehicleSize],[LaneNumber],[Address],[AttachImageUrl],[PicImageUrl],[Guid],[Enter],[LotID],[CreateDate],[AutoAdd],[OpenDoor],[isMain])
	 select @intdeviceid,0,dateadd(mi,-10,@time),'',0,0,1,PlateNumber,'Unknown','Unknow','','','',1,'','','',newid(),1,@inlotid,getdate(),1,2,1
	 from  tb_RealCurrentPark
	 where PlateNumber not in (
	 
	     select PlateNumber from #tempin_top  
	 )



	select * into #tb_DeviceUserEventInfo　from　tb_DeviceUserEventInfo  where (isnull(isMain,0) = 1 or enter !=1 )  and time < = @time

			  
	       
	select LotID,platenumber,time,type
	 into #tempin
	 from (
	 select LotID,time, PlateNumber,type, ROW_NUMBER() over(partition by PlateNumber order by Time desc) num,enter from #tb_DeviceUserEventInfo with(nolock)
	 where lotid = @lotid 
	  --where PlateNumber<>'unknown'
	  ) t
	  where t.num=1 and enter = 1 --最后一条记录



	/*不在範圍內的出場*/
	 INSERT INTO tb_DeviceUserEventInfo  ([DeviceID],[ID],[Time],[Type],[GroupID],[Index],[Count],[PlateNumber],[PlateType],[PlateColor],[VehicleType],[VehicleColor],[VehicleSize],[LaneNumber],[Address],[AttachImageUrl],[PicImageUrl],[Guid],[Enter],[LotID],[CreateDate],[AutoAdd],[OpenDoor])
	 select @outdeviceid,0,dateadd(mi,-10,@time),'',0,0,1,PlateNumber,'Unknown','Unknow','','','',1,'','','',newid(),3,@outlotid,getdate(),2,1
	 from  #tempin
	 where PlateNumber not in (
	 
	     select PlateNumber from  tb_RealCurrentPark
	 )


	/*在範圍內的入場*/
	 INSERT INTO tb_DeviceUserEventInfo([DeviceID],[ID],[Time],[Type],[GroupID],[Index],[Count],[PlateNumber],[PlateType],[PlateColor],[VehicleType],[VehicleColor],[VehicleSize],[LaneNumber],[Address],[AttachImageUrl],[PicImageUrl],[Guid],[Enter],[LotID],[CreateDate],[AutoAdd],[OpenDoor],[isMain])
	 select @intdeviceid,0,dateadd(mi,-10,@time),'',0,0,1,PlateNumber,'Unknown','Unknow','','','',1,'','','',newid(),1,@inlotid,getdate(),1,2,1
	 from  tb_RealCurrentPark
	 where PlateNumber not in (
	 
	     select PlateNumber from #tempin  
	 )






	select '保存成功'
END
