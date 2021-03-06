IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_GetBindOwnerAndDoorCard4Manage') and xtype='P')  DROP PROCEDURE [dbo].[SP_GetBindOwnerAndDoorCard4Manage]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetBindOwnerAndDoorCard4Manage]    Script Date: 2021/3/19 14:48:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[SP_GetBindOwnerAndDoorCard4Manage] '3C64A773-4B53-4FC0-AC46-A4359DFD1B6C','+85281234567'
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SP_GetBindOwnerAndDoorCard4Manage]  --SP_GetBindOwnerAndDoorCard4Manage '7CA9BD80-116E-4C2F-8449-C24D3ACFD4EA','+85281234567'
@bt_app_user_uid uniqueidentifier,
@bt_app_user_mobile varchar(20)
AS 
BEGIN

	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 
	zh_owner_id,
	zh_owner.name as zh_owner_name,
	zh_owner.code as zh_owner_code
	--is_master,
	--app_permission_type
	INTO #BindOwnerRight
	FROM [dbo].[BT_APP_BindOwner] BO WITH(nolock) 
	INNER JOIN zh_owner WITH(nolock) ON zh_owner.id=BO.zh_owner_id
	WHERE ([bt_app_user_uid]=@bt_app_user_uid OR isnull([bt_app_user_mobile],'-852')=@bt_app_user_mobile) AND ISNULL(BO.[deleted],0)=0 AND ISNULL(BO.[disabled],0)=0
		   and (		ISNULL(BO.is_master,0)=1 --主帳號
							OR charindex(',1,',','+ISNULL(BO.app_permission_type,'')+',',0)<>0--有權限管理帳號
			)

	SELECT 
	BO.app_bind_guid,
	BO.[bt_app_user_uid] as app_user_uid,
	BO.[bt_app_user_mobile]  as app_user_mobile,
	BO.zh_owner_id,
	BO.is_master,
	BO.app_permission_type,
	zh_owner.code as zh_owner_code,
	zh_owner.name as zh_owner_name,
	BO.[app_alias]  as app_user_alias,
	BO.[remark] as app_user_remark,
	BO.bind_created_by_qrcode,
	BO.[disabled]
	INTO #BindOwner
	FROM [dbo].[BT_APP_BindOwner] BO WITH(nolock) 
	INNER JOIN zh_owner WITH(nolock) ON zh_owner.id=BO.zh_owner_id
	--WHERE ([bt_app_user_uid]=@bt_app_user_uid OR [bt_app_user_mobile]=@bt_app_user_mobile) AND ISNULL([deleted],0)=0
	WHERE ISNULL(BO.[deleted],0)=0 AND zh_owner.id IN(SELECT zh_owner_id FROM #BindOwnerRight)
	

	--SELECT * FROM #BindOwnerRight

	SELECT * FROM #BindOwner ORDER BY zh_owner_id,app_user_uid,app_user_mobile


	SELECT cardm.[col_ID]        as record_id
		  ,cardm.[col_CardID]    as door_card_id
		  ,convert(varchar(10),cardm.[col_DateStart],120) as door_card_date_start
		  ,convert(varchar(10),cardm.[col_DateEnd],120) as door_card_date_end
		  ,cardm.[col_State]     as door_card_state
		  ,cardm.[col_CardName]  as door_card_user
		  ,cardm.[col_Remark]    as door_card_remark
		  ,zh_members.ownerid as zh_owner_id
		  --,zh_owner.zh_owner_code
		  --,zh_owner.zh_owner_name
		  ,cardm.[kmbm] as door_card_code--卡面編碼
		  ,cardm.col_UserID as zh_member_id
	  FROM [dbo].[BT_col_CardManagement] cardm with(nolock)
	  INNER JOIN zh_members with(nolock) on cardm.col_UserID=zh_members.id
	  WHERE zh_members.ownerid IN(SELECT zh_owner_id FROM #BindOwnerRight)
	  ORDER BY  cardm.[col_CardID]
 
END
 

