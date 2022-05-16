--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'IntoRawDataLogForReaderForSoyal') and xtype='P')  DROP PROCEDURE [dbo].[IntoRawDataLogForReaderForSoyal]
GO
/****** Object:  StoredProcedure [dbo].[IntoRawDataLogForReaderForSoyal]    Script Date: 03/04/2021 16:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2021-03-04>
-- Description:	<保存打卡記錄>
--EXEC IntoRawDataLogForReaderForSoyal '000001000000',24,'2216214793','2021-03-30 10:31:31','1','1','true','1','101',11,1,0,'2021-03-30 10:20'
-- =============================================
CREATE PROCEDURE [dbo].[IntoRawDataLogForReaderForSoyal] 
(
	@ReaderLOGO nvarchar(16),
	@UserAddress int,
	@CardNO nvarchar(32),
	@EventTime datetime,
	@Controller nvarchar(16),
	@Reader nvarchar(16),
	@Valid bit,
	@DoorNo nvarchar(16),
	@AreaNO nvarchar(16),
	@EventType int,
	@isTAData int,
	@dwWorkcode int,
	@GetDataTime nvarchar(19)
)
AS
BEGIN
	SET NOCOUNT ON;
	if @EventType=17--發生警報
		begin
			select 1
			return
		end
	
	Declare @AreadNum int
	SET @AreadNum=@AreaNO
	select top 1  @AreadNum=AreaID from t_Soyal_Area WITH(NOLOCK) where AreaID=@AreaNO
	--set @AreadNum=1--有設備之後去掉
	if @AreadNum is null
		begin
			select 0
			return
		end

	if substring(@ReaderLOGO,1,1)<>'S'
		begin
			set @ReaderLOGO='S' + right('00' + convert(varchar,@AreadNum),3) + @ReaderLOGO
		end

	Declare @UserID int,@UserCode nvarchar(64),@UserName nvarchar(125),@UserType int,@UserTemp nvarchar(16),@IsOverTemp int,@SecondHostID int,@SecondEventTime datetime,@IsOpenDoor int,@OpenDoorTime datetime,@PicDataUrl nvarchar(max),@tmpCardID nvarchar(125),@tmpUserAddress int,@tempCount int,@CardType int,@IfHadFace int,@ifNeedMatchTemperature int--samlau 20210519
	--Declare @GetDataTime datetime
	--set @GetDataTime=GetDate()
	Declare @DeviceID int,@Readername nvarchar(125),@AreaID int,@BuildingID int,@IsCardMachine int,@HasQRCode bit,@IsOctDevice bit,@DoorID int,@InOutType int,@IsFirst int,@NeedTemperature int--samlau 20210304
	set @DeviceID=0
	set @Readername='' 
	set @AreaID=0
	set @BuildingID=0
	set @HasQRCode=0
	set @IsCardMachine=0
	set @IsOctDevice=0
	set @DoorID=1--samlau 20210304
	set @InOutType=1--samlau 20210304
	set @IsFirst=1--samlau 20210304
	set @UserTemp='0'--samlau 20210519
	set @IsOverTemp=0--samlau 20210519
	set @SecondHostID=0--samlau 20210519
	set @IsOpenDoor=0--samlau 20210304
	set @NeedTemperature=0--samlau 20210519
	set @ifNeedMatchTemperature=0--samlau 20210519
	set @PicDataUrl=''--samlau 20210519

	select @DeviceID=HostDeviceID,@Readername=HostName,@AreaID=xq_id,@BuildingID=ly_id,@IsCardMachine=IsCardMachine,@HasQRCode=HasQRCode,@IsOctDevice=IsOctDevice,@DoorID=DoorID,@InOutType=InOutType,@NeedTemperature=NeedTemperature from V_HostDevice where ReaderLOGO=@ReaderLOGO--samlau 20210304 
    if @DeviceID=0
        begin
            set @ReaderLOGO=substring(@ReaderLOGO,1,10)+'000000'
			select @DeviceID=HostDeviceID,@Readername=HostName,@AreaID=xq_id,@BuildingID=ly_id,@IsCardMachine=IsCardMachine,@HasQRCode=HasQRCode,@IsOctDevice=IsOctDevice,@DoorID=DoorID,@InOutType=InOutType,@NeedTemperature=NeedTemperature from V_HostDevice where ReaderLOGO=@ReaderLOGO--samlau 20210304
        end

	if @IsCardMachine=1 --samlau 20210519
		begin
			Delete From BT_sys_FreeCard where sys_CardNO=@CardNO
			insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime)
			values(@CardNO,@EventTime,@DeviceID,GetDate())
		end

	Declare @IsQRCode int--samlau 20210304
	set @IsQRCode=0--samlau 20210304
	set @UserID=0
	set @UserCode=''
	set @UserName=NULL
	set @UserType=0--samlau 20210304 
	set @tmpUserAddress=@UserAddress 
		 
	if @CardNO='0000000000' or @CardNO='' or @CardNO='0' or @CardNO is null or replace(@CardNO,'0','')=''--samlau 20160715
		begin
			set @CardNO=''
			if @UserAddress=0-- samlau 20160715
				begin
					select 0
					return
				end

			select @UserID=col_UserID from BT_col_UserIDAndAddress WITH(NOLOCK) where col_UserAddress=@UserAddress			
			if @UserID>0 
				begin
					select @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserID=@UserID and col_UserAddress=@UserAddress--samlau 20210304  
				end

			if @UserID=0 
				begin
					select @tempCount=count(1) from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress
					if @tempCount=1
						begin
							select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress
						end
				end

			if @UserID=0 
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress and col_Status=1 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime order by col_UserID desc
				end
			if @UserID=0 
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress and col_DateStart<=@EventTime and col_DateEnd>=@EventTime order by col_UserID desc
				end
			if @UserID=0 
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress and col_Status=1 and col_DateStart<=@EventTime order by col_DateEnd desc,col_UserID desc  
				end
			if @UserID=0 
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress and col_DateStart<=@EventTime order by col_DateEnd desc,col_UserID desc 
				end
			if @UserID=0 
				begin
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=@UserAddress order by col_DateStart,col_DateEnd,col_UserID desc 
				end
						 
		end
	else
		begin
			select @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=col_UserAddress,@UserType=col_UserType,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@CardNO--samlau 20210304  
			--if @UserID=0 and len(@CardNO)<10
			--	begin
			--		set @tmpCardID=right(('0000000000' + @CardNO),10)
			--		select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=col_UserAddress,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@@tmpCardID 
			--	end
			if @UserID=0  
				begin
					set @tmpCardID=replace(ltrim(replace(@CardNO,'0',' ')),' ','0') 
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=col_UserAddress,@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@tmpCardID 
				end

			if @UserID=0  
				begin
					select top 1 @UserID=qrcode_id,@UserCode=visitor,@UserName=visitor,@UserType=1,@CardNO=cardid,@IsQRCode=1,@CardType=11,@IfHadFace=0 from BT_OpenDoor_QRCode WITH(NOLOCK) where cardid=@CardNO 
				end

		 	if @UserAddress=0 or @UserAddress is null or @UserAddress<>@tmpUserAddress
				begin
					set @UserAddress=@tmpUserAddress--@UserID 
				end 
		end

	if @UserName is null
		begin
			set @UserName=''
		end
		 
	if @CardNO is null-- samlau 20151124
		begin
			set @CardNO=''-- samlau 20151124
		end

	if @CardNO='' and @UserID=0 and @UserAddress=0
		begin
			return-- samlau 20151124
		end

	--if @IsCardMachine=1 --samlau 20210519去掉--else if @IsCardMachine=1 and @EventType=2 and @Valid=0
	--	begin
	--		Delete From BT_sys_FreeCard where sys_CardNO=@CardNO
	--		insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime)
	--		values(@CardNO,@EventTime,@DeviceID,GetDate())
	--	end
	--else if @UserID>0-- samlau 20160715
	--	begin
	--		Delete from BT_sys_FreeCard where sys_CardNO=@CardNO
	--	end

	if @UserID>0-- samlau 20160715
		begin
			set @isTAData=1-- samlau 20160715
			if @IsCardMachine=0 and @NeedTemperature=1 and @EventType=19--samlau 20210519
				begin
					set @ifNeedMatchTemperature=1--samlau 20210519
				end
 		end
	else
		begin
			set @isTAData=0-- samlau 20160715
		end

	set @Valid=0
	if @EventType=11--合法卡认证通过
		begin			
			set @Valid=1 
			SET @EventType=1
		end 
	else if @EventType=19--巡邏卡拍卡
		begin			
			set @Valid=1 
			SET @EventType=1
		end 
	else if @EventType=1--進出密碼錯誤
		begin
			Set @EventType=6
		end
	else if @EventType=2--輸入三次密碼錯誤, 鍵盤自動上鎖 30 秒
		begin
			return
		end
	else if @EventType=5--未分配权限
		begin
			Set @EventType=6
		end
	else if @EventType=4 or @EventType=7--无效时段
		begin
			Set @EventType=7
		end
	else if @EventType=6--卡号过期
		begin
			Set @EventType=8
		end
	else if @EventType=8--編輯密碼錯誤
		begin
			return
		end
	else if @EventType=9--脅迫信息(緊急求救)
		begin
			return
		end
	else if @EventType=10--密碼進入
		begin
			return
		end
	else if @EventType=0 or @EventType=3 or @EventType=52--无此卡号
		begin
			Set @EventType=9
		end
	else if @EventType=14--卡機進入警戒模式
		begin
			return
		end
	else if @EventType=15--解除警戒模式
		begin
			return
		end
	else if @EventType=16--按鈕開門
		begin
			return
		end
	else if @EventType=21--反挾持
		begin
			return
		end
	else if @EventType=22--訪客求援(密碼)
		begin
			return
		end
	else if @EventType=23--清潔人員卡
		begin
			return
		end
	else if @EventType=27--緊急按鈕
		begin
			return
		end
	else if @EventType=28--讀卡加密碼進入
		begin
			return
		end
	else if @EventType=39--指紋進入
		begin
			return
		end
	else if @EventType=40--指紋錯誤
		begin
			return
		end
	else
		begin
			return
		end

	if @EventType>11
		begin
			if @EventType<>16 and @EventType<>21 and @EventType<>22 and @EventType<>23 and @EventType<>27 and @EventType<>28 and @EventType<>39 and @EventType<>40 and @EventType<>52
				begin
					return
				end
		end
		 
	Declare @EventTypeMessage as nvarchar(max)
	select @EventTypeMessage=sys_EventType from BT_sys_EventTypeForReader where sys_ID=@EventType
	--if @EventTypeMessage is null
	--	begin
	--		set @EventTypeMessage=@EventMessage
	--	end

	--if @UserID>0 and @Valid='true'
	--	begin
	--		set @IsOpenDoor=1
	--		set @OpenDoorTime=@EventTime
	--	end

	Declare @count as int,@sys_ID as int
	set @count=0
	set @sys_ID=0
	if @CardNO='' and @UserAddress>0
		begin
			select @count=1,@sys_ID=sys_ID from BT_sys_RawDataLogForReader where sys_ReaderID=@DeviceID and sys_EventTime=@EventTime and sys_EventType=@EventType and sys_UserAddress=@UserAddress
		end
	else
		begin
			select @count=1,@sys_ID=sys_ID from BT_sys_RawDataLogForReader where sys_ReaderID=@DeviceID and sys_EventTime=@EventTime and sys_EventType=@EventType and sys_CardNO=@CardNO
		end

	if @count=1
		begin
			return
		end

	Declare @tmpReaderID as int,@tmpsysID bigint--samlau 20210304
	set @tmpsysID=0--samlau 20210304
	if @ifNeedMatchTemperature=1--samlau 20210304 海康測溫記錄匹配Soyal拍卡記錄
		begin
			set @tmpReaderID=0
			select top 1 @tmpReaderID=HostDeviceID from V_HostDeviceForSam where ly_id=@BuildingID and DoorID=@DoorID and HostDeviceID<>@DeviceID and BrandID<>15 and DeviceType='DS-K1T671TM-3XF' order by HostDeviceID--支持測溫的卡機
			--if @tmpReaderID=0
			--	begin
			--		select top 1 @tmpReaderID=HostDeviceID from V_HostDeviceForSam where ly_id=@BuildingID and DoorID=@DoorID and HostDeviceID<>@DeviceID and BrandID<>15 order by HostDeviceID
			--	end

			if @tmpReaderID>0
				begin
					select @tmpsysID=sys_ID,@UserTemp=sys_UserTemp,@IsOverTemp=sys_IsOverTemp,@SecondHostID=sys_ReaderID,@SecondEventTime=sys_EventTime,@PicDataUrl=sys_PicDataUrl from BT_sys_RawDataLogForReader a where sys_ReaderID=@tmpReaderID and sys_EventTime>=dateadd(second,-1,@EventTime) and sys_EventTime<dateadd(second,60,@EventTime) and sys_EventType=999 and sys_UserID=0 and ISNULL(sys_UserTemp,0)>0 and ISNULL(sys_IsOverTemp,0)=0 and sys_IsMatched=0 and sys_EventTime=(select max(sys_EventTime) from BT_sys_RawDataLogForReader where sys_ReaderID=a.sys_ReaderID)
					if @tmpsysID>0
						begin
							-----------要控制开闸启用下面三行-----------
							--Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@tmpReaderID and col_Status<0
							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select @tmpsysID,'OPENDOOR',@UserName,@UserType,@UserAddress,ISNULL(col_FCCellID,'0'),@CardNo,ISNULL(col_CardType,0),N'' + @EventTime + '',N'' + @EventTime + '',ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@DeviceID,-3,0,3,0,'2999-12-31','2999-12-31' from BT_col_UserInfoForReader WHERE col_UserID=@UserID and col_CardID=@CardNO
							-----------要控制开闸启用下面三行-----------

							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select sys_ID,'OPENDOOR',ISNULL(sys_UserName,'OPENDOOR'),ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(col_FCCellID,'0'),sys_CardNO,ISNULL(col_CardType,0),sys_EventTime,sys_EventTime,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@tmpReaderID,-3,0,1,0,'2008-10-01','2008-10-01' from BT_sys_RawDataLogForReader a left join BT_col_UserInfoForReader b on a.sys_UserID=b.col_UserID and a.sys_CardNO=b.col_CardID where sys_ID=@tmpsysID
							update BT_sys_RawDataLogForReader set sys_IsMatched=1 WHERE sys_ID=@tmpsysID 
						end
					else
						begin
							--Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@tmpReaderID and col_Status<0
							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select @tmpsysID,'SETONLYTEMPMODE',@UserName,@UserType,@UserAddress,ISNULL(col_FCCellID,'0'),@CardNo,ISNULL(col_CardType,0),N'' + @EventTime + '',N'' + @EventTime + '',ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@tmpReaderID,-6,0,1,0,'2008-10-01','2008-10-01' from BT_col_UserInfoForReader WHERE col_UserID=@UserID and col_CardID=@CardNO

							set @ifNeedMatchTemperature=0
						end
				end
			else
				begin
					set @ifNeedMatchTemperature=0
				end
		end

	insert into BT_sys_RawDataLogForReader (sys_ReaderID,sys_DeviceName,sys_EventTime,sys_EventType,sys_EventMessage,sys_CardNO,sys_PassWord,sys_CardName,sys_GetDataTime,sys_RoomNumber,sys_UserID,sys_UserCode,sys_UserName,sys_PicDataUrl,sys_QRCode,sys_AttendanceState,sys_CallLiftFloor,sys_Valid,sys_IsTAData,sys_AreaID,sys_BuildingID,sys_UserAddress,sys_UserType,sys_DoorID,sys_InOutType,sys_IsQRCode,sys_UserTemp,sys_IsOverTemp,sys_IsFirst,sys_SecondHostID,sys_SecondEventTime,sys_IsOpenDoor,sys_OpenDoorTime,sys_IsMatched)
	VALUES(@DeviceID,@Readername,N'' + @EventTime + '',@EventType,@EventTypeMessage,@CardNO,'',@UserName,@GetDataTime,'',@UserID,@UserCode,@UserName,@PicDataUrl,'',@InOutType,'',@Valid,@isTAData,@AreaID,@BuildingID,@UserAddress,@UserType,@DoorID,@InOutType,@IsQRCode,@UserTemp,@IsOverTemp,@IsFirst,@SecondHostID,@SecondEventTime,@IsOpenDoor,@OpenDoorTime,1)--samlau 20210304
	if @ifNeedMatchTemperature=1--samlau 20210304
		begin
			Declare @tmpNewsysID bigint
			set @tmpNewsysID=0
			select @tmpNewsysID=sys_ID from BT_sys_RawDataLogForReader where sys_ReaderID=@DeviceID and sys_EventTime=@EventTime and sys_CardNO=@CardNO and sys_UserID=@UserID
			update BT_col_AutoDownloadUserForReader set col_UserID=@tmpNewsysID,col_DownloadLevel=1,col_UpdateTime='2008-10-01',col_CreateTime='2008-10-01' where col_UserID=@tmpsysID and col_UserCode='OPENDOOR' and col_Status=-3 and col_DeviceID=@DeviceID
		end

	if @IsCardMachine=1 --samlau 20210519
		begin
			return
		end

--	Declare @SwipeTime int
--	set @SwipeTime=0
  
	if @UserID>0-- ISNULL(@UserID,'')<>''--if @CardNO is not null -- samlau 20151124
		begin  
			Declare @isOneInOneOut as int
			set @isOneInOneOut=0--启用一进一出限制
			select @isOneInOneOut=1 from BT_SystemParam where ParamName='PMS_EnabledOneInOneOut' and ParamValue=1 
			if @Valid=1--合法卡认证通过
				begin  
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,@DeviceID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader a where col_CardID=@CardNO and ISNULL(col_UserAddress,0)<>@tmpUserAddress--拍卡的卡片用戶位置跟數據庫對不上的就刪掉 

					update BT_col_UserInfoForReader set col_SwipeTime=col_SwipeTime+1 where col_UserID=@UserID and col_CardID=@CardNO  --and col_CreateTime<@EventTime
					update BT_col_UserInfoForReader set col_LastInOutTime=@EventTime,col_LastReaderID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_LastInOutTime is null
					update BT_col_UserInfoForReader set col_LastInOutTime=@EventTime,col_LastReaderID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_LastInOutTime is not null and col_LastInOutTime<@EventTime

					Declare @UpdateTime datetime,@CurrentInOutType int
					select @CurrentInOutType=col_InOutType,@UpdateTime=col_UpdateTime from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserID=@UserID and col_CardID=@CardNO
					if @EventTime>@UpdateTime
						begin
							update BT_col_UserInfoForReader set col_InOutType=@InOutType where col_UserID=@UserID and col_CardID=@CardNO and col_InOutType<>@InOutType and col_UpdateTime<@EventTime
							--update BT_col_UserInfoForReader set col_InOutType=@InOutType where col_UserID<>@UserID and col_CardID=@CardNO and col_DateStart<GETDATE() and col_DateEnd>GetDate() and col_Status=1 and col_SetorClear=1 and col_InOutType<>@InOutType and col_UpdateTime<@EventTime

							--if @InOutType=1
							--	begin
							--		update BT_col_UserInfoForReader set col_InTime=@EventTime,col_InDeviceID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_UpdateTime<@EventTime and (col_OutTime is null or col_OutTime<@EventTime)
							--		update BT_col_UserInfoForReader set col_InTime=@EventTime,col_InDeviceID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_UpdateTime<@EventTime and col_InTime is not null and col_InTime<@EventTime
							--	end
							--else
							--	begin
							--		update BT_col_UserInfoForReader set col_OutTime=@EventTime,col_OutDeviceID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_UpdateTime<@EventTime and (col_OutTime is null or col_OutTime<@EventTime)
							--		update BT_col_UserInfoForReader set col_OutTime=@EventTime,col_OutDeviceID=@DeviceID where col_UserID=@UserID and col_CardID=@CardNO and col_UpdateTime<@EventTime and col_OutTime is not null and col_OutTime<@EventTime
							--	end

							if @isOneInOneOut=1--NFC的进了就删除入闸下载出闸，出了再下载入闸
								begin
									if @InOutType=2
										begin
											Delete From BT_col_AutoDownloadUserForReader where col_UserID=@UserID and col_CardNo=@CardNO and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType<>@InOutType)-- and col_Status=1
											if @CardType>=12
												begin
													Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardNO and ISNULL(col_UserAddress,0)>0 and col_CardType>=12) and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType<>@InOutType)-- and col_Status=1
												end

											if @CardType<11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@GetDataTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=1)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType>12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=1 and brandID=15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType=12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=1 and brandID=15 and IsOctDevice='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType=11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasQRCode='true' and InOutType=1)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end

											if @CardType<12 AND @IfHadFace=1
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,@GetDataTime),dateadd(second,1,@GetDataTime) from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasFace='true' AND brandID<>15 and InOutType=1)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_UserType=0 and a.col_CardType<12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_IfHadFace=1 and a.col_InOutType=2 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end

											if @CardType<11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@GetDataTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType>12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and brandID=15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType=12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and brandID=15 and IsOctDevice='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType=11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @GetDataTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasQRCode='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_InOutType=2 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end

											if @CardType<12 AND @IfHadFace=1
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,@GetDataTime),dateadd(second,1,@GetDataTime) from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasFace='true' AND brandID<>15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_UserType=0 and a.col_CardType<12 and a.col_DateEnd>GetDate() and a.col_Status=1 and a.col_IfHadFace=1 and a.col_InOutType=2 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
													
											Delete From BT_col_AutoDownloadUserForReader where col_UserID=@UserID and col_CardNo=@CardNO and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType=@InOutType) and col_Status=99
											if @CardType>=12
												begin
													Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardNO and ISNULL(col_UserAddress,0)>0 and col_CardType>=12) and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType=@InOutType) and col_Status=99
												end

											if @CardType<11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.HostDeviceID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK),V_HostDeviceForSam as b WITH(NOLOCK) where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.HostDeviceID=@DeviceID and b.HostDeviceID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) AND b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType>12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2 and brandID=15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) AND b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType=12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2 and brandID=15 and IsOctDevice='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) AND b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType=11
												begin
													if @HasQRCode='true' 
														begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.HostDeviceID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK),V_HostDeviceForSam as b WITH(NOLOCK) where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.HostDeviceID=@DeviceID and b.HostDeviceID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
														end
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasQRCode='true' and InOutType=2)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and (a.col_Status=0 or a.col_DateEnd<GetDate()) and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) AND b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord c where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=99 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime and sys_CreateTime=(select max(sys_CreateTime) as sys_CreateTime from BT_sys_UserDownloadRecord where sys_UserID=@UserID and sys_CardNO=@CardNO and sys_ReaderID=c.sys_ReaderID AND sys_IsOK=1)) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
										end
									else if @InOutType=1
										begin
											set @UpdateTime='2008-01-01 '+ convert(nvarchar(8),getdate(),108)
											Delete From BT_col_AutoDownloadUserForReader where col_UserID=@UserID and col_CardNo=@CardNO and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType=@InOutType) 
											if @CardType>=12
												begin
													Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardNO and ISNULL(col_UserAddress,0)>0 and col_CardType>=12) and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and InOutType=@InOutType) 
												end

											if @CardType<11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.HostDeviceID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK),V_HostDeviceForSam as b WITH(NOLOCK) where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and b.HostDeviceID=@DeviceID and b.HostDeviceID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@UpdateTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=@InOutType)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType>12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@UpdateTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=@InOutType and brandID=15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType=12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@UpdateTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=@InOutType and brandID=15 and IsOctDevice='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
											else if @CardType=11 
												begin
													if @HasQRCode='true' 
														begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.HostDeviceID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,'2008-01-01',@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK),V_HostDeviceForSam as b WITH(NOLOCK) where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and b.HostDeviceID=@DeviceID and b.HostDeviceID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
														end
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@UpdateTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasQRCode='true' and InOutType=@InOutType)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and b.sys_ReaderID in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=99)
												end
												
											set @UpdateTime=DATEADD(second,10,@UpdateTime)
											set @GetDataTime=DATEADD(second,10,@GetDataTime)
											update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1,col_UpdateTime=@UpdateTime where col_UserID=@UserID and col_CardNo=@CardNo and col_Status=1 and col_RunCount=0 and col_CreateTime<=GETDATE()
											if @CardType<11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,@UpdateTime,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType<11 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end
											else if @CardType>12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @UpdateTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2 and brandID=15)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end				
											else if @CardType=12
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @UpdateTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and InOutType=2 and brandID=15 and IsOctDevice='true')) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end													
											else if @CardType=11
												begin
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else @UpdateTime end,@GetDataTime from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasQRCode='true' and InOutType=2)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_CardType=11 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end

											if @CardType<12 AND @IfHadFace=1
												begin
													update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1,col_UpdateTime=dateadd(second,1,@UpdateTime) where col_UserID=@UserID and col_CardNo=@CardNo and col_Status=2 and col_RunCount=0 and col_CreateTime<=GETDATE()
													INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
													SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,b.sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,@UpdateTime),dateadd(second,1,@GetDataTime) from BT_col_UserInfoForReader as a WITH(NOLOCK) left join (select sys_UserCode,sys_CardNo,sys_ReaderID from BT_sys_UserReaderAccess WITH(NOLOCK) WHERE sys_CardNO=@CardNO and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) Where IsCardMachine=0 and HasFace='true' AND brandID<>15 and InOutType=2)) as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserID=@UserID and a.col_CardID=@CardNo and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and b.sys_ReaderID not in (select sys_ReaderID from BT_sys_UserDownloadRecord where sys_UserID=a.col_UserID and sys_CardNO=a.col_CardID and sys_SetOrClear=1 and sys_IsOK=1 and sys_CreateTime>a.col_UpdateTime) and b.sys_ReaderID not in (select col_DeviceID from BT_col_AutoDownloadUserForReader where col_UserID=a.col_UserID and col_CardNo=a.col_CardID and col_Status=1)
												end

										end
								end 
						end
				end
			else if @EventType>=6 and @EventType<=9 --刷卡開門失敗 samlau 20200921
				begin
					if @CardType=0 or @CardType>11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and ISNULL(col_UserAddress,0)>0 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime and col_Status=1--samlau 20210304
						end

					if @HasQRCode='true' AND @CardType=11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType=11 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime and col_Status=1--samlau 20210304
						end

					--if @CardType=0 or @CardType>11
					--	begin
					--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and ISNULL(col_UserAddress,0)>0 and col_Status=0 --and col_DateEnd<dateadd(month,-6,getdate())--samlau 20210304
					--	end
					if @HasQRCode='true' AND @CardType=11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType=11 and col_Status=0 --and col_DateEnd<dateadd(month,-6,getdate())--samlau 20210304
						end
				end

		end
	else 
		begin
			if @Valid=1--合法卡认证通过
				begin
					Delete From BT_col_AutoDownloadUserForReader where col_UserID=0 and col_UserAddress=@tmpUserAddress and col_CardNo=@CardNO and col_Status=99
					INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
					SELECT 0,'0','0',0,@tmpUserAddress,'0',@CardNO,12,@EventTime,@EventTime,0,2,0,@DeviceID,99,0,1,0,GETDATE(),GETDATE() 
				end
		end

END
