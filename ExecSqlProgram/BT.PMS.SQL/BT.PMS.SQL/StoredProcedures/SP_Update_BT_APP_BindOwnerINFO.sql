--USE [BT_PMS]
--GO

IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_Update_BT_APP_BindOwnerINFO') and xtype='P')   DROP PROCEDURE [dbo].[SP_Update_BT_APP_BindOwnerINFO]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_Update_BT_APP_BindOwnerINFO]
@NewBindOwnerINFO as [dbo].[TVP_BT_APP_BindOwner_Info] READONLY
AS
BEGIN

	SET NOCOUNT ON;


	set xact_abort on

	begin transaction	

		UPDATE BT_APP_BindOwner
			   SET bt_app_user_uid=temp.[user_uid]
		FROM @NewBindOwnerINFO temp
		WHERE		BT_APP_BindOwner.bt_app_user_uid='00000000-0000-0000-0000-000000000000'
			  AND   BT_APP_BindOwner.[app_bind_guid]=temp.[app_bind_guid]


		UPDATE [dbo].[BT_APP_User] SET [bt_app_user_name]=temp.user_fullname,[bt_app_user_mobile]=left(temp.[user_mobile],20)
		FROM @NewBindOwnerINFO temp 
		WHERE		BT_APP_User.bt_app_user_uid=temp.[user_uid]
 
		INSERT INTO [dbo].[BT_APP_User]
				   ([bt_app_user_uid]
				   ,[bt_app_user_name]
				   ,[bt_app_user_mobile])
		SELECT distinct [user_uid]
			  ,[user_fullname]
			  ,[user_mobile]
		  FROM @NewBindOwnerINFO temp
				WHERE not exists(
					 SELECT * FROM [dbo].[BT_APP_User]  
					 WHERE BT_APP_User.bt_app_user_uid=temp.user_uid
		)


	commit tran


END

GO

 