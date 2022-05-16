
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'DeleteUserFCCellID') and xtype='P')  DROP PROCEDURE [dbo].[DeleteUserFCCellID]
GO



-- =============================================
-- Author:		<SAM>
-- Create date: <2019-03-14>
-- Description:	<删除业主房间> 
--Exec DeleteUserFCCellID 99,20
-- =============================================
CREATE PROCEDURE [dbo].[DeleteUserFCCellID] 
(
	@UserID int,
	@ZFID int
)
AS
BEGIN
	SET NOCOUNT ON; 
	   
Create Table #TempForReaderID
(
	ReaderID int
)
		Declare @num int,@sys_MemberID int,@lgidnew int
		Declare @UserCode nvarchar(20),@CellCode nvarchar(20),@CellID int,@lpid int,@lgid int,@Count int,@CardID nvarchar(125),@ZH_MembersCode nvarchar(20),@ZH_MembersID int
		Set @UserCode=''
		Set @CellCode='0'
		Set @CellID=0
		Set @lpid=0
		Set @lgid=0
		Set @Count=0
		Set @CardID=''
		Set @ZH_MembersCode=''
		Set @ZH_MembersID=0
		select @UserCode=CODE from ZH_Owner where ID=@UserID
		if @UserCode=''
			goto TheEnd

		select @CellID=CELLID from ZH_FC where ZFID=@ZFID
		if @CellID=0
			goto TheEnd
			
		select @CellCode=code from FC_Cell where cellid=@CellID
		select @lpid=lpid,@lgid=lgid from View_CellDetailInfo where cellid=@CellID
			
	
		Update BT_col_UserInfoForReader set col_FCCellID='0' where col_UserID=@UserID and col_FCCellID=@CellCode
		Update BT_col_UserInfoForReader set col_FCCellID='0' where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and col_FCCellID=@CellCode
		Update BT_col_CardManagement set col_FCCellID=0 where col_UserID in (select a.ID FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and col_FCCellID=@CellID

		--有多少人
		IF OBJECT_ID('tempdb.dbo.#TBMembersLP') IS NOT NULL DROP TABLE #TBMembersLP
		CREATE TABLE #TBMembersLP(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int
		)
		--插入数据，有多少人
		INSERT INTO #TBMembersLP(sys_MemberID)
		SELECT DISTINCT d.id as sys_MemberID from ZH_Members as d
		LEFT JOIN View_ZHFCLPInfo as a on a.OwnerID=d.ownerid 
		LEFT JOIN BT_col_UserInfoForReader as b on d.code=b.col_UserCode 
		WHERE d.ownerid=@UserID and a.OwnerCode is not null and b.col_CardID is not null and b.col_DateEnd>GetDate() and b.col_Status=1 AND b.col_IsUploadToReader<99

		--原有的对应的门禁权限
		IF OBJECT_ID('tempdb.dbo.#TBMembersLPOldDoorAccess') IS NOT NULL DROP TABLE #TBMembersLPOldDoorAccess
		CREATE TABLE #TBMembersLPOldDoorAccess(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int,
			sys_ReaderID			int
		)


		SET @num=1
		WHILE(EXISTS(SELECT 1 FROM #TBMembersLP WHERE number=@num))
			BEGIN
				SET @sys_MemberID=0
				SELECT @sys_MemberID=ISNULL(sys_MemberID,0) FROM #TBMembersLP WHERE number=@num

				--门组				
				INSERT INTO #TBMembersLPOldDoorAccess(sys_MemberID,sys_ReaderID)
				SELECT DISTINCT @sys_MemberID,a.AccessControlID FROM tb_DoorGroup_SettingUserID as a 
				LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
				WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
				and a.DoorID in ( 
				SELECT sys_ParentID FROM tb_LP_ReaderAccess_JTCY as a WHERE sys_FClgid=@lgid AND ISNULL(a.sys_ParentID,0)<>0 AND ISNULL(a.sys_ReaderID,0)=0
				)
				AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
				AND NOT EXISTS(SELECT 1 FROM #TBMembersLPOldDoorAccess as TL WHERE TL.sys_MemberID=@sys_MemberID AND TL.sys_ReaderID=a.AccessControlID )

				--门禁点
				INSERT INTO #TBMembersLPOldDoorAccess(sys_MemberID,sys_ReaderID)
				SELECT DISTINCT @sys_MemberID,HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
				and a.HostDeviceID in ( 
					SELECT sys_ReaderID FROM tb_LP_ReaderAccess_JTCY as a WHERE sys_FClgid=@lgid AND ISNULL(a.sys_ParentID,0)=0 AND ISNULL(a.sys_ReaderID,0)<>0
				)				
				AND NOT EXISTS(SELECT 1 FROM #TBMembersLPOldDoorAccess as TL WHERE TL.sys_MemberID=@sys_MemberID AND TL.sys_ReaderID=a.HostDeviceID )


				SET @num=@num+1
			END




		--排除原有房产后剩下的楼宇
		IF OBJECT_ID('tempdb.dbo.#TBMembersLPRemain') IS NOT NULL DROP TABLE #TBMembersLPRemain
		CREATE TABLE #TBMembersLPRemain(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int,
			lgid					int
		)

		--排除原有房产后剩下的楼宇对应的门禁权限
		IF OBJECT_ID('tempdb.dbo.#TBMembersLPRemainDoorAccess') IS NOT NULL DROP TABLE #TBMembersLPRemainDoorAccess
		CREATE TABLE #TBMembersLPRemainDoorAccess(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int,
			sys_ReaderID			int
		)

		INSERT INTO #TBMembersLPRemain(sys_MemberID,lgid)
		SELECT DISTINCT d.id as sys_MemberID,a.lgid from ZH_Members as d
		LEFT JOIN View_ZHFCLPInfo as a on a.OwnerID=d.ownerid 
		LEFT JOIN BT_col_UserInfoForReader as b on d.code=b.col_UserCode 
		WHERE d.ownerid=@UserID and a.OwnerCode is not null and b.col_CardID is not null and b.col_DateEnd>GetDate() and b.col_Status=1 AND b.col_IsUploadToReader<99
		AND isnull(a.cellid,0)<>@CellID

		SET @num=1
		WHILE(EXISTS(SELECT 1 FROM #TBMembersLPRemain WHERE number=@num))
			BEGIN
				SET @sys_MemberID=0
				SET @lgidnew=0

				SELECT @sys_MemberID=ISNULL(sys_MemberID,0),@lgidnew=ISNULL(lgid,0) FROM #TBMembersLPRemain WHERE number=@num
				--门组				
				INSERT INTO #TBMembersLPRemainDoorAccess(sys_MemberID,sys_ReaderID)
				SELECT DISTINCT @sys_MemberID,a.AccessControlID FROM tb_DoorGroup_SettingUserID as a 
				LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
				WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
				and a.DoorID in ( 
				SELECT sys_ParentID FROM tb_LP_ReaderAccess_JTCY as a WHERE sys_FClgid=@lgidnew AND ISNULL(a.sys_ParentID,0)<>0 AND ISNULL(a.sys_ReaderID,0)=0
				)
				AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
				AND NOT EXISTS(SELECT 1 FROM #TBMembersLPRemainDoorAccess as TL WHERE TL.sys_MemberID=@sys_MemberID AND TL.sys_ReaderID=a.AccessControlID )

				--门禁点
				INSERT INTO #TBMembersLPRemainDoorAccess(sys_MemberID,sys_ReaderID)
				SELECT DISTINCT @sys_MemberID,HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
				and a.HostDeviceID in ( 
					SELECT sys_ReaderID FROM tb_LP_ReaderAccess_JTCY as a WHERE sys_FClgid=@lgidnew AND ISNULL(a.sys_ParentID,0)=0 AND ISNULL(a.sys_ReaderID,0)<>0
				)				
				AND NOT EXISTS(SELECT 1 FROM #TBMembersLPRemainDoorAccess as TL WHERE TL.sys_MemberID=@sys_MemberID AND TL.sys_ReaderID=a.HostDeviceID )


				SET @num=@num+1
			END
			

		delete from ZH_FC where zfid=@ZFID 


		--删除，排除在其他楼宇重复的
		DELETE A FROM #TBMembersLPOldDoorAccess as A WHERE EXISTS (SELECT 1 FROM #TBMembersLPRemainDoorAccess as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID  )


		--select 'aaaaa',* from #TBMembersLPRemain

		--select 'bbbbb',* from #TBMembersLPOldDoorAccess

		--select 'ccccc',* from #TBMembersLPRemainDoorAccess


		--抄存储过程SaveUserReaderAccess
		--删除
		update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID in (SELECT sys_MemberID FROM #TBMembersLPOldDoorAccess)


		DELETE A FROM tb_DoorGroup_UserReaderAccess_JTCY as A WHERE EXISTS(SELECT 1 FROM #TBMembersLPOldDoorAccess as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID)

		--插入之前先删除之前插入的数据
		DELETE A FROM BT_col_AutoDownloadUserForReader as A,
		(
			SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBMembersLPOldDoorAccess as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		) as B
		WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
		from #TBMembersLPOldDoorAccess as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBMembersLPOldDoorAccess as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBMembersLPOldDoorAccess as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBMembersLPOldDoorAccess as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
		from #TBMembersLPOldDoorAccess as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)

		--最后删除
		DELETE A FROM BT_sys_UserReaderAccess as A,
		( 
			SELECT c.col_UserCode,B.* FROM #TBMembersLPOldDoorAccess as B
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=B.sys_MemberID
		) as B
		WHERE A.sys_UserCode=B.col_UserCode AND A.sys_ReaderID=B.sys_ReaderID

		DELETE A FROM BT_sys_UserReaderAccess_JTCY as A,#TBMembersLPOldDoorAccess as B
		WHERE A.sys_memberid=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID


		delete from BT_col_CardManagement_FCCELL 
		where cellid = @CellID and cardid in ( select col_id from BT_col_CardManagement where col_ownerid = @UserID)



		--Jason 20210427 注释，Nancy测试数据不对。现在改成只要业主在其他楼宇或其他房产楼宇也有这个门禁，就不删除这个门禁 Start

		--select col_UserID as UserID,col_CardID as CardID into #tmpForUserAndCard from BT_col_CardManagement where col_UserID in (select a.ID FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and col_FCCellID=@CellID

		--select @Count=1 from View_ZHFCLPInfo where OWNERID=@UserID and lgid=@lgid
		--if @Count=0
		--	begin
		--		Declare @PlanTemplateID int
		--		Set @PlanTemplateID=255
		--		Set @Count=0
		--		select @Count=1 from BT_sys_ReaderAccessForLP where sys_FClgid=@lgid
		--		if @Count=0
		--			begin
		--				Insert into #TempForReaderID
		--				select HostDeviceID from V_HostDeviceForSam WHERE IsCardMachine=0 and ly_id in (select a.lgid from FC_Lg as a left join BT_FC_Lg_Ext as b on a.lgid=b.lgid where b.is_xq_door=1 and a.sslpid=@lpid) 
 
		--				Insert into #TempForReaderID
		--				select HostDeviceID from V_HostDeviceForSam WHERE IsCardMachine=0 and ly_id=@lgid and HostDeviceID not in (select ReaderID from #TempForReaderID)

		--				Delete From #TempForReaderID Where ReaderID not in (select distinct sys_ReaderID from BT_sys_ReaderAccessForLP where sys_FClgid in (SELECT distinct lgid  FROM View_ZHFCLPInfo where ownerID=@UserID))
		--			end
		--		else
		--			begin
		--				Insert into #TempForReaderID
		--				select distinct sys_ReaderID from BT_sys_ReaderAccessForLP where sys_FClgid=@lgid and sys_ReaderID not in (select distinct sys_ReaderID from BT_sys_ReaderAccessForLP where sys_FClgid in (SELECT distinct lgid  FROM View_ZHFCLPInfo where ownerID=@UserID))
		--			end


		--		Delete BT_col_AutoDownloadUserForReader from BT_col_AutoDownloadUserForReader as a,(select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0)) as b where a.col_UserCode=b.col_UserCode and a.col_CardNo=b.col_CardID and a.col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and a.col_DeviceID in (select ReaderID from #TempForReaderID)
		--		Delete BT_col_AutoDownloadUserForReader from BT_col_AutoDownloadUserForReader as a,(select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and ISNULL(col_UserAddress,0)>0 and col_CardType>=12 and col_Status=1 and col_DateEnd>GetDate() AND col_IsUploadToReader<99) as b where a.col_UserAddress=b.col_UserAddress and a.col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and a.col_DeviceID in (select ReaderID from #TempForReaderID)
		--		--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime)
		--		--select distinct col_UserCode,col_CardID,sys_ReaderID,99,col_DateStart,col_DateEnd,0,GetDate() from (select * from BT_sys_UserReaderAccess where sys_UserCode=@UserCode and sys_ReaderID in (select ReaderID from #TempForReaderID)) as a inner join (select * from BT_col_UserInfoForReader where col_UserID=@UserID) as b on a.sys_UserCode=b.col_UserCode and a.sys_CardNo=b.col_CardID   
		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_sys_UserReaderAccess where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)) as a inner join (select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and col_CardType<11 AND col_IsUploadToReader<99) as b on a.sys_UserCode=b.col_UserCode and a.sys_CardNo=b.col_CardID 

		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_sys_UserReaderAccess where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)) as a inner join (select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and ISNULL(col_UserAddress,0)>0 and col_CardType>12 AND col_IsUploadToReader<99) as b on a.sys_UserCode=b.col_UserCode and a.sys_CardNo=b.col_CardID  Where ISNULL(b.col_UserAddress,0)>0 and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15)
		
		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_sys_UserReaderAccess where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)) as a inner join (select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and ISNULL(col_UserAddress,0)>0 and col_CardType=12 AND col_IsUploadToReader<99) as b on a.sys_UserCode=b.col_UserCode and a.sys_CardNo=b.col_CardID  Where ISNULL(b.col_UserAddress,0)>0 and sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and BrandID=15 and IsOctDevice='true')
		
		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from (select * from BT_sys_UserReaderAccess where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)) as a inner join (select * from BT_col_UserInfoForReader where col_UserCode in (select a.Code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and col_CardType=11 AND col_IsUploadToReader<99) as b on a.sys_UserCode=b.col_UserCode and a.sys_CardNo=b.col_CardID Where sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasQRCode='true')

		--		Delete from BT_sys_UserReaderAccess where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)
		--		Delete from BT_sys_UserReaderAccessOld where sys_UserCode in (select a.code FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)
		--		Delete from BT_sys_UserReaderAccess_JTCY where sys_MemberID in (select a.id FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)
		--		Delete from tb_DoorGroup_UserReaderAccess_JTCY where sys_MemberID in (select a.id FROM ZH_Members a left join ZH_Owner b on a.ownerid=b.id WHERE b.ID=@UserID and ISNULL(a.ID,0)>0) and sys_ReaderID in (select ReaderID from #TempForReaderID)
		--	end
		--else--要更新房间号的话就下载
		--	begin

		--		--Delete a from BT_col_AutoDownloadUserForReader a,#tmpForUserAndCard b where a.col_UserID=b.UserID and a.col_CardNo=b.CardID  --and col_Status=1
		--		Delete from BT_col_AutoDownloadUserForReader where col_CardNo in (select CardID from #tmpForUserAndCard)  --and col_Status=1
		--		Delete from BT_col_AutoDownloadUserForReader where col_UserAddress in (select col_UserAddress from BT_col_UserInfoForReader where col_CardID in (select CardID from #tmpForUserAndCard) and col_UserAddress>0 and col_CardType>=12)
		--		--insert into BT_col_AutoDownloadUserForReader(col_UserCode,col_CardNo,col_DeviceID,col_Status,col_DateStart,col_DateEnd,col_IsQRCodeCard,col_CreateTime) select col_UserCode,col_CardID,sys_ReaderID,1,col_DateStart,col_DateEnd,0,GetDate() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_UserCode=@UserCode
		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID in (select CardID from #tmpForUserAndCard) and a.col_CardType<11 and a.col_Status=1 and a.col_DateEnd>GetDate() AND a.col_IsUploadToReader<99 order by a.col_DateStart,a.col_UpdateTime

		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID in (select CardID from #tmpForUserAndCard) and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and a.col_Status=1 and a.col_DateEnd>GetDate() AND a.col_IsUploadToReader<99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime

		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID in (select CardID from #tmpForUserAndCard) and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and a.col_Status=1 and a.col_DateEnd>GetDate() AND a.col_IsUploadToReader<99 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime

		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo left join V_HostDeviceForSam c on b.sys_ReaderID=c.HostDeviceID  where a.col_CardID in (select CardID from #tmpForUserAndCard) and a.col_CardType=11 and a.col_Status=1 and a.col_DateEnd>GetDate() AND a.col_IsUploadToReader<99 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime

		--		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		--		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),ISNULL(col_Status,1),sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,GETDATE()),dateadd(second,1,GETDATE()) from BT_col_UserInfoForReader as a inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo where a.col_CardID in (select CardID from #tmpForUserAndCard) and a.col_UserType=0 and a.col_CardType<12 and a.col_Status=1 and a.col_DateEnd>GetDate() AND a.col_IsUploadToReader<99 and a.col_IfHadFace=1 and b.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15) order by a.col_DateStart,a.col_UpdateTime

		--	end



        --drop table #tmpForUserAndCard

		--Jason 20210427 注释，Nancy测试数据不对。现在改成只要业主在其他楼宇或其他房产楼宇也有这个门禁，就不删除这个门禁 End

TheEnd:
Select 1
return 0

   
END
