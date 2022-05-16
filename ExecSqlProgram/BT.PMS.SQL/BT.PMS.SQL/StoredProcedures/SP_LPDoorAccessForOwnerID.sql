

IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_LPDoorAccessForOwnerID') and xtype='P')  DROP PROCEDURE [dbo].[SP_LPDoorAccessForOwnerID]
GO



-- exec SP_LPDoorAccessForOwnerID 1499,''

-- Author:		<Jason>
-- Create date: <2021-04-20>
-- Description:	<给新增的房产所有家庭成员赋予新增房产的权限> 

CREATE Proc [dbo].[SP_LPDoorAccessForOwnerID]
(
	@ownerid		int,
	@lgid			int
)
as 
BEGIN TRY



		--获取楼宇人员
		IF OBJECT_ID('tempdb.dbo.#TBMembersLP') IS NOT NULL DROP TABLE #TBMembersLP
		CREATE TABLE #TBMembersLP(
			number					[int] IDENTITY(1,1) NOT NULL,
			sys_MemberID			int
		)
		--插入数据
		INSERT INTO #TBMembersLP(sys_MemberID)
		SELECT DISTINCT d.id as sys_MemberID from ZH_Members as d
		LEFT JOIN BT_col_UserInfoForReader as b on d.code=b.col_UserCode 
		WHERE d.ownerid=@ownerid and b.col_CardID is not null and b.col_DateEnd>GetDate() and b.col_Status=1 AND b.col_IsUploadToReader<99

		DECLARE @num int,@sys_MemberID int,@sys_ParentID int,@numreaderid int,@sys_ReaderID int
		IF(ISNULL(@lgid,0)>0)
			BEGIN
						
				--先获取门组存在，新表#TBMemberIDDoorGroup存在而表tb_DoorGroup_UserReaderAccess_JTCY不存在的数据
				IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsert') IS NOT NULL DROP TABLE #TBDoorGroupInsert
				CREATE TABLE #TBDoorGroupInsert(
					number					[int] IDENTITY(1,1) NOT NULL,
					sys_ReaderID			int
				)

				--获取已插入的门组对应的楼宇人员
				IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsertMembers') IS NOT NULL DROP TABLE #TBDoorGroupInsertMembers
				CREATE TABLE #TBDoorGroupInsertMembers(
					number					[int] IDENTITY(1,1) NOT NULL,			
					sys_MemberID			int,		
					sys_ReaderID			int
				)

				--插入，对应的是门禁组
				INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT DISTINCT AccessControlID FROM tb_DoorGroup_SettingUserID as a 
				LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
				WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
				and a.DoorID in ( 
					SELECT sys_ParentID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)<>0 AND ISNULL(sys_ReaderID,0)=0
				)
				AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0

				SELECT Row_number() over(order by A.sys_ParentID asc) RID ,A.sys_ParentID as ParentID Into #TempData_AccessControlAdd 
				FROM tb_LP_ReaderAccess_JTCY as A 
				LEFT JOIN tb_DoorGrup as b on b.ID=a.sys_ParentID
				WHERE A.sys_FClgid=@lgid AND ISNULL(A.sys_ParentID,0)<>0 AND ISNULL(sys_ReaderID,0)=0 
				AND ISNULL(b.ID,0)>0 AND ISNULL(b.IsDelete,0)=0
						
				--插入，对应的是门禁点
				INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT DISTINCT HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
				and a.HostDeviceID in ( 
					SELECT sys_ReaderID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)=0 AND ISNULL(sys_ReaderID,0)<>0
				)
				AND NOT EXISTS(SELECT 1 FROM #TBDoorGroupInsert as B WHERE B.sys_ReaderID=a.HostDeviceID)

				SELECT Row_number() over(order by HostDeviceID asc) RID ,HostDeviceID as ReaderID Into #TempData_AccessControlAddAccess FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
				and a.HostDeviceID in ( 
					SELECT sys_ReaderID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)=0 AND ISNULL(sys_ReaderID,0)<>0
				)


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
			IF(EXISTS(SELECT 1 FROM #TBMembersLP) )
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
							INSERT INTO #TBReader(sys_ReaderID) SELECT DISTINCT AccessControlID FROM tb_DoorGroup_SettingUserID as a 
							LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
							WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0 AND a.DoorID=@sys_ParentID	 	
							AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0

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
			IF(EXISTS(SELECT 1 FROM #TBMembersLP) )
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








			END







	SELECT 1  
END TRY
BEGIN CATCH
	SELECT 0
END CATCH