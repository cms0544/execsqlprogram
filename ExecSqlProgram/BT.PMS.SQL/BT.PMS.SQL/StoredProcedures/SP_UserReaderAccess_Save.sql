

IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_UserReaderAccess_Save') and xtype='P')  DROP PROCEDURE [dbo].[SP_UserReaderAccess_Save]
GO



-- exec SP_UserReaderAccess_Save 1499,''

-- Author:		<Jason>
-- Create date: <2021-04-20>
-- Description:	<修改卡号门禁组权限> 

CREATE Proc [dbo].[SP_UserReaderAccess_Save]
(
	@memberid		int
)
as 
BEGIN TRY


		--没有操作过，并且没有指派过门禁权限，则自动赋予楼宇门禁权限
		IF(NOT EXISTS(SELECT 1 FROM BT_IsExistsUserReaderAccess WHERE sys_MemberID=@memberid) AND NOT EXISTS(SELECT 1 FROM tb_DoorGroup_UserReaderAccess_JTCY WHERE sys_MemberID=@memberid) )
			BEGIN

				DECLARE @number int, @lgid int --所在楼宇ID

				SELECT TOP 1 @lgid=ISNULL(a.lgid,0) FROM View_ZHFCLPInfo as a
				LEFT JOIN ZH_Members as d on d.ownerid =a.OwnerID
				WHERE d.id=@memberid

			--先获取门组存在，新表#TBMemberIDDoorGroup存在而表tb_DoorGroup_UserReaderAccess_JTCY不存在的数据
				IF OBJECT_ID('tempdb.dbo.#TBDoorGroupInsert') IS NOT NULL DROP TABLE #TBDoorGroupInsert
				CREATE TABLE #TBDoorGroupInsert(
					number					[int] IDENTITY(1,1) NOT NULL,
					sys_ReaderID			int
				)

				--获取员工所在的楼宇ID，可能有多个
				IF OBJECT_ID('tempdb.dbo.#TBLGID') IS NOT NULL DROP TABLE #TBLGID
				CREATE TABLE #TBLGID(
					number			[int] IDENTITY(1,1) NOT NULL,
					lgid			int
				)

				INSERT INTO #TBLGID(lgid) 
				SELECT DISTINCT ISNULL(a.lgid,0) FROM View_ZHFCLPInfo as a
				LEFT JOIN ZH_Members as d on d.ownerid =a.OwnerID
				WHERE d.id=@memberid AND ISNULL(a.lgid,0)>0

				SET @number=1

				WHILE(EXISTS(SELECT 1 FROM #TBLGID WHERE number=@number))
					BEGIN
						SET @lgid=0

						SELECT @lgid=ISNULL(lgid,0) FROM #TBLGID WHERE number=@number

						TRUNCATE TABLE #TBDoorGroupInsert


						--插入，对应的是门禁组
						INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT DISTINCT AccessControlID FROM tb_DoorGroup_SettingUserID as a 
						LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.AccessControlID
						WHERE ISNULL(a.IsDelete,0)=0 AND ISNULL(a.AccessControlID,0)<>0		
						and a.DoorID in ( 
							SELECT sys_ParentID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)<>0 AND ISNULL(sys_ReaderID,0)=0
						)
						AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0

						--插入，对应的是门禁点
						INSERT INTO #TBDoorGroupInsert(sys_ReaderID) SELECT DISTINCT HostDeviceID FROM BT_HostDevice as a WHERE ISNULL(Deleted,0)=0 AND ISNULL(HostDeviceID,0)<>0			
						and a.HostDeviceID in ( 
							SELECT sys_ReaderID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)=0 AND ISNULL(sys_ReaderID,0)<>0
						)
						AND NOT EXISTS(SELECT 1 FROM #TBDoorGroupInsert as B WHERE B.sys_ReaderID=a.HostDeviceID)



						--插入
						update BT_col_UserInfoForReader set col_IsUploadToReader=0,col_UploadTime=NULL,col_SwipeTime=0,col_UpdateTime=GetDate() where col_UserID=@memberid


						--插入之前先删除之前插入的数据
						DELETE A FROM BT_col_AutoDownloadUserForReader as A,
						(
							SELECT col_UserID,col_UserCode,d.sys_ReaderID FROM #TBDoorGroupInsert as d
							left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
						) as B
						WHERE 1=1 AND A.col_UserID=B.col_UserID AND A.col_UserCode=B.col_UserCode AND A.col_DeviceID=B.sys_ReaderID

						INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
						SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
						ISNULL(col_Status,1) as col_Status,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,GETDATE(),GETDATE() 
						from #TBDoorGroupInsert as d 
						left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
						--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
						where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType<11 order by a.col_DateStart,a.col_UpdateTime
		
				
						INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
						SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
						ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
						from #TBDoorGroupInsert as d 
						left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid 
						--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
						where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType>12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15) order by a.col_DateStart,a.col_UpdateTime
		

						INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
						SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
						ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
						from #TBDoorGroupInsert as d
						left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
						--inner join BT_sys_UserReaderAccess as b on a.col_UserCode=b.sys_UserCode and a.col_CardID=b.sys_CardNo 
						where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and ISNULL(a.col_UserAddress,0)>0 and a.col_CardType=12 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and brandID=15 and IsOctDevice='true') order by a.col_DateStart,a.col_UpdateTime


						INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
						SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
						ISNULL(col_Status,1) as col_Status ,sys_ReaderID,1,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,case when col_DateStart>GetDate() and ISNULL(brandID,0)=15 and datepart(hour,col_DateStart)>0 AND datepart(MINUTE,getdate())>0 then col_DateStart else GetDate() end,GETDATE() 
						from #TBDoorGroupInsert as d
						left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid 
						left join V_HostDeviceForSam c on d.sys_ReaderID=c.HostDeviceID 
						where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_CardType=11 and c.IsCardMachine=0 and c.HasQRCode='true' order by a.col_DateStart,a.col_UpdateTime


						INSERT INTO BT_col_AutoDownloadUserForReader(col_UserID,col_UserCode,col_UserName,col_UserType,col_UserAddress,col_FCCellID,col_CardNo,col_CardType,col_DateStart,col_DateEnd,col_MaxSwipeTime,col_PlanTemplateID,col_Enabled,col_DeviceID,col_Status,col_IsQRCodeCard,col_DownloadLevel,col_RunCount,col_UpdateTime,col_CreateTime) 
						SELECT col_UserID,col_UserCode,col_UserName,ISNULL(col_UserType,0),ISNULL(col_UserAddress,0),ISNULL(col_FCCellID,'0'),col_CardID,ISNULL(col_CardType,0),col_DateStart,col_DateEnd,ISNULL(col_MaxSwipeTime,0),ISNULL(col_PlanTemplateID,255),
						ISNULL(col_Status,1) as col_Status ,sys_ReaderID,2,case when ISNULL(col_UserType,0)=1 and ISNULL(col_CardType,0)=11 then 1 else 0 end,1,0,dateadd(second,1,col_DateStart),dateadd(second,1,GETDATE()) 
						from #TBDoorGroupInsert as d
						left join BT_col_UserInfoForReader as a on a.col_UserID=@memberid
						where col_Status=1 AND col_IsUploadToReader<99 and isnull(a.col_UserID,0)>0 and a.col_UserType=0 and a.col_CardType<12 and a.col_IfHadFace=1 and d.sys_ReaderID in (select HostDeviceID from V_HostDeviceForSam where IsCardMachine=0 and HasFace='true' AND brandID<>15)
		

						insert into BT_sys_UserReaderAccess(sys_UserCode,sys_CardNo,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange)
						SELECT col_UserCode,col_CardID,A.sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
						LEFT JOIN BT_col_UserInfoForReader as c on c.col_UserID=@memberid
						WHERE ISNULL(c.col_UserCode,'')<>'' AND NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess as B WHERE B.sys_UserCode=c.col_UserCode AND B.sys_ReaderID=A.sys_ReaderID AND B.sys_CardNo=c.col_CardID )

						insert into BT_sys_UserReaderAccess_JTCY(sys_memberid,sys_ReaderID,sys_PlanTemplateID,sys_CreateType,sys_IfChange) 
						SELECT @memberid as sys_MemberID,sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM #TBDoorGroupInsert as A
						WHERE NOT EXISTS(SELECT 1 FROM BT_sys_UserReaderAccess_JTCY as B WHERE B.sys_MemberID=@memberid AND B.sys_ReaderID=A.sys_ReaderID )


						INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
						SELECT @memberid,sys_ParentID,0 as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange FROM tb_LP_ReaderAccess_JTCY as A
						WHERE sys_FClgid=@lgid AND ISNULL(A.sys_ParentID,0)<>0 AND ISNULL(A.sys_ReaderID,0)=0 AND not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=@memberid AND B.sys_ParentID=A.sys_ParentID AND B.sys_ReaderID=0 ) 


						--加这个是为了防止先在【卡号信息】加了门组，之后在【门组管理】去掉某个门禁点，要删除而删除不了
						INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
						SELECT DISTINCT @memberid,A.DoorID,AccessControlID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
						FROM tb_DoorGroup_SettingUserID as A 
						LEFT JOIN BT_HostDevice as b on b.HostDeviceID=A.AccessControlID
						WHERE ISNULL(A.IsDelete,0)=0 AND ISNULL(A.AccessControlID,0)<>0		
						and A.DoorID in ( 
							SELECT sys_ParentID FROM tb_LP_ReaderAccess_JTCY WHERE sys_FClgid=@lgid AND ISNULL(sys_ParentID,0)<>0 AND ISNULL(sys_ReaderID,0)=0
						)
						AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
						AND not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=@memberid AND B.sys_ParentID=A.DoorID AND B.sys_ReaderID=A.AccessControlID ) 

						
						INSERT INTO tb_DoorGroup_UserReaderAccess_JTCY(sys_MemberID, sys_ParentID, sys_ReaderID, sys_PlanTemplateID, sys_CreateType, sys_IfChange)
						SELECT @memberid,0 as sys_ParentID,A.sys_ReaderID as sys_ReaderID,255 as sys_PlanTemplateID,2 as sys_CreateType,1 as sys_IfChange 
						FROM tb_LP_ReaderAccess_JTCY as A
						LEFT JOIN BT_HostDevice as b on b.HostDeviceID=a.sys_ReaderID
						WHERE sys_FClgid=@lgid AND ISNULL(A.sys_ParentID,0)=0 AND ISNULL(A.sys_ReaderID,0)<>0 
						AND ISNULL(b.HostDeviceID,0)>0 AND ISNULL(b.Deleted,0)=0
						AND not exists (select 1 from tb_DoorGroup_UserReaderAccess_JTCY as B where B.sys_MemberID=@memberid AND B.sys_ParentID=0 AND B.sys_ReaderID=A.sys_ReaderID ) 

						

						SET @number=@number +1

					END

			END






	SELECT 1  
END TRY
BEGIN CATCH
	SELECT 0
END CATCH