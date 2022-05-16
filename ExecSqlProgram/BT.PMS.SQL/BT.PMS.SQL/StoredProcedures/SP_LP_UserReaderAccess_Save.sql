

IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_LP_UserReaderAccess_Save') and xtype='P')  DROP PROCEDURE [dbo].[SP_LP_UserReaderAccess_Save]
GO

-- exec SP_LP_UserReaderAccess_Save 1,'','41'

-- Author:		<Jason>
-- Create date: <2021-04-09>
-- Description:	<修改楼宇门禁组、门禁点权限> 

CREATE Proc [dbo].[SP_LP_UserReaderAccess_Save]
(
	@lgid				int,
	@doorids			nvarchar(max), --门禁组
	@readerids			nvarchar(max)
)
as 
BEGIN TRY

		
		DECLARE @num int,@sys_MemberID int,@sys_ParentID int,@numreaderid int,@sys_ReaderID int


		DELETE FROM BT_sys_ReaderAccessForLP WHERE sys_FClgid=@lgid

		--门禁组 Start
		--获取员工保存之前的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupOld') IS NOT NULL DROP TABLE #TBDoorGroupOld
		CREATE TABLE #TBDoorGroupOld(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int
		)

		INSERT INTO #TBDoorGroupOld(sys_ParentID) SELECT ISNULL(sys_ParentID,0) FROM tb_LP_ReaderAccess_JTCY as a
		LEFT JOIN tb_DoorGrup as b on b.ID=a.sys_ParentID
		where a.sys_FClgid=@lgid and isnull(a.sys_ReaderID,0)=0
		AND ISNULL(b.ID,0)>0 AND ISNULL(b.IsDelete,0)=0

		DELETE FROM tb_LP_ReaderAccess_JTCY where sys_FClgid=@lgid and isnull(sys_ParentID,0)<>0


		SELECT Row_number() over(order by ParentID asc) RID ,ParentID Into #TempData_AccessControlAdd FROM(
			SELECT Convert(int,COL) ParentID  from fn_split_ToTable(@doorids,',')
		) as h

		DELETE FROM #TempData_AccessControlAdd WHERE ISNULL(ParentID,0)=0

		--select '' as #TempData_AccessControlAdd,* from #TempData_AccessControlAdd

		--select 'aaaaa',* from #TempData_AccessControlAdd

		INSERT INTO tb_LP_ReaderAccess_JTCY(sys_FClgid,sys_ParentID,sys_ReaderID,sys_PlanTemplateID)
		SELECT @lgid as sys_FClgid,ParentID,0 as sys_ReaderID,255 as sys_PlanTemplateID FROM #TempData_AccessControlAdd


		--获取员工保存之后的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupNew') IS NOT NULL DROP TABLE #TBDoorGroupNew
		CREATE TABLE #TBDoorGroupNew(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int
		)

		INSERT INTO #TBDoorGroupNew(sys_ParentID) SELECT ParentID FROM #TempData_AccessControlAdd
		--select '' as 门禁组,* from #TBDoorGroupNew
		--门禁组 End


		--门禁点 Start
		--获取员工保存之前的门禁点
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupOldAccess') IS NOT NULL DROP TABLE #TBDoorGroupOldAccess
		CREATE TABLE #TBDoorGroupOldAccess(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ReaderID			int
		)

		INSERT INTO #TBDoorGroupOldAccess(sys_ReaderID) SELECT ISNULL(a.sys_ReaderID,0) FROM tb_LP_ReaderAccess_JTCY as a 
		LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.sys_ReaderID
		where a.sys_FClgid=@lgid and ISNULL(a.sys_ParentID,0)=0 and isnull(a.sys_ReaderID,0)<>0
		AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
		

		DELETE FROM tb_LP_ReaderAccess_JTCY where sys_FClgid=@lgid and ISNULL(sys_ParentID,0)=0 and isnull(sys_ReaderID,0)<>0


		SELECT Row_number() over(order by ReaderID asc) RID ,ReaderID Into #TempData_AccessControlAddAccess FROM(
			SELECT Convert(int,COL) ReaderID  from fn_split_ToTable(@readerids,',')
		) as h
		

		DELETE FROM #TempData_AccessControlAddAccess WHERE ISNULL(ReaderID,0)=0

		INSERT INTO tb_LP_ReaderAccess_JTCY(sys_FClgid,sys_ParentID,sys_ReaderID,sys_PlanTemplateID)
		SELECT @lgid as sys_FClgid,0 as sys_ParentID,ReaderID,255 as sys_PlanTemplateID FROM #TempData_AccessControlAddAccess


		
		INSERT INTO BT_sys_ReaderAccessForLP(sys_FClgid,sys_ReaderID,sys_PlanTemplateID)
		SELECT @lgid as sys_FClgid,ReaderID,255 as sys_PlanTemplateID FROM #TempData_AccessControlAddAccess

		--select '' as BT_sys_ReaderAccessForLP, * from #TempData_AccessControlAddAccess

		--获取员工保存之后的门禁点
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupNewAccess') IS NOT NULL DROP TABLE #TBDoorGroupNewAccess
		CREATE TABLE #TBDoorGroupNewAccess(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ReaderID			int
		)

		INSERT INTO #TBDoorGroupNewAccess(sys_ReaderID) SELECT ReaderID FROM #TempData_AccessControlAddAccess
		--select '' as 门禁点,* from #TBDoorGroupNewAccess
		--门禁点 End




		--加这个是为了防止先在【卡号信息】加了门组，之后在【门组管理】去掉某个门禁点，要删除而删除不了
		--INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
		--SELECT  @lgid as sys_MemberID,DoorID as sys_ParentID,AccessControlID as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
		--FROM tb_DoorGroup_SettingUserID as a WHERE ISNULL(a.IsDelete,0)=0 AND isnull(a.AccessControlID,0)<>0 AND a.DoorID in (SELECT ParentID FROM #TempData_AccessControlAdd)
		--AND not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=@lgid AND B.sys_ParentID=A.DoorID AND B.sys_ReaderID=A.AccessControlID ) 






		--获取楼宇人员
		IF OBJECT_ID('tempdb.dbo.#TBMembersLP') IS NOT NULL DROP TABLE #TBMembersLP
		CREATE TABLE #TBMembersLP(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int
		)
		--插入数据
		INSERT INTO #TBMembersLP(sys_MemberID)
		SELECT DISTINCT d.id as sys_MemberID from ZH_Members as d
		LEFT JOIN View_ZHFCLPInfo as a on a.OwnerID=d.ownerid 
		LEFT JOIN BT_col_UserInfoForReader as b on d.code=b.col_UserCode 
		WHERE a.lgid=@lgid and a.OwnerCode is not null and b.col_CardID is not null and b.col_DateEnd>GetDate() and b.col_Status=1 AND b.col_IsUploadToReader<99
		--AND d.id=1731


		--获取已删除的门组
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupDel') IS NOT NULL DROP TABLE #TBDoorGroupDel
		CREATE TABLE #TBDoorGroupDel(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int,			
			sys_ReaderID			int
		)

		--获取已删除的门组对应的楼宇人员
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupDelMembers') IS NOT NULL DROP TABLE #TBDoorGroupDelMembers
		CREATE TABLE #TBDoorGroupDelMembers(
			number					[int] IDENTITY(1,1) NOT NULL,			
			sys_MemberID			int,		
			sys_ReaderID			int
		)

		--这是删除之前已经存在的员工门禁数据，用于对比
		--门组下对应的员工之前的门禁权限
		IF OBJECT_ID('tempdb.dbo.#TBAccessMembersCompare') IS NOT NULL DROP TABLE #TBAccessMembersCompare
		CREATE TABLE #TBAccessMembersCompare(
			number					[int] IDENTITY(1,1) NOT NULL,			
			sys_MemberID			int,		
			sys_ReaderID			int
		)

		--要插入的插入
		--先获取门组存在，新表#TBMemberIDDoorGroup存在而表tb_DoorGroup_UserReaderAccess_JTCY不存在的数据
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsert') IS NOT NULL DROP TABLE #TBDoorGroupInsert
		CREATE TABLE #TBDoorGroupInsert(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_ParentID			int,
			sys_ReaderID			int
		)
		--获取已插入的门组对应的楼宇人员
		IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsertMembers') IS NOT NULL DROP TABLE #TBDoorGroupInsertMembers
		CREATE TABLE #TBDoorGroupInsertMembers(
			number					[int] IDENTITY(1,1) NOT NULL,			
			sys_MemberID			int,		
			sys_ReaderID			int
		)

		
		--删除，对应的是门禁组
		--select * from #TBDoorGroupOld
		INSERT INTO #TBDoorGroupDel(sys_ReaderID) SELECT DISTINCT a.AccessControlID FROM tb_DoorGroup_SettingUserID as a 
		LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
		WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
		and a.DoorID in ( 
		SELECT sys_ParentID FROM #TBDoorGroupOld WHERE sys_ParentID not in (SELECT sys_ParentID FROM #TBDoorGroupNew )
		)
		AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
		AND A.AccessControlID not in (SELECT T.sys_ReaderID FROM tb_LP_ReaderAccess_JTCY as T WHERE T.sys_FClgid=@lgid AND ISNULL(T.sys_ParentID,0)=0 AND ISNULL(T.sys_ReaderID,0)<>0 )


		--插入，对应的是门禁组
		INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT a.AccessControlID FROM tb_DoorGroup_SettingUserID as a 
		LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
		WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
		and a.DoorID in ( 
			SELECT sys_ParentID FROM #TBDoorGroupNew --WHERE sys_ParentID not in (SELECT sys_ParentID FROM #TBDoorGroupOld )
		)
		AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
		

		--select '' as #TBDoorGroupInsert1,* from #TBDoorGroupInsert


		--select '' as #TBDoorGroupNew1,* from #TBDoorGroupNew

		--删除，对应的是门禁点
		--select * from #TBDoorGroupOld
		INSERT INTO #TBDoorGroupDel(sys_ReaderID) SELECT DISTINCT HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0
		and a.HostDeviceID in ( 
		SELECT sys_ReaderID FROM #TBDoorGroupOldAccess --WHERE sys_ReaderID not in (SELECT sys_ReaderID FROM #TBDoorGroupNewAccess )
		)
		AND NOT EXISTS(SELECT 1 FROM #TBDoorGroupDel as B WHERE B.sys_ReaderID=a.HostDeviceID)

		--插入，对应的是门禁点
		INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT DISTINCT HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
		and a.HostDeviceID in ( 
			SELECT sys_ReaderID FROM #TBDoorGroupNewAccess --WHERE sys_ReaderID not in (SELECT sys_ReaderID FROM #TBDoorGroupOldAccess )
		)
		AND NOT EXISTS(SELECT 1 FROM #TBDoorGroupInsert as B WHERE B.sys_ReaderID=a.HostDeviceID)

		--select '' as #TBDoorGroupNewAccess,* from #TBDoorGroupNewAccess


		--select '' as #TBDoorGroupInsert,* from #TBDoorGroupInsert
		--
		INSERT INTO BT_sys_ReaderAccessForLP(sys_FClgid,sys_ReaderID,sys_PlanTemplateID)
		SELECT @lgid as sys_FClgid,sys_ReaderID,255 as sys_PlanTemplateID FROM #TBDoorGroupInsert as A
		WHERE 1=1 AND NOT EXISTS(SELECT 1 FROM BT_sys_ReaderAccessForLP as B WHERE B.sys_FClgid=@lgid AND B.sys_ReaderID=A.sys_ReaderID )
		


		IF(EXISTS(SELECT 1 FROM #TBMembersLP))
			BEGIN

				--删除
				SET @num=1
				WHILE(EXISTS(SELECT 1 FROM #TBDoorGroupDel WHERE number=@num))
					BEGIN

						INSERT INTO #TBDoorGroupDelMembers(sys_MemberID,sys_ReaderID)

						SELECT sys_MemberID,sys_ReaderID FROM (
						SELECT DISTINCT a.sys_MemberID,b.sys_ReaderID from #TBMembersLP as a,
						(SELECT * FROM #TBDoorGroupDel where number=@num) as b
						) as D WHERE NOT EXISTS(SELECT 1 FROM #TBDoorGroupDelMembers as TB WHERE TB.sys_MemberID=D.sys_MemberID AND TB.sys_ReaderID=D.sys_ReaderID )
				
						SET @num=@num+1
					END
					
				--插入
				SET @num=1
				WHILE(EXISTS(SELECT 1 FROM #TBDoorGroupInsert WHERE number=@num))
					BEGIN

						INSERT INTO #TBDoorGroupInsertMembers(sys_MemberID,sys_ReaderID)

						SELECT sys_MemberID,sys_ReaderID FROM (
						SELECT DISTINCT a.sys_MemberID,b.sys_ReaderID from #TBMembersLP as a,
						(SELECT * FROM #TBDoorGroupInsert where number=@num) as b
						) as D WHERE NOT EXISTS(SELECT 1 FROM #TBDoorGroupInsertMembers as TB WHERE TB.sys_MemberID=D.sys_MemberID AND TB.sys_ReaderID=D.sys_ReaderID )
				
						SET @num=@num+1
					END

				--这是删除之前已经存在的员工门禁数据，用于对比
				SET @num=1
				WHILE(EXISTS(SELECT 1 FROM #TBMembersLP WHERE number=@num))
					BEGIN

						SET @sys_MemberID=0
						SELECT @sys_MemberID=ISNULL(sys_MemberID,0) FROM #TBMembersLP WHERE number=@num

						--门禁组
						INSERT INTO #TBAccessMembersCompare(sys_MemberID,sys_ReaderID)
							SELECT sys_MemberID,sys_ReaderID FROM (		
							SELECT DISTINCT @sys_MemberID as sys_MemberID,a.AccessControlID as sys_ReaderID 
							FROM tb_DoorGroup_SettingUserID as a 
							LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
							WHERE ISNULL(a.AccessControlID,0)<>0 AND ISNULL(a.IsDelete,0)=0 AND a.DoorID in (
							SELECT sys_ParentID FROM tb_DoorGroup_UserReaderAccess_JTCY where sys_MemberID=@sys_MemberID AND ISNULL(sys_ParentID,0)<>0 AND ISNULL(sys_ReaderID,0)=0 
							)
							AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0

						) as D WHERE NOT EXISTS(SELECT 1 FROM #TBAccessMembersCompare as TB WHERE TB.sys_MemberID=D.sys_MemberID AND TB.sys_ReaderID=D.sys_ReaderID )

						--门禁点
						INSERT INTO #TBAccessMembersCompare(sys_MemberID,sys_ReaderID)
							SELECT sys_MemberID,sys_ReaderID FROM (
							SELECT DISTINCT @sys_MemberID as sys_MemberID,a.sys_ReaderID FROM tb_DoorGroup_UserReaderAccess_JTCY as a
							LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.sys_ReaderID
							where sys_MemberID=@sys_MemberID AND ISNULL(a.sys_ParentID,0)=0 AND ISNULL(a.sys_ReaderID,0)<>0 
							AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
						) as D WHERE NOT EXISTS(SELECT 1 FROM #TBAccessMembersCompare as TB WHERE TB.sys_MemberID=D.sys_MemberID AND TB.sys_ReaderID=D.sys_ReaderID )


						SET @num=@num+1
					END

			END

		--select '1111',* from #TBDoorGroupDelMembers where sys_MemberID=1851

		--存在的也删除掉
		DELETE A FROM #TBDoorGroupDelMembers as A WHERE EXISTS (SELECT 1 FROM #TBDoorGroupInsertMembers as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID  )

		

		--可能没有设置权限的就去掉
		DELETE A FROM #TBDoorGroupDelMembers as A WHERE NOT EXISTS (SELECT 1 FROM #TBAccessMembersCompare as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID  )

		--DELETE A FROM #TBDoorGroupDelMembers as A WHERE NOT EXISTS (SELECT 1 FROM #TBAccessMembersCompare as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID  )

		INSERT INTO #TBDoorGroupDelMembers(sys_MemberID,sys_ReaderID)
		SELECT sys_MemberID,sys_ReaderID FROM (
		SELECT sys_MemberID,sys_ReaderID FROM #TBAccessMembersCompare as A WHERE NOT EXISTS (SELECT 1 FROM #TBDoorGroupInsertMembers as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID  )
		) as AAA WHERE NOT EXISTS (SELECT 1 FROM #TBDoorGroupDelMembers as B WHERE B.sys_MemberID=AAA.sys_MemberID AND B.sys_ReaderID=AAA.sys_ReaderID  )




		
		--select '2222',* from #TBDoorGroupDelMembers where sys_MemberID=1851

		--select '3333',* from #TBDoorGroupInsertMembers where sys_MemberID=1851

		--select '5555',* from #TBAccessMembersCompare where sys_MemberID=1851

		--楼宇下的员工门组全部删除
		DELETE A FROM tb_DoorGroup_UserReaderAccess_JTCY as A
		WHERE A.sys_MemberID in (SELECT sys_MemberID FROM #TBDoorGroupDelMembers)






		--抄存储过程SaveUserReaderAccess
		--删除
		update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID in (SELECT sys_MemberID FROM #TBDoorGroupDelMembers)



		--插入之前先删除之前插入的数据
		DELETE A FROM BT_col_AutoDownloadUserForReader as A,
		(
			SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupDelMembers as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		) as B
		WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
		from #TBDoorGroupDelMembers as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDelMembers as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDelMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupDelMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,99,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
		from #TBDoorGroupDelMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)

		--最后删除
		DELETE A FROM BT_sys_UserReaderAccess as A,
		( 
			SELECT c.col_UserCode,B.* FROM #TBDoorGroupDelMembers as B
			LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=B.sys_MemberID
		) as B
		WHERE A.sys_UserCode=B.col_UserCode AND A.sys_ReaderID=B.sys_ReaderID

		DELETE A FROM BT_sys_UserReaderAccess_JTCY as A,#TBDoorGroupDelMembers as B
		WHERE A.sys_memberid=B.sys_MemberID AND A.sys_ReaderID=B.sys_ReaderID
		


		--要插入的插入

		--插入
		update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID in(SELECT sys_MemberID FROM #TBDoorGroupInsertMembers)


		--插入之前先删除之前插入的数据
		DELETE A FROM BT_col_AutoDownloadUserForReader as A,
		(
			SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupInsertMembers as d
			left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		) as B
		WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
		from #TBDoorGroupInsertMembers as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsertMembers as d 
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsertMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
		from #TBDoorGroupInsertMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID 
		left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


		INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
		SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
		ISNULL(col_Status,1) as col_Status ,sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
		from #TBDoorGroupInsertMembers as d
		left join BT_col_UserInfoForReader as a on a.col_UserID=d.sys_MemberID
		where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
		

		insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange)
		SELECT col_UserCode,col_CardID,A.sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
		FROM #TBDoorGroupInsertMembers as A
		LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=A.sys_MemberID
		WHERE ISNULL(c.col_UserCode,'')<>'' AND NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess as B WHERE B.sys_UserCode=c.col_UserCode AND B.sys_ReaderID=A.sys_ReaderID AND B.sys_CardNo=c.col_CardID )

		insert into BT_sys_UserReaderAccess_JTCY(sys_memberid,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange) 
		SELECT A.sys_MemberID as sys_MemberID,sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
		FROM #TBDoorGroupInsertMembers as A
		WHERE NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=A.sys_ReaderID )




		--批量插入表，门禁组
		IF(ISNULL(@doorids,'')<>'' AND EXISTS(SELECT 1 FROM #TBMembersLP) )
			BEGIN

				IF OBJECT_ID('tempdb.dbo.#TBReader') IS NOT NULL DROP TABLE #TBReader
				CREATE TABLE #TBReader(
					number					[int] IDENTITY(1,1) NOT NULL,
					sys_ReaderID			int
				)

				SET @num=1
				WHILE(EXISTS(SELECT 1 FROM #TempData_AccessControlAdd WHERE RID=@num))
					BEGIN						
						
						SET @sys_ParentID=0
						SELECT @sys_ParentID=ISNULL(ParentID,0) FROM #TempData_AccessControlAdd WHERE RID=@num

						INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
						SELECT sys_MemberID,@sys_ParentID,0 as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBMembersLP as A
						WHERE not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=@sys_ParentID AND B.sys_ReaderID=0 ) 

						TRUNCATE TABLE #TBReader
						INSERT INTO #TBReader(sys_ReaderID) SELECT DISTINCT AccessControlID FROM tb_DoorGroup_SettingUserID as a WHERE ISNULL(IsDelete,0)=0 AND ISNULL(AccessControlID,0)<>0 AND DoorID=@sys_ParentID	 	
					
						SET @numreaderid=1

						WHILE(EXISTS(SELECT 1 FROM #TBReader WHERE number=@numreaderid ))
							BEGIN
								SET @sys_ReaderID=0
								SELECT @sys_ReaderID=ISNULL(sys_ReaderID,0) FROM #TBReader WHERE number=@numreaderid

								--加这个是为了防止先在【卡号信息】加了门组，之后在【门组管理】去掉某个门禁点，要删除而删除不了
								INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
								SELECT sys_MemberID,@sys_ParentID,@sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBMembersLP as A
								WHERE not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=A.sys_MemberID AND B.sys_ParentID=@sys_ParentID AND B.sys_ReaderID=@sys_ReaderID ) 
								

								SET @numreaderid=@numreaderid+1
							END
						
						
						SET @num=@num+1

					END

			END


		--批量插入表，门禁点
		IF(ISNULL(@readerids,'')<>'' AND EXISTS(SELECT 1 FROM #TBMembersLP) )
			BEGIN

				SET @num=1
				WHILE(EXISTS(SELECT 1 FROM #TempData_AccessControlAddAccess WHERE RID=@num))
					BEGIN						
						
						SET @sys_ReaderID=0
						SELECT @sys_ReaderID=ISNULL(ReaderID,0) FROM #TempData_AccessControlAddAccess WHERE RID=@num

						INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
						SELECT sys_MemberID,0 as sys_ParentID,@sys_ReaderID as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBMembersLP as A
						WHERE not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=A.sys_MemberID AND B.sys_ReaderID=@sys_ReaderID AND ISNULL(B.sys_ParentID,0)=0 ) 

						
						
						SET @num=@num+1

					END
			END




	SELECT 1  
END TRY
BEGIN CATCH
	SELECT 0
END CATCH