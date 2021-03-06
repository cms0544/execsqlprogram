--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'GetAllNeedAutoProcessUserByReader') and xtype='P')  DROP PROCEDURE [dbo].[GetAllNeedAutoProcessUserByReader]
GO
/****** Object:  StoredProcedure [dbo].[GetAllNeedAutoProcessUserByReader]    Script Date: 10/31/2013 15:45:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2019-02-27>
-- Description:	<根據卡機獲取需要上傳下載的用戶列表> 
-- EXEC GetAllNeedAutoProcessUserByReader 30
-- =============================================
CREATE PROCEDURE [dbo].[GetAllNeedAutoProcessUserByReader]
(
@ReaderID nvarchar(32),--Soyal 的是ReaderLOGO,海康的是設備自增ID
@DownloadLevel int=0 --0: 普通下載；1：web 下載； 2：APP下載或手動下載；3：下載失敗等待重新下載的
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--col_status
--1: 下载卡号跟人脸
--2: 下载人脸
--4: 删除人脸
--5: 上传人脸
--9: 过期会员禁用门禁权限
--99: 已刪除会员

	Declare @InOutType as int,@lyid int,@AutoDelDay int,@IsCardRegReader int,@DeviceID int,@BrandID int,@IsSoyal int,@DownloadTime datetime,@DoorNum int
	set @AutoDelDay=31--出口有效期  
	set @InOutType=1
	set @IsCardRegReader=1
	set @BrandID=14
	set @IsSoyal=0
	set @DoorNum=1
	if SUBSTRING(@ReaderID,1,1)='S'
		begin
			set @DownloadTime=Dateadd(Minute,10,GetDate()) 	--Soyal的只能到時間再下載
			set @IsSoyal=1
			select @DeviceID=HostDeviceID,@lyid=ly_id,@InOutType=InOutType,@IsCardRegReader=IsCardMachine,@BrandID=BrandID from V_HostDeviceForSam WITH(NOLOCK) where ReaderLOGO=@ReaderID
		end
	else
		begin
			set @DownloadTime=Dateadd(year,1,GetDate()) --下人臉需要時間，所以其他的提前1年下載
			SET @DeviceID=cast(@ReaderID as int)
			select @lyid=ly_id,@InOutType=InOutType,@IsCardRegReader=IsCardMachine,@BrandID=BrandID,@DoorNum=HostCamera from V_HostDeviceForSam WITH(NOLOCK) where HostDeviceID=@DeviceID
			if @BrandID=15
				begin
					set @IsSoyal=1
				end
		end 

	if @IsCardRegReader=1
		return

	Declare @xq_door as bit
	set @xq_door='false'
	SELECT @xq_door=is_xq_door FROM BT_FC_Lg_Ext where lgid=@lyid
	Declare @isOneInOneOut as int
	set @isOneInOneOut=0--启用一进一出限制
	select @isOneInOneOut=1 from BT_SystemParam where ParamName='PMS_EnabledOneInOneOut' and ParamValue=1 
	
	if @DoorNum>1
		begin
	--select top (case when @IsSoyal=0 then 10 when @DownloadLevel=0 then 3 else 5 end) 因為要控制開門，所以不能連續下載
	select top (case when @IsSoyal=0 then 1 else 3 end) col_ID,col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,
	Case when ISNULL(col_FCCellID,'0')<>'0' then col_FCCellID When col_IsQRCodeCard=1 then 'QRCODE' When @BrandID<>14 then ISNULL(col_FCCellID,'0') WHEN @xq_door='true' and ISNULL(col_FCCellID,'0')<>'0' THEN col_FCCellID WHEN @xq_door='true' THEN (select TOP 1 CellCode from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode) when @xq_door='false' and (col_FCCellID='0' or (select lgid from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode and CellCode=col_FCCellID)<>@lyid) then (select TOP 1 CellCode from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode AND lgid=@lyid) END AS col_FCCellID,
	col_CardNo as col_CardID,col_CardType,col_DateStart,case when @InOutType=2 and @isOneInOneOut=1 then convert(nvarchar(10),dateadd(day,@AutoDelDay,col_DateEnd),120) else col_DateEnd end as col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled as col_Status,col_IsQRCodeCard,col_DeviceID,col_Status as col_SetOrClear,col_DownloadLevel,col_RunCount,col_UpdateTime
	from BT_col_AutoDownloadUserForReader 
	where col_DeviceID in (select HostDeviceID from V_HostDeviceForSam where MainReaderID=@DeviceID) and col_DownloadLevel=@DownloadLevel and col_UpdateTime<@DownloadTime 
	order by col_UpdateTime,col_DateStart,col_UserID,col_DeviceID 
		end
	else
		begin
	--select top (case when @IsSoyal=0 then 10 when @DownloadLevel=0 then 3 else 5 end) 因為要控制開門，所以不能連續下載
	select top (case when @IsSoyal=0 then 1 else 3 end) col_ID,col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,
	Case when ISNULL(col_FCCellID,'0')<>'0' then col_FCCellID When col_IsQRCodeCard=1 then 'QRCODE' When @BrandID<>14 then ISNULL(col_FCCellID,'0') WHEN @xq_door='true' and ISNULL(col_FCCellID,'0')<>'0' THEN col_FCCellID WHEN @xq_door='true' THEN (select TOP 1 CellCode from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode) when @xq_door='false' and (col_FCCellID='0' or (select lgid from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode and CellCode=col_FCCellID)<>@lyid) then (select TOP 1 CellCode from View_ZHFCLPInfo a left join ZH_Members b on a.OwnerID=b.OwnerID WHERE b.Code=col_UserCode AND lgid=@lyid) END AS col_FCCellID,
	col_CardNo as col_CardID,col_CardType,col_DateStart,case when @InOutType=2 and @isOneInOneOut=1 then convert(nvarchar(10),dateadd(day,@AutoDelDay,col_DateEnd),120) else col_DateEnd end as col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled as col_Status,col_IsQRCodeCard,col_DeviceID,col_Status as col_SetOrClear,col_DownloadLevel,col_RunCount,col_UpdateTime
	from BT_col_AutoDownloadUserForReader 
	where col_DeviceID=@DeviceID and col_DownloadLevel=@DownloadLevel and col_UpdateTime<@DownloadTime 
	order by col_UpdateTime,col_DateStart,col_UserID 
		end

END
