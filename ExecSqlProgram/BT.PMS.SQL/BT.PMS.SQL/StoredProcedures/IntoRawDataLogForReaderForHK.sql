--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'IntoRawDataLogForReaderForHK') and xtype='P')  DROP PROCEDURE [dbo].[IntoRawDataLogForReaderForHK]
GO
/****** Object:  StoredProcedure [dbo].[IntoRawDataLogForReaderForHK]    Script Date: 03/04/2021 16:23:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2021-03-04>
-- Description:	<保存打卡記錄>
--Exec IntoRawDataLogForReaderForHK '30','192.168.90.165',2,'刷卡開鎖成功; Temperature: 37.6;OverTemp:True','','2263200324','','吳先生','2021-03-10 10:22:23','','',0,'0','',1
-- =============================================
CREATE PROCEDURE [dbo].[IntoRawDataLogForReaderForHK] 
(
	@ReaderID nvarchar(100),
	@IPaddr nvarchar(50), 
	@EventType int,
	@EventMessage nvarchar(max), 
	@EmployeeNo nvarchar(16),-- samlau 20210125 新卡機工號前面有0
	@CardNO nvarchar(125), --samlau 20161230 超級密碼18446744073709551613;胁迫密碼18446744073709551614 
	@PassWord nvarchar(125),
	@CardName nvarchar(125),
	@EventTime datetime,
	@PicDataUrl nvarchar(max),
	@QRCode nvarchar(max),
	@AttendanceState int,
	@RoomNumber nvarchar(64),
	@CallLiftFloor nvarchar(16),
	@Valid bit,
	@UserTemp as nvarchar(16)='',
	@IsOverTemp int=0,
	@DoorNo int=1--samlau 20210414 控制器對應的門ID
	--@GetDataTime datetime
)
AS
BEGIN
	SET NOCOUNT ON;
	Declare @UserID int,@UserCode nvarchar(64),@UserName nvarchar(125),@UserAddress nvarchar(16),@UserType int,@IsOpenDoor int,@OpenDoorTime datetime,@tmpCardID nvarchar(125),@IsMatched int,@CardType int,@IfHadFace int--samlau 20210304
	Declare @GetDataTime datetime
	set @GetDataTime=GetDate()   
 
	if @UserTemp=''--samlau 20210304
		begin
			Declare @Temperature as nvarchar(max),@OverTemp nvarchar(16),@Remark nvarchar(max)--samlau 20200507 温度
			set @OverTemp=''-- 是否超溫
			set @Remark=''--samlau 20200507
			if CHARINDEX('Temperature',@EventMessage)>0--samlau 20201208
				begin 
					set @Temperature=SubString(@EventMessage,CHARINDEX('Temperature: ',@EventMessage)+13,len(@EventMessage)-CHARINDEX('Temperature: ',@EventMessage)-12)
					set @EventMessage=SubString(@EventMessage,0,CHARINDEX('Temperature: ',@EventMessage))
					if CHARINDEX(';',@EventMessage)=len(@EventMessage)
						begin
							set @EventMessage=SubString(@EventMessage,0,len(@EventMessage))
						end

					if CHARINDEX(';OverTemp:True',@Temperature)>0
						begin
							set @OverTemp='1'
							set @Temperature=replace(@Temperature,';OverTemp:True','')
						end
					else if CHARINDEX(';OverTemp:False',@Temperature)>0
						begin
							set @OverTemp='0'
							set @Temperature=replace(@Temperature,';OverTemp:False','')
						end

					if CHARINDEX(';',@Temperature)>0
						begin
							set @Temperature=SubString(@Temperature,0,CHARINDEX(';',@Temperature))
						end

					if @Temperature=''
						begin
							set @Temperature='0'
						end

					if @OverTemp=''
						begin
							set @OverTemp='0'
						end

					--if @OverTemp='0' and exists(select 1 from CustomerFunctionSetting WHERE FunctionName='AlarmTemperature' and value is not null and value<>'')
					--	begin
					--		select @OverTemp='1' from CustomerFunctionSetting WHERE FunctionName='AlarmTemperature' and cast(value as float)>0 and cast(value as float)<cast(@Temperature as float)
					--	end
					--if @OverTemp='0' and 37.2<cast(@Temperature as float)
					--	begin
					--		set @OverTemp='1'
					--	end

					set @UserTemp=@Temperature
					set @IsOverTemp=cast(@OverTemp AS int)
					set @Remark=@Temperature+'°C'
				end
		end
	else if CHARINDEX('Temperature',@EventMessage)>0
		begin
			set @EventMessage=SubString(@EventMessage,0,CHARINDEX('Temperature: ',@EventMessage)-2)
		end

	Declare @DeviceID int,@Readername nvarchar(125),@AreaID int,@BuildingID int,@IsCardMachine int,@HasQRCode bit,@HasFace bit,@DoorID int,@InOutType int,@IsFirst int,@HasQRCodeReader bit--samlau 20210304
	set @DeviceID=@ReaderID
	set @Readername='' 
	set @AreaID=0
	set @BuildingID=0
	set @HasQRCode=0
	set @HasFace=0
	set @IsCardMachine=0
	set @DoorID=@DoorNo--samlau 20210304
	set @InOutType=1--samlau 20210304
	set @IsFirst=1--samlau 20210304
	set @IsOpenDoor=0--samlau 20210304
	set @IsMatched=1--samlau 20210304
	set @HasQRCodeReader=0--samlau 20210519

	select @Readername=HostName,@AreaID=xq_id,@BuildingID=ly_id,@IsCardMachine=IsCardMachine,@HasQRCode=HasQRCode,@HasFace=hasFace,@DoorID=DoorID,@InOutType=InOutType,@HasQRCodeReader=HasQRCodeReader from V_HostDevice where HostDeviceID=@DeviceID and BrandID=13--samlau 20210304 
	if @DoorNo>1 or @DoorID<>@DoorNo--samlau 20210314 
		begin
			select @DeviceID=HostDeviceID,@Readername=HostName,@AreaID=xq_id,@BuildingID=ly_id,@IsCardMachine=IsCardMachine,@HasQRCode=HasQRCode,@HasFace=hasFace,@DoorID=DoorID,@InOutType=InOutType,@HasQRCodeReader=HasQRCodeReader from V_HostDevice where MainReaderID=@DeviceID and DoorID=@DoorNo and HostCamera>1 and BrandID=13--samlau 20210314 
		end

	if @IsCardMachine=1 --samlau 20210519
		begin
			Delete From BT_sys_FreeCard where sys_CardNO=@CardNO
			insert into BT_sys_FreeCard (sys_CardNO,sys_EventTime,sys_DeviceID,sys_CreateTime)
			values(@CardNO,@EventTime,@DeviceID,GetDate())
		end

	Declare @IsQRCode int--samlau 20210304
	set @IsQRCode=0--samlau 20210304
	if @QRCode is null--samlau 20210304
		set @QRCode=''
	else if @QRCode='0'
		set @QRCode=''

	set @UserID=0
	set @UserCode=''
	set @UserName=NULL
	set @UserAddress=@EmployeeNo--samlau 20210304
	set @UserType=0--samlau 20210304
	set @CardType=0--samlau 20210304
	set @IfHadFace=0--samlau 20210304
	if @CardNO='0000000000' or  @CardNO='' or  @CardNO='0' or @CardNO is null or replace(@CardNO,'0','')=''--samlau 20160415
		begin 
			set @CardNO=null-- samlau 20170531 
		end
	else
		begin
			select @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=cast(col_UserAddress as nvarchar(16)),@UserType=col_UserType,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@CardNO--samlau 20210304  
			--if @UserID=0 and len(@CardNO)<10
			--	begin
			--		set @tmpCardID=right(('0000000000' + @CardNO),10)
			--		select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=cast(col_UserAddress as nvarchar(16)),@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@@tmpCardID 
			--	end
			if @UserID=0  
				begin
					set @tmpCardID=replace(ltrim(replace(@CardNO,'0',' ')),' ','0') 
					select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserName=col_UserName,@UserAddress=cast(col_UserAddress as nvarchar(16)),@UserType=col_UserType,@CardNO=col_CardID,@CardType=col_CardType,@IfHadFace=col_IfHadFace from BT_col_UserInfoForReader WITH(NOLOCK) where col_CardID=@tmpCardID 
				end
				
			if @UserID=0  
				begin
					select top 1 @UserID=qrcode_id,@UserCode=visitor,@UserName=visitor,@UserType=1,@CardNO=cardid,@IsQRCode=1,@CardType=11,@IfHadFace=0 from BT_OpenDoor_QRCode WITH(NOLOCK) where cardid=@CardNO 
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

	if @CardNO='' and @UserID=0 and @UserTemp='0'
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

	Declare @isTAData bit-- samlau 20160715
	if @UserID>0-- samlau 20160715
		begin
			set @isTAData=1-- samlau 20160715
			if @EventType=6 and @UserTemp='0' and @HasQRCodeReader='true'--samlau 20210525 QRCODE下載成黑名單卡的情況
				begin
					set @EventType=1
				end
 		end
	else
		begin
			set @isTAData=0-- samlau 20160715
			if @IsCardMachine=0 and @UserTemp<>'0' and @IsOverTemp=0 and @EventType=999--samlau 20210519
				begin
					set @IsFirst=0
					set @IsMatched=0
				end
		end

	if @IsQRCode=0 and @UserID=0
		begin
			if @QRCode<>''--samlau 20210304
				set @IsQRCode=1
			else if @UserID=0 and len(@CardNO)=14
				set @IsQRCode=1
		end

	set @Valid='false'	
	Declare @dwVerifyMode int
	set @dwVerifyMode=0
	Declare @EventTypeBackup int
	set @EventTypeBackup=@EventType
	if @EventType=1--合法卡认证通过
		begin	
			set @Valid='true'		
			if @CardNO='18446744073709551613'--超級密碼 samlau 20161230
				begin
					set @dwVerifyMode=1003--samlau 20161230
					Set @EventType=10--samlau 20180921		28--samlau 20161230
					set @isTAData=0--samlau 20161230
				end
			else if @CardNO='18446744073709551614'--胁迫密碼 samlau 20161230
				begin
					set @dwVerifyMode=1003--samlau 20161230
					Set @EventType=9 --samlau 20180921		28--samlau 20161230
					set @isTAData=0--samlau 20161230
				end
			else
				begin
					set @dwVerifyMode=1004
					Set @EventType=1234+@dwVerifyMode
				end
		end
	else if @EventType=2--刷卡加密码认证通过
		begin
			set @Valid='true'		
			set @dwVerifyMode=1011
			Set @EventType=1234+@dwVerifyMode
		end
	else if @EventType=5--刷卡加密码超次
		begin
			set @dwVerifyMode=1011
			Set @EventType=1234+@dwVerifyMode
		end
	else if @EventType=6--未分配权限
		begin
			set @dwVerifyMode=1004
			Set @EventType=4
		end
	else if @EventType=7--无效时段
		begin
			set @dwVerifyMode=1000
			Set @EventType=4
		end
	else if @EventType=8--卡号过期
		begin
			set @dwVerifyMode=1004
			Set @EventType=3
		end
	else if @EventType=9--无此卡号
		begin
			set @dwVerifyMode=1004
			Set @EventType=3
		end
	else if @EventType=16--多重认证成功
		begin
			set @Valid='true'
			set @dwVerifyMode=1000
			Set @EventType=1234+@dwVerifyMode
		end
	else if @EventType=17--首卡开门开始
		begin
			set @dwVerifyMode=1004
			Set @EventType=1234+@dwVerifyMode
		end 
	else if @EventType=38--指纹比对通过  samlau 20170524
		begin
			set @Valid='true'
			set @dwVerifyMode=1001--2235 指紋驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
	else if @EventType=49--指纹不存在  samlau 20170524
		begin
			set @dwVerifyMode=1001--2235 指紋驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
	else if @EventType=40--刷卡加指纹认证通过  samlau 20170524
		begin
			set @Valid='true'
			set @dwVerifyMode=1010--2244 指紋+卡片驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
	else if @EventType=43--刷卡加指纹加密码认证通过  samlau 20170524
		begin
			set @Valid='true'
			set @dwVerifyMode=1012--2246 指紋+密碼+卡片驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=46--46--指纹加密码认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1009--2243 指紋+密碼驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=54--54--人脸加指纹认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1016--2250	面部+指紋驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=57--57--人脸加密码认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1017--2251	面部+密碼驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=60--60--人脸加刷卡认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1018--2252	面部+卡片驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=63--63--人脸加密码加指纹认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1020--2254	面部+指紋+密碼驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=66--66--人脸加刷卡加指纹认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1019--2253	面部+指紋+卡片驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=69--69--工号加指纹认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1008--2242	用戶位置+指紋驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=72--72--工号加指纹加密码认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1013--2247	用戶位置+指紋+密碼驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=75--75--人脸认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1015--2249	面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=76--76--人脸认证失败   samlau 20210312
		begin
    		set @dwVerifyMode=1015--2249	面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=999--999--測溫事件   samlau 20210520
		begin
    		set @dwVerifyMode=1015--2249	面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=77--77--工号加人脸认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1027--2261	用戶位置+面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=101--101--工号加密码认证通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1025--2259	用戶位置+密碼驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=105--105--人证比对通过   samlau 20170524
		begin
			set @Valid='true'
    		set @dwVerifyMode=1015--2249	面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
    else if @EventType=107--107--黑名单事件   samlau 20170524
		begin
    		set @dwVerifyMode=1000--指紋或密碼或卡片或面部驗證進出   samlau 20170524
			Set @EventType=1234+@dwVerifyMode
		end 
	else if @EventType=1034--胁迫报警-- samlau 20161228
		begin
			Set @EventType=9-- samlau 20161228
			set @dwVerifyMode=1003-- samlau 20161228
			set @isTAData=0-- samlau 20161228
		end 
	else if @EventType=1039--解除码输入-- samlau 20161228
		begin
			set @Valid='true'
			Set @EventType=15-- samlau 20161228
			set @dwVerifyMode=1003-- samlau 20161228
			set @isTAData=0-- samlau 20161228
		end 
		
	set @EventType=@EventTypeBackup
	if @dwVerifyMode=0
		begin 
			set @isTAData=0-- samlau 20160715
			SET @Valid='false'
			return
		end
		 
	Declare @EventTypeMessage as nvarchar(max)
	select @EventTypeMessage=sys_EventType from BT_sys_EventTypeForReader where sys_ID=@EventType
	if @EventTypeMessage is null
		begin
			set @EventTypeMessage=@EventMessage
		end
	if @UserTemp<>'0'--samlau 20210304
		begin
			set @EventTypeMessage=@EventTypeMessage+'; ' + @UserTemp +'°C'
		end

	if @Valid='true' and @OverTemp='1'
		begin
			set @Valid='false'
		end

	if @UserID>0 and @Valid='true'
		begin
			set @IsOpenDoor=1
			set @OpenDoorTime=@EventTime
		end

	if @IsFirst=0--samlau 20210304 海康測溫記錄匹配Soyal拍卡記錄
		begin
			Declare @tmpReaderID as int,@tmpsysID bigint
			set @tmpReaderID=0
			set @tmpsysID=0
			select top 1 @tmpReaderID=HostDeviceID from V_HostDeviceForSam where ly_id=@BuildingID and DoorID=@DoorID and HostDeviceID<>@DeviceID and BrandID=15 and NeedTemperature=1 order by HostDeviceID
			if @tmpReaderID=0
				begin
					select top 1 @tmpReaderID=HostDeviceID from V_HostDeviceForSam where ly_id=@BuildingID and DoorID=@DoorID and HostDeviceID<>@DeviceID and BrandID<>13 and NeedTemperature=1 order by HostDeviceID
				end
			if @tmpReaderID=0
				begin
					select top 1 @tmpReaderID=HostDeviceID from V_HostDeviceForSam where ly_id=@BuildingID and DoorID=@DoorID and HostDeviceID<>@DeviceID and NeedTemperature=1 order by HostDeviceID
				end

			if @tmpReaderID>0
				begin
					select @tmpsysID=sys_ID from BT_sys_RawDataLogForReader a where sys_ReaderID=@tmpReaderID and sys_EventTime<=@EventTime and sys_EventTime>=dateadd(second,-5,@EventTime) and sys_EventType=1 and sys_UserID>0 and ISNULL(sys_UserTemp,0)=0 and sys_SecondHostID=0 and sys_IsOpenDoor=0 and sys_EventTime=(select max(sys_EventTime) from BT_sys_RawDataLogForReader where sys_ReaderID=a.sys_ReaderID)
					if @tmpsysID>0
						begin
							update BT_sys_RawDataLogForReader set sys_UserTemp=@UserTemp,sys_IsOverTemp=@IsOverTemp,sys_SecondHostID=@DeviceID,sys_SecondEventTime=@EventTime,sys_IsOpenDoor=1,sys_OpenDoorTime=@EventTime WHERE sys_ID=@tmpsysID
							update BT_sys_RawDataLogForReader set sys_PicDataUrl=@PicDataUrl WHERE sys_ID=@tmpsysID and ISNULL(sys_PicDataUrl,'')=''

							-----------要控制开闸启用下面三行-----------
							--Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@tmpReaderID and col_Status<0
							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select sys_ID,'OPENDOOR',ISNULL(sys_UserName,'OPENDOOR'),ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(col_FCCellID,'0'),sys_CardNO,ISNULL(col_CardType,0),sys_EventTime,sys_EventTime,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@tmpReaderID,-3,0,1,0,'2008-10-01','2008-10-01' from BT_sys_RawDataLogForReader a left join BT_col_UserInfoForReader b on a.sys_UserID=b.col_UserID and a.sys_CardNO=b.col_CardID where sys_ID=@tmpsysID
							-----------要控制开闸启用下面三行-----------

							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select sys_ID,'OPENDOOR',ISNULL(sys_UserName,'OPENDOOR'),ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(col_FCCellID,'0'),sys_CardNO,ISNULL(col_CardType,0),sys_EventTime,sys_EventTime,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@DeviceID,-3,0,1,0,'2008-10-01','2008-10-01' from BT_sys_RawDataLogForReader a left join BT_col_UserInfoForReader b on a.sys_UserID=b.col_UserID and a.sys_CardNO=b.col_CardID where sys_ID=@tmpsysID

							set @IsMatched=1
						end
				end
			else if @HasQRCodeReader='true'
				begin
					select @tmpsysID=sys_ID from BT_sys_RawDataLogForReader a where sys_ReaderID=@DeviceID and sys_EventTime<=@EventTime and sys_EventTime>=dateadd(second,-5,@EventTime) and sys_EventType=1 and sys_UserID>0 and ISNULL(sys_UserTemp,0)=0 and sys_SecondHostID=0 and sys_IsOpenDoor=0 and sys_EventTime=(select max(sys_EventTime) from BT_sys_RawDataLogForReader where sys_ReaderID=a.sys_ReaderID and sys_EventTime<=@EventTime and sys_EventType=1)
					if @tmpsysID>0
						begin
							update BT_sys_RawDataLogForReader set sys_UserTemp=@UserTemp,sys_IsOverTemp=@IsOverTemp,sys_SecondHostID=@DeviceID,sys_SecondEventTime=@EventTime,sys_IsOpenDoor=1,sys_OpenDoorTime=@EventTime WHERE sys_ID=@tmpsysID
							update BT_sys_RawDataLogForReader set sys_PicDataUrl=@PicDataUrl WHERE sys_ID=@tmpsysID and ISNULL(sys_PicDataUrl,'')=''

							-----------要控制开闸启用下面三行-----------
							--Delete From BT_col_AutoDownloadUserForReader where col_DeviceID=@tmpReaderID and col_Status<0
							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select sys_ID,'OPENDOOR',ISNULL(sys_UserName,'OPENDOOR'),ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(col_FCCellID,'0'),sys_CardNO,ISNULL(col_CardType,0),sys_EventTime,sys_EventTime,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@tmpReaderID,-3,0,1,0,'2008-10-01','2008-10-01' from BT_sys_RawDataLogForReader a left join BT_col_UserInfoForReader b on a.sys_UserID=b.col_UserID and a.sys_CardNO=b.col_CardID where sys_ID=@tmpsysID
							-----------要控制开闸启用下面三行-----------

							--INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
							--select sys_ID,'OPENDOOR',ISNULL(sys_UserName,'OPENDOOR'),ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(col_FCCellID,'0'),sys_CardNO,ISNULL(col_CardType,0),sys_EventTime,sys_EventTime,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,0),ISNULL(col_Status,0),@DeviceID,-3,0,1,0,'2008-10-01','2008-10-01' from BT_sys_RawDataLogForReader a left join BT_col_UserInfoForReader b on a.sys_UserID=b.col_UserID and a.sys_CardNO=b.col_CardID where sys_ID=@tmpsysID

							set @IsMatched=1
						end
				end

			if @IsMatched=0 AND @CardNO<>''
				begin
					set @IsFirst=1
				end
		end

	Declare @count as int,@sys_ID as int,@sys_PicDataUrl as nvarchar(max),@sys_QRCode as nvarchar(max)
	set @count=0
	set @sys_ID=0
	set @sys_PicDataUrl=''
	set @sys_QRCode=''
	select @count=1,@sys_ID=sys_ID,@sys_PicDataUrl=sys_PicDataUrl,@sys_QRCode=sys_QRCode from BT_sys_RawDataLogForReader where sys_ReaderID=@DeviceID and sys_EventTime=@EventTime and sys_EventType=@EventType and sys_CardNO=@CardNO --and sys_UserCode=@UserCode-- and sys_UserID=@UserID
	if @count=0
		begin
			select @count=1,@sys_ID=sys_ID,@sys_PicDataUrl=sys_PicDataUrl,@sys_QRCode=sys_QRCode from BT_sys_RawDataLogForReader where sys_ReaderID=@DeviceID and sys_EventTime=dateadd(second,-1,@EventTime) and sys_EventType=@EventType and sys_CardNO=@CardNO and sys_GetDataTime<@GetDataTime-- and sys_UserCode=@UserCode and sys_UserID=@UserID
		end

	if @count=1
		begin 
			if @Temperature<>'0'--samlau 20200508
				begin
					update BT_sys_RawDataLogForReader set sys_UserTemp=@UserTemp,sys_IsOverTemp=@IsOverTemp where sys_ID=@sys_ID --AND (sys_Reserved1 IS NULL OR sys_Reserved1='')
				end

			if @IsFirst=1
				begin
					update BT_sys_RawDataLogForReader set sys_IsFirst=@IsFirst where sys_ID=@sys_ID and sys_IsFirst=0 
				end

			if (@sys_PicDataUrl='' and @PicDataUrl<>'') OR (charindex(':',@sys_PicDataUrl)=0 AND charindex(':',@PicDataUrl)>1)--samlau 20200508
				begin
					update BT_sys_RawDataLogForReader set sys_PicDataUrl=@PicDataUrl where sys_ID=@sys_ID
				end

			if @sys_QRCode='' and (@QRCode<>'' OR @IsQRCode=1)
				begin
					update BT_sys_RawDataLogForReader set sys_QRCode=@QRCode,sys_IsQRCode=1 where sys_ID=@sys_ID--samlau 20210304
				end
				
			if @Valid='false'--samlau 20200716
				begin
					update BT_sys_RawDataLogForReader set sys_Valid=@Valid where sys_ID=@sys_ID and sys_Valid<>@Valid --samlau 20200716
				end

			update BT_sys_RawDataLogForReader set sys_ReaderID=@DeviceID,sys_DeviceName=@Readername,sys_DoorID=@DoorID where sys_ID=@sys_ID and sys_DoorID<>@DoorID--samlau 20210414
			return
		end
		 
	insert into BT_sys_RawDataLogForReader (sys_ReaderID,sys_DeviceName,sys_EventTime,sys_EventType,sys_EventMessage,sys_CardNO,sys_PassWord,sys_CardName,sys_GetDataTime,sys_RoomNumber,sys_UserID,sys_UserCode,sys_UserName,sys_PicDataUrl,sys_QRCode,sys_AttendanceState,sys_CallLiftFloor,sys_Valid,sys_IsTAData,sys_AreaID,sys_BuildingID,sys_UserAddress,sys_UserType,sys_DoorID,sys_InOutType,sys_IsQRCode,sys_UserTemp,sys_IsOverTemp,sys_IsFirst,sys_SecondHostID,sys_SecondEventTime,sys_IsOpenDoor,sys_OpenDoorTime,sys_IsMatched)
	VALUES(@DeviceID,@Readername,N'' + @EventTime + '',@EventType,@EventTypeMessage,@CardNO,@PassWord,@CardName,@GetDataTime,@RoomNumber,@UserID,@UserCode,@UserName,@PicDataUrl,@QRCode,@AttendanceState,@CallLiftFloor,@Valid,@isTAData,@AreaID,@BuildingID,@UserAddress,@UserType,@DoorID,@InOutType,@IsQRCode,@UserTemp,@IsOverTemp,@IsFirst,0,NULL,@IsOpenDoor,@OpenDoorTime,@IsMatched)--samlau 20210304
	
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
					if @CardType<11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType<11 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime and col_Status=1--samlau 20210304
						end
					if @HasQRCode='true' AND @CardType=11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType=11 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime and col_Status=1--samlau 20210304
						end
					if @HasFace='true' AND @IfHadFace=1
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,dateadd(second,1,GETDATE()),dateadd(second,1,GETDATE()) from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_UserType=0 and col_CardType<12 and col_DateStart<=@EventTime and col_DateEnd>=@EventTime and col_Status=1 and col_IfHadFace=1--samlau 20210304					
						end
					if @CardType<11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType<11 and col_Status=0 --and col_DateEnd<dateadd(month,-6,getdate())--samlau 20210304
						end
					if @HasQRCode='true' AND @CardType=11
						begin
							INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) SELECT col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Status,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID where sys_ReaderID=@DeviceID and sys_UserCode=@UserCode and col_CardID=@CardNO and col_CardType=11 and col_Status=0 --and col_DateEnd<dateadd(month,-6,getdate())--samlau 20210304
						end
				end

		end

END
