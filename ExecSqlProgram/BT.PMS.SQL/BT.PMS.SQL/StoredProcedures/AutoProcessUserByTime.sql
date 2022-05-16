--USE [BT_PMS]
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'AutoProcessUserByTime') and xtype='P')  DROP PROCEDURE [dbo].[AutoProcessUserByTime]
GO
/****** Object:  StoredProcedure [dbo].[AutoProcessUserByTime]    Script Date: 11/9/2020 20:36:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<SAM>
-- Create date: <2020-09-21>
-- Description:	<自動處理員工，如過期到期刪除等> 
--EXEC AutoProcessUserByTime 0
-- =============================================
CREATE PROCEDURE [dbo].[AutoProcessUserByTime] 
(
	@ReaderID int
)
AS
BEGIN
	SET NOCOUNT ON;  

	Declare @tmpID as int,@count int
	set @tmpID=0
	set @count=0
	if @ReaderID<0
		begin
			set @ReaderID=0-@ReaderID
			select @ReaderID=HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15 and ReaderLOGO=(select ReaderLOGO From t_sys_ReaderMachine where connPortID=@ReaderID)
		end
	select @tmpID=min(HostDeviceID) from V_HostDeviceForSam where IsCardMachine=0 and HostDeviceID in (select sys_ReaderID from BT_sys_ReaderOnlineStatus where sys_LoginOrOut=1)

	if @ReaderID>0 AND @tmpID<>@ReaderID
		return 0
		
	Declare @TodayDate datetime,@TomorrowDate datetime
	set @TodayDate=Convert(nvarchar(10),GETDATE(),120)
	set @TomorrowDate=dateadd(day,1,@TodayDate)

	Declare @AutoDelDay int
	set @AutoDelDay=-30
	Declare @AutoDelDate datetime
	set @AutoDelDate=Convert(nvarchar(10),GETDATE(),120)
	set @AutoDelDate=DATEADD(day,@AutoDelDay, @AutoDelDate) 
	set @AutoDelDate=DATEADD(Hour,4, @AutoDelDate) 

	Delete From BT_col_AutoDownloadUserForReader where col_DeviceID is NULL
	
	set @count=0
	select @count=1 from BT_sys_ReaderOnlineStatus WHERE sys_DeviceID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
	if @count=1
		begin
			Delete from BT_sys_ReaderOnlineStatus where sys_DeviceID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
			Delete from BT_sys_ReaderOnlineLog where sys_DeviceID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
			Delete from t_sys_ReaderMachine where ReaderLOGO NOT IN (select ReaderLOGO from BT_HostDevice WITH(NOLOCK))
			Delete from BT_sys_UserReaderAccess where sys_ReaderID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
			Delete from BT_sys_UserReaderAccessOld where sys_ReaderID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
			Delete from BT_sys_UserReaderAccess_JTCY where sys_ReaderID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
			Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_ReaderID NOT IN (select HostDeviceID from BT_HostDevice WITH(NOLOCK))
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_DeviceID NOT IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK))
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_DeviceID NOT IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK))
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_DeviceID NOT IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK)) and col_CreateTime<Dateadd(day,-1,@TodayDate)
	if @count=1
		begin
			Delete From BT_col_AutoDownloadUserForReader where col_DeviceID not in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK)) and col_CreateTime<Dateadd(day,-1,@TodayDate)
		end
		
	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_Status=-3 and col_DateEnd<=dateadd(second,-10,GetDate())
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_Status=-3 and col_DateEnd<=dateadd(second,-10,GetDate())
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_Status=1 and col_DateEnd<=GetDate() and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK))-- where InOutType=1  一进一出才需要
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_Status=1 and col_DateEnd<=GetDate() and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK))-- where InOutType=1 一进一出才需要
		end
	-- 一进一出才需要
	--set @count=0
	--select @count=1 from BT_col_AutoDownloadUserForReader where col_Status=1 and col_DateEnd<=dateadd(day,-1,@TodayDate) and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=2)
	--if @count=1		
	--	begin
	--		Delete from BT_col_AutoDownloadUserForReader where col_Status=1 and col_DateEnd<=dateadd(day,-1,@TodayDate) and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=2)
	--	end
	
	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_UserAddress=0 and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15)
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_UserAddress=0 and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15) 
		end
	
	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_CardNo IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1 or col_DateEnd<GetDate()) and col_Status=1 --and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=1)
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_CardNo IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1 or col_DateEnd<GetDate()) and col_Status=1 --and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=1)
		end

	--set @count=0
	--select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_CardNo IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1) and col_Status=1 and col_DateEnd<=dateadd(day,-1,@TodayDate) and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=2)
	--if @count=1
	--	begin
	--		Delete from BT_col_AutoDownloadUserForReader where col_CardNo IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1) and col_Status=1 and col_DateEnd<=dateadd(day,-1,@TodayDate) and col_DeviceID IN (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where InOutType=2)
	--	end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_CardNo NOT IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status=1 and col_DateEnd>=GetDate()) and col_Status=1
	if @count=1
		begin
			Delete from BT_col_AutoDownloadUserForReader where col_CardNo NOT IN (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status=1 and col_DateEnd>=GetDate()) and col_Status=1
		end
		
	set @count=0
	select @count=1 from (select id,Code,ownerid,zpurl from ZH_Members WITH(NOLOCK) where REPLACE(ISNULL(zpurl,'no.gif'),'no.gif','')<>'') a left join BT_col_CardManagement b on a.id=b.col_UserID WHERE col_CardID not in (select COL_CardID from BT_col_UserFaceData WITH(NOLOCK)) and b.col_State=1
	if @count=1
		begin
			insert into BT_col_UserFaceData(col_UserCode,col_CardID,col_FaceURL,col_CreateTime) select code,col_CardID,zpurl,getdate() from (select id,Code,ownerid,zpurl from ZH_Members WITH (NOLOCK) where REPLACE(ISNULL(zpurl,'no.gif'),'no.gif','')<>'') a left join BT_col_CardManagement b on a.id=b.col_UserID WHERE col_CardID not in (select COL_CardID from BT_col_UserFaceData WITH(NOLOCK)) and b.col_State=1 
		end

	set @count=0
	select @count=1 from BT_col_UserInfoForReader WITH(NOLOCK) WHERE col_IfHadFace=0 and col_CardID in (select COL_CardID from BT_col_UserFaceData WITH(NOLOCK) )
	if @count=1
		begin
			update BT_col_UserInfoForReader set col_IfHadFace=1 where col_IfHadFace=0 and col_CardID in (select COL_CardID from BT_col_UserFaceData)
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_DownloadLevel=3 and col_UpdateTime<=GETDATE()
	if @count=1
		begin
			UPDATE BT_col_AutoDownloadUserForReader SET col_DownloadLevel=0 WHERE col_DownloadLevel=3 and col_UpdateTime<=GETDATE()
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader WHERE col_CardType=11 and col_Status=1 and col_DownloadLevel=0 and col_DateStart<dateadd(minute,1,GETDATE()) and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15)
	if @count=1
		begin
			UPDATE BT_col_AutoDownloadUserForReader SET col_DownloadLevel=1 WHERE col_CardType=11 and col_Status=1 and col_DownloadLevel=0 and col_DateStart<dateadd(minute,1,GETDATE()) and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15)
		end

	set @count=0
	select @count=1 from BT_col_AutoDownloadUserForReader a where col_datestart<getdate() and col_Status=1 and col_DownloadLevel=3 and col_RunCount=0 and col_updateTime>col_dateStart and col_updateTime>Getdate() and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15) and not exists (select 1 from BT_col_AutoDownloadUserForReader where col_DeviceID=a.col_DeviceID and col_Status=99)
	if @count=1
		begin
			update a set col_DownloadLevel=1,col_updateTime=col_dateStart from BT_col_AutoDownloadUserForReader a where col_datestart<getdate() and col_Status=1 and col_DownloadLevel=3 and col_RunCount=0 and col_updateTime>col_dateStart and col_updateTime>Getdate() and col_DeviceID in (select HostDeviceID from V_HostDeviceForSam WITH(NOLOCK) where BrandID=15) and not exists (select 1 from BT_col_AutoDownloadUserForReader where col_DeviceID=a.col_DeviceID and col_Status=99)
		end

	set @count=0
	select @count=1 from BT_col_UserIDAndAddress where col_UserID>0 and col_CardID not in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK))
	if @count=1
		begin
			update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_UserID>0 and col_CardID not in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK))  
		end
		
	set @count=0
	select @count=1 from BT_col_UserIDAndAddress where col_IsDel=0 and col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<GETDATE() and col_Status<>1 and col_IsUploadToReader=99 and col_InOutType<>1)
	if @count=1
		begin
			update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=1 where col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<GETDATE() and col_Status<>1 and col_IsUploadToReader=99 and col_InOutType<>1)
		end
  
	set @count=0
	select @count=1 from BT_col_UserIDAndAddress where col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<Dateadd(day,-7,@TodayDate) and col_Status<>1 and col_IsUploadToReader=99)
	if @count=1
		begin
			update BT_col_UserIDAndAddress set col_UserID=0,col_CardID='',col_IsDel=0 where col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<Dateadd(day,-7,@TodayDate) and col_Status<>1 and col_IsUploadToReader=99)    
		end
		
	set @count=0
	select @count=1 from BT_col_UserIDAndAddress where col_UserID=0 and col_IsDel=1
	if @count=1
		begin
			update BT_col_UserIDAndAddress set col_IsDel=0 where col_UserID=0 and col_IsDel=1
		end
		
	set @count=0
	select @count=1 from BT_col_UserInfoForReader where col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99-- and col_InOutType=-1  一进一出才需要
	if @count=1
		begin
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType<11 AND col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType>12 AND ISNULL(a.col_UserAddress,0)>0 and col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=12 AND ISNULL(a.col_UserAddress,0)>0 and col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=11 AND col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')

			update BT_col_CardManagement set col_State=0 where col_State=1 and col_CardID IN (SELECT col_CardID FROM BT_col_UserInfoForReader where col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99)
			update BT_OpenDoor_QRCode set cancel=1 where cancel=0 and cardid IN (SELECT col_CardID FROM BT_col_UserInfoForReader where col_UserType=1 and col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99)
			update BT_col_UserInfoForReader set col_PlanTemplateID=2,col_Status=0,col_IsUploadToReader=99 where col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader<99
		end

	set @count=0
	select @count=1 from BT_col_UserInfoForReader WHERE col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK))--卡號刪除的情況
	if @count=1
		begin
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_col_UserInfoForReader WHERE col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK)) AND col_Status=1 and col_IsUploadToReader<99) as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType<11  
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_col_UserInfoForReader WHERE col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK)) AND col_Status=1 and col_IsUploadToReader<99) as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType>12 and ISNULL(a.col_UserAddress,0)>0 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_col_UserInfoForReader WHERE col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK)) AND col_Status=1 and col_IsUploadToReader<99) as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=12 and ISNULL(a.col_UserAddress,0)>0 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_col_UserInfoForReader WHERE col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK)) AND col_Status=1 and col_IsUploadToReader<99) as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=11 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')
			update BT_col_UserInfoForReader set col_PlanTemplateID=2,col_Status=0,col_IsUploadToReader=99 where col_CardID not in (select col_CardID from BT_col_CardManagement WITH(NOLOCK))
		end

	Declare @TempDateTime as datetime,@qrcodeid int,@CardNo as nvarchar(125)
	set @TempDateTime=dateadd(hour,-24,getdate())--已过期一天
	set @qrcodeid=0
	set @CardNo=''
	select top 1 @qrcodeid=qrcode_id,@CardNo=cardid from BT_OpenDoor_QRCode where cancel=0 and end_time<=@TempDateTime order by end_time
	if @qrcodeid>0
		begin
			Exec SP_CancelOpenDoorQRCode @qrcodeid,@CardNo
		end

	----一进一出执行这个，不执行上面的
	--select col_UserID,col_UserType,col_UserAddress,col_CardID into #tmpForDisableCard from BT_col_UserInfoForReader WITH(NOLOCK) where col_DateEnd<GETDATE() and col_Status=1 and col_IsUploadToReader=1 and col_InOutType<>1--卡片过期，全部删掉
	--set @count=0
	--select @count=1 from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserType=2 and col_DateEnd<dateadd(day,-1,@TodayDate) and col_Status=1 and col_IsUploadToReader=1 and col_InOutType=1
	--if @count=1
	--	begin
	--		insert into #tmpForDisableCard select col_UserID,col_UserType,col_UserAddress,col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_DateEnd<dateadd(day,-1,@TodayDate) and col_Status=1 and col_IsUploadToReader=1 and col_InOutType=1
	--	end
	--set @count=0
	--select @count=1 from #tmpForDisableCard
	--if @count=1
	--	begin
	--		Delete from t_col_AutoDownloadUserForReader where col_CardNo IN (select col_CardID from #tmpForDisableCard) 
	--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType<>11 AND col_CardNo IN (select col_CardID from #tmpForDisableCard) 
	--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
	--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardType=11 AND col_CardNo IN (select col_CardID from #tmpForDisableCard) and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')

	--		update t_col_UserInfoForReader set col_PlanTemplateID=2,col_Status=0,col_SetorClear=99,col_IsAllOK=0,col_ErrorReaders='' where col_CardID in (select col_CardID from #tmpForDisableCard)
	--	end
	 
	set @count=0
	select @count=1 from BT_col_UserInfoForReader a where col_UserAddress>0 and col_Status=1 and exists(select 1 from BT_col_UserInfoForReader where col_UserID>a.col_UserID and col_UserAddress=a.col_UserAddress and col_CardID<>a.col_CardID and col_Status=1)
	if @count=1--重复用户位置的
		begin
			update a set col_UserAddress=0 from BT_col_UserInfoForReader a where col_UserAddress>0 and col_Status=1 and exists(select 1 from BT_col_UserInfoForReader where col_UserID>a.col_UserID and col_UserAddress=a.col_UserAddress and col_CardID<>a.col_CardID and col_Status=1)
		end


	Set @Count=0
	Select @Count=count(1) from BT_col_AutoDownloadUserForReader WITH(NOLOCK) where col_Status=1 AND col_UpdateTime<dateadd(minute,10,GETDATE())--没有下载的就加速删除的
	if @Count<=100
		begin
			set @count=0
			select @count=1 from BT_col_AutoDownloadUserForReader where col_Status=99 and col_DownloadLevel=0 and col_UpdateTime<@TodayDate
			if @count=1
				begin
					update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1 where col_ID in (select top 100 col_ID from BT_col_AutoDownloadUserForReader where col_Status=99 and col_DownloadLevel=0 and col_UpdateTime<@TodayDate order by col_DateEnd,col_UpdateTime)
				end
				
  			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			select top 100 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE()
			from BT_col_UserInfoForReader as a WITH(NOLOCK) inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo  
			 where a.col_CardType<11 and col_Status=1 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GETDATE() --and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
			and col_CardID not in (select sys_CardID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=1 and sys_ReaderID=b.sys_ReaderID and sys_CreateTime>a.col_UpdateTime)
			and col_CardID not in (select col_CardNo from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_Status=1 and col_DeviceID=b.sys_ReaderID) order by a.col_DateStart,a.col_CreateTime
			
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			select top 100 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE()
			from BT_col_UserInfoForReader as a WITH(NOLOCK) inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo  
			 where ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and col_Status=1 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GETDATE() and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
			and col_CardID not in (select sys_CardID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=1 and sys_ReaderID=b.sys_ReaderID and sys_CreateTime>a.col_UpdateTime)
			and col_CardID not in (select col_CardNo from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_Status=1 and col_DeviceID=b.sys_ReaderID) order by a.col_DateStart,a.col_CreateTime
			
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			select top 100 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE()
			from BT_col_UserInfoForReader as a WITH(NOLOCK) inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo  
			 where ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and col_Status=1 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GETDATE() and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')
			and col_CardID not in (select sys_CardID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=1 and sys_ReaderID=b.sys_ReaderID and sys_CreateTime>a.col_UpdateTime)
			and col_CardID not in (select col_CardNo from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_Status=1 and col_DeviceID=b.sys_ReaderID) order by a.col_DateStart,a.col_CreateTime
			
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			select top 100 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,col_DateStart,GETDATE()
			from BT_col_UserInfoForReader as a WITH(NOLOCK) inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo  
			 where a.col_CardType=11 and col_Status=1 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GETDATE() and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')
			and col_CardID not in (select sys_CardID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=1 and sys_ReaderID=b.sys_ReaderID and sys_CreateTime>a.col_UpdateTime)
			and col_CardID not in (select col_CardNo from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_Status=1 and col_DeviceID=b.sys_ReaderID) order by a.col_DateStart,a.col_CreateTime
			
			INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
			select top 100 col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,DATEADD(SECOND,1,GETDATE()),DATEADD(SECOND,1,GETDATE())
			from BT_col_UserInfoForReader as a WITH(NOLOCK) inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo  
			 where a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and col_Status=1 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GETDATE() and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
			and col_CardID not in (select sys_CardID from BT_sys_UserDownloadRecord where sys_UserCode=a.col_UserCode and sys_CardID=a.col_CardID and sys_SetOrClear=2 and sys_ReaderID=b.sys_ReaderID and sys_CreateTime>a.col_UpdateTime)
			and col_CardID not in (select col_CardNo from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_Status=2 and col_DeviceID=b.sys_ReaderID) order by a.col_DateStart,a.col_CreateTime

	 	end

--------------------------------------补回漏下载和漏删除的-------------------------------------
 if DATEPART(hour,getdate())=0 and DATEPART(minute,getdate())<=30--samlau 20200921
	begin
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,col_DateStart,GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType<11 and bb.col_Status=1 and bb.col_DateEnd>GetDate() and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear=99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=1)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType>12 and ISNULL(bb.col_UserAddress,0)>0 and bb.col_Status=1 and bb.col_DateEnd>GetDate() and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear=99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=1)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType=12 and ISNULL(bb.col_UserAddress,0)>0 and bb.col_Status=1 and bb.col_DateEnd>GetDate() and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear=99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=1)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,col_DateStart)>0 then col_DateStart else GetDate() end,GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType=11 and bb.col_Status=1 and bb.col_DateEnd>GetDate() and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true') and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear=99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a left join V_HostDeviceForSam c on a.sys_ReaderID=c.HostDeviceID where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=1)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,dateadd(second,1,GETDATE()),dateadd(second,1,GETDATE()) from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_UserType=0 and bb.col_CardType<12 and bb.col_IfHadFace=1 and bb.col_Status=1 and bb.col_DateEnd>GetDate() and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15) and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear=1 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=2)
		 
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType<11 and bb.col_Status=0 and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear<99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=99)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType>12 and ISNULL(bb.col_UserAddress,0)>0 and bb.col_Status=0 and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear<99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=99)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType=12 and ISNULL(bb.col_UserAddress,0)>0 and bb.col_Status=0 and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear<99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=99)
	
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		select col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,0,0,GETDATE(),GETDATE() from (
		select bb.col_UserID,bb.col_UserCode,bb.col_UserName,bb.col_UserType,bb.col_UserAddress,bb.col_FCCellID,bb.col_CardID,bb.col_CardType,bb.col_DateStart,bb.col_DateEnd,bb.col_MaxSwipeTime,bb.col_PlanTemplateID,bb.col_Status,cc.sys_ReaderID from BT_sys_UserReaderAccess cc left join BT_col_UserInfoForReader bb on cc.sys_UserCode=bb.col_UserCode and cc.sys_CardNo=bb.col_CardID 
		where bb.col_CardType=11 and bb.col_Status=0 and bb.col_UpdateTime>dateadd(day,-7,Getdate()) and cc.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true') and exists(
		select DISTINCT sys_usercode,sys_CardID,sys_ReaderID from BT_sys_UserDownloadRecord aa where aa.sys_usercode=bb.col_Usercode and aa.sys_CardID=bb.col_CardID and aa.sys_ReaderID=cc.sys_ReaderID and aa.sys_CreateTime>bb.col_UpdateTime  
		 AND aa.sys_SetOrClear<99 and sys_CreateTime=(
		select max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_usercode=aa.sys_usercode and sys_CardID=aa.sys_CardID and sys_ReaderID=aa.sys_ReaderID
		))) a where not exists (select 1 from BT_col_AutoDownloadUserForReader where col_UserCode=a.col_UserCode and col_CardNo=a.col_CardID and col_DeviceID=a.sys_ReaderID and col_Status=99)
	
	end
---------------------------------------------------------------------------------------
 
	Declare @UserID bigint,@oldUserID bigint,@UserCode nvarchar(125)--记录的唯一标识
	Declare @CardID nvarchar(125)--卡号、二维码编号
	Declare @UserType int--用戶类型：0：業主；1：訪客
	Declare @CardType int--卡类型：0：NFC；11：QRCode；12：八達通
	Declare @StartDate nvarchar(19)--有效时段开始时间	yyyy-MM-dd HH:mm:ss
	Declare @EndDate nvarchar(19)--有效时段结束时间	yyyy-MM-dd HH:mm:ss 
	
CREATE TABLE #t_col_UserInfoForReader(
	col_UserID bigint NOT NULL,
	col_UserCode nvarchar(125) NOT NULL, 
	col_UserType int NOT NULL,   
	col_UserAddress int NOT NULL,   
	col_CardID nvarchar(125) NOT NULL, 
	col_CardType int NOT NULL,   
	col_DateStart datetime NOT NULL,
	col_DateEnd datetime NOT NULL,
	col_CreateTime datetime NOT NULL
	)
	--------------------------------------------有效卡没有分配到用户位置的看看有没有删除了卡号之后分配到了用户位置的--------------------------------------------------------------------
	Set @Count=0
	Select @Count=count(1) from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=0 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GetDate() and col_Status=1 
	if @Count>0
		begin
			set @count=0
			select @count=1 from BT_col_AutoDownloadUserForReader where col_Status=99 and col_UpdateTime>'2008-01-02' and col_UpdateTime<@TomorrowDate
			if @count=1
				begin
					update BT_col_AutoDownloadUserForReader set col_DownloadLevel=1,col_UpdateTime='2008-01-01 '+ convert(nvarchar(8),col_DateStart,108) where col_ID in (select top 10 col_ID from BT_col_AutoDownloadUserForReader where col_Status=99 and col_UpdateTime>'2008-01-02' and col_UpdateTime<@TomorrowDate order by col_UpdateTime,col_UserID,col_UserAddress)
				end
				
			set @count=0
			select @count=1 from BT_col_UserIDAndAddress where col_IsDel=0 AND col_UserID>0 and col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<dateadd(day,-1,@TodayDate) and col_IsUploadToReader=99 and col_UpdateTime<dateadd(day,-1,@TodayDate))
			if @count=1
				begin
					update BT_col_UserIDAndAddress set col_IsDel=1 where col_IsDel=0 AND col_UserID>0 and col_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress>0 and col_DateEnd<dateadd(day,-1,@TodayDate) and col_IsUploadToReader=99 and col_UpdateTime<dateadd(day,-1,@TodayDate))--col_UserType=2 and
				end

			insert into #t_col_UserInfoForReader Select top 100 col_UserID,col_UserCode,col_UserType,col_UserAddress,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_CreateTime from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=0 and (col_CardType=0 or col_CardType>=12) and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GetDate() and col_Status=1 order by col_DateStart,col_CreateTime
			Set @Count=0
			Select @Count=count(1) FROM BT_col_UserIDAndAddress WITH(NOLOCK) where col_UserID=0 or col_IsDel=1
			if @Count=0
				begin
					insert into #t_col_UserInfoForReader Select top 100 col_UserID,col_UserCode,col_UserType,col_UserAddress,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_CreateTime from BT_col_UserInfoForReader WITH(NOLOCK) where col_UserAddress=0 and col_DateStart<=dateadd(minute,10,GetDate()) and col_DateEnd>GetDate() and col_Status=1 order by col_DateStart,col_CreateTime
				end

			Declare @i as int
			Set @Count=0
			Select @Count=count(1) FROM BT_col_UserIDAndAddress WITH(NOLOCK) where col_UserID=0 or col_IsDel=1
			if @Count>0--释放了多少个用户位置
				begin
					set @oldUserID=0
					set @i=0
					while @i<@count and @i<=100
						begin
							set @UserID=0
							Select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserType=col_UserType,@CardID=col_CardID,@CardType=col_CardType,@StartDate=convert(nvarchar(19),col_DateStart,120),@EndDate=convert(nvarchar(19),col_DateEnd,120) from #t_col_UserInfoForReader WITH(NOLOCK) order by col_DateStart,col_CreateTime
							if @UserID=0
								break

							Delete From #t_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardID							
							Exec SaveUserCardInfoForReader @UserID,@CardID,@UserType,1
							--Exec SaveUserInfoForReader @UserCode,@CardID,@UserType,1
							set @i=@i+1
							--set @oldUserID=@UserID
						end
				end
				
			 
		end
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	truncate table #t_col_UserInfoForReader
	insert into #t_col_UserInfoForReader select top 100  C.col_UserID,C.col_UserCode,C.col_UserType,col_UserAddress,C.col_CardID,C.col_CardType,C.col_DateStart,C.col_DateEnd,C.col_CreateTime from BT_col_CardManagement a left join ZH_Members b on a.col_UserID=b.id left join ZH_Owner m on b.OwnerID=m.ID 
	 left join BT_col_UserInfoForReader c on a.col_UserID=c.col_UserID and a.col_CardID=c.col_CardID 
	 left join BT_col_UserFaceData d on c.col_UserCode=d.col_UserCode and c.col_CardID=d.col_CardID
	where ISNULL(a.col_UserID,0)>0 and a.col_UserType=0 and ISNULL(c.col_UserID,0)>0 and c.col_CreateTime<dateadd(minute,-5,GetDate()) 
	and (c.col_UserType<>a.col_UserType or c.col_CardType<>a.col_CardType or c.col_UserName<>isnull(b.alias,b.name)
	and c.col_MaxSwipeTime<>a.col_MaxSwipeTime and REPLACE(ISNULL(d.col_FaceURL,'no.gif'),'no.gif','')<>REPLACE(ISNULL(b.zpurl,'no.gif'),'no.gif','')
	or (c.col_Status=1 and c.col_DateStart<>a.col_DateStart) OR (c.col_Status=1 and c.col_DateEnd<>a.col_DateEnd) or (c.col_Status=1 and (a.col_state=0 or b.deleted=1 or m.yzzt='停用')) or (c.col_Status=0 and (a.col_state=1 and b.deleted=0 and m.yzzt='正常')) 
     ) order by C.col_DateStart,C.col_CreateTime --姓名，有效期，照片等信息修改了的
	Set @Count=0
	Select @Count=count(1) from #t_col_UserInfoForReader 
	if @Count>0
		begin
			while 1=1
				begin
					set @UserID=0
					Select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserType=col_UserType,@CardID=col_CardID,@CardType=col_CardType,@StartDate=convert(nvarchar(19),col_DateStart,120),@EndDate=convert(nvarchar(19),col_DateEnd,120) from #t_col_UserInfoForReader WITH(NOLOCK) order by col_DateStart,col_CreateTime
					if @UserID=0
						break
						
					Delete From #t_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardID							
					Exec SaveUserCardInfoForReader @UserID,@CardID,@UserType,1
				end
		end
		

	--卡片刪除或禁用
	truncate table #t_col_UserInfoForReader
	insert into #t_col_UserInfoForReader select top 100 col_UserID,col_UserCode,col_UserType,col_UserAddress,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_CreateTime from BT_col_UserInfoForReader where col_UserType=0 and col_Status=1 and col_CardID not in (
	select col_CardID from BT_col_CardManagement where col_State=1
	)
  	Set @Count=0
	Select @Count=count(1) from #t_col_UserInfoForReader 
	if @Count>0
		begin
			while 1=1
				begin
					set @UserID=0
					Select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserType=col_UserType,@CardID=col_CardID,@CardType=col_CardType,@StartDate=convert(nvarchar(19),col_DateStart,120),@EndDate=convert(nvarchar(19),col_DateEnd,120) from #t_col_UserInfoForReader WITH(NOLOCK) order by col_DateStart,col_CreateTime
					if @UserID=0
						break
						
					Delete From #t_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardID							
					Exec SaveUserCardInfoForReader @UserID,@CardID,@UserType,1
				end
		end
  
	--新增卡片
	truncate table #t_col_UserInfoForReader
	insert into #t_col_UserInfoForReader select top 100 col_UserID,'',col_UserType,0,col_CardID,col_CardType,col_DateStart,col_DateEnd,col_CreateTime from BT_col_CardManagement where col_State=1 and col_UserID>0 and col_CardID not in (
	select col_CardID from BT_col_UserInfoForReader
	) order by col_CreateTime
  	Set @Count=0
	Select @Count=count(1) from #t_col_UserInfoForReader 
	if @Count>0
		begin
			while 1=1
				begin
					set @UserID=0
					Select top 1 @UserID=col_UserID,@UserCode=col_UserCode,@UserType=col_UserType,@CardID=col_CardID,@CardType=col_CardType,@StartDate=convert(nvarchar(19),col_DateStart,120),@EndDate=convert(nvarchar(19),col_DateEnd,120) from #t_col_UserInfoForReader WITH(NOLOCK) order by col_DateStart,col_CreateTime
					if @UserID=0
						break
						
					Delete From #t_col_UserInfoForReader where col_UserID=@UserID and col_CardID=@CardID							
					Exec SaveUserCardInfoForReader @UserID,@CardID,@UserType,1
				end
		end

 if DATEPART(hour,getdate())=23 and DATEPART(minute,getdate())>=30--samlau 20200908
	begin
		if not exists(select 1 from BT_SystemParam where ParamName='PMS_AutoDelRawDataLogBeforeDays' and ParamValue>0)--法律規定不能保存超過多少天的記錄，自動刪除歷史數據
			begin
				 set @AutoDelDay=0
				 select @AutoDelDay=0-ParamValue from BT_SystemParam where ParamName='PMS_AutoDelRawDataLogBeforeDays' 
				 if @AutoDelDay<>0
					begin
						set @AutoDelDate=Convert(nvarchar(10),GETDATE(),120)
						set @AutoDelDate=DATEADD(day,@AutoDelDay, @AutoDelDate) 
						Delete From BT_sys_RawDataLogForReader where sys_EventTime<@AutoDelDate
					end
			end

		set @count=0
		select @count=count(1) from BT_sys_UserDownloadRecord a WITH(NOLOCK) where sys_CreateTime<(select Max(sys_CreateTime) from BT_sys_UserDownloadRecord WITH(NOLOCK) where sys_UserCode=a.sys_UserCode and sys_CardID=a.sys_CardID and sys_ReaderID=a.sys_ReaderID and sys_SetOrClear=a.sys_SetOrClear) 
		if @count>1000
			begin
				insert into BT_sys_UserDownloadRecordBackup(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)
				select ISNULL(sys_UserID,0),ISNULL(sys_UserCode,''),sys_UserName,ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(sys_FCCellID,''),sys_CardID,ISNULL(sys_CardType,0),ISNULL(sys_DateStart,'2021-03-10'),ISNULL(sys_DateEnd,'2021-03-10'),ISNULL(sys_MaxSwipeTime,0),ISNULL(sys_PlanTemplateID,255),ISNULL(sys_Status,1),ISNULL(sys_IsQRCodeCard,0),sys_SetOrClear,sys_ReaderID,ISNULL(sys_IsOK,1),ISNULL(sys_ErrorRemark,''),sys_CreateTime 
				from BT_sys_UserDownloadRecord a WITH(NOLOCK) where sys_CreateTime<(select Max(sys_CreateTime) from BT_sys_UserDownloadRecord WITH(NOLOCK) where sys_UserCode=a.sys_UserCode and sys_CardID=a.sys_CardID and sys_ReaderID=a.sys_ReaderID and sys_SetOrClear=a.sys_SetOrClear) order by sys_UserCode,sys_CardID,sys_ReaderID
				Delete a From BT_sys_UserDownloadRecord a where sys_CreateTime<(select Max(sys_CreateTime) from BT_sys_UserDownloadRecord where sys_UserCode=a.sys_UserCode and sys_CardID=a.sys_CardID and sys_ReaderID=a.sys_ReaderID and sys_SetOrClear=a.sys_SetOrClear)
			end

			
		Set @Count=0
		Select @Count=count(1) from BT_sys_UserDownloadRecord WITH(NOLOCK) 
		if @Count>100000
			begin
				set @AutoDelDate=@TodayDate
				set @AutoDelDate=DATEADD(month,-1, @AutoDelDate) 
				insert into BT_sys_UserDownloadRecordBackup(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)
				select ISNULL(sys_UserID,0),ISNULL(sys_UserCode,''),sys_UserName,ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(sys_FCCellID,''),sys_CardID,ISNULL(sys_CardType,0),ISNULL(sys_DateStart,'2021-03-10'),ISNULL(sys_DateEnd,'2021-03-10'),ISNULL(sys_MaxSwipeTime,0),ISNULL(sys_PlanTemplateID,255),ISNULL(sys_Status,1),ISNULL(sys_IsQRCodeCard,0),sys_SetOrClear,sys_ReaderID,ISNULL(sys_IsOK,1),ISNULL(sys_ErrorRemark,''),sys_CreateTime 
				 from BT_sys_UserDownloadRecord where sys_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1 and col_DateEnd<@AutoDelDate) order by sys_ID 
				Delete From BT_sys_UserDownloadRecord where sys_CardID in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK) where col_Status<1 and col_DateEnd<@AutoDelDate) 				
				
				insert into BT_sys_UserDownloadRecordBackup(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)
				select ISNULL(sys_UserID,0),ISNULL(sys_UserCode,''),sys_UserName,ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(sys_FCCellID,''),sys_CardID,ISNULL(sys_CardType,0),ISNULL(sys_DateStart,'2021-03-10'),ISNULL(sys_DateEnd,'2021-03-10'),ISNULL(sys_MaxSwipeTime,0),ISNULL(sys_PlanTemplateID,255),ISNULL(sys_Status,1),ISNULL(sys_IsQRCodeCard,0),sys_SetOrClear,sys_ReaderID,ISNULL(sys_IsOK,1),ISNULL(sys_ErrorRemark,''),sys_CreateTime 
				 from BT_sys_UserDownloadRecord where sys_CardID not in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK))
				Delete From BT_sys_UserDownloadRecord where sys_CardID not in (select col_CardID from BT_col_UserInfoForReader WITH(NOLOCK)) 				
			end

		Set @Count=0
		Select @Count=count(1) from BT_sys_UserDownloadRecord WITH(NOLOCK) 
		if @Count>1000000
			begin
				set @AutoDelDate=DATEADD(month,-6, @TodayDate) 
				insert into BT_sys_UserDownloadRecordBackup(sys_UserID,sys_UserCode,sys_UserName,sys_UserType,sys_UserAddress,sys_FCCellID,sys_CardID,sys_CardType,sys_DateStart,sys_DateEnd,sys_MaxSwipeTime,sys_PlanTemplateID,sys_Status,sys_IsQRCodeCard,sys_SetOrClear,sys_ReaderID,sys_IsOK,sys_ErrorRemark,sys_CreateTime)
				select ISNULL(sys_UserID,0),ISNULL(sys_UserCode,''),sys_UserName,ISNULL(sys_UserType,0),ISNULL(sys_UserAddress,0),ISNULL(sys_FCCellID,''),sys_CardID,ISNULL(sys_CardType,0),ISNULL(sys_DateStart,'2021-03-10'),ISNULL(sys_DateEnd,'2021-03-10'),ISNULL(sys_MaxSwipeTime,0),ISNULL(sys_PlanTemplateID,255),ISNULL(sys_Status,1),ISNULL(sys_IsQRCodeCard,0),sys_SetOrClear,sys_ReaderID,ISNULL(sys_IsOK,1),ISNULL(sys_ErrorRemark,''),sys_CreateTime 
				from BT_sys_UserDownloadRecord  where sys_CreateTime<@AutoDelDate order by sys_ID 
				Delete From BT_sys_UserDownloadRecord where sys_CreateTime<@AutoDelDate  

				set @AutoDelDate=DATEADD(YEAR,-2, @AutoDelDate) 
				Delete From BT_sys_UserDownloadRecordBackup where sys_CreateTime<@AutoDelDate
			end
	end
	
	Set @Count=0
	Select @Count=count(1) from BT_sys_ReaderOnlineLog 
	if @Count>10000
		begin
			Delete From BT_sys_ReaderOnlineLog where sys_CreateTime<dateadd(month,-1,GetDate())
		end

	--Drop table #tmpForDisableCard
	--Drop table #t_col_UserInfoForReader
END
