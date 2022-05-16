IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'SP_UpdateCardInfoByApp2') and xtype='P')  DROP PROCEDURE [dbo].[SP_UpdateCardInfoByApp2]
GO

/****** Object:  StoredProcedure [dbo].[SP_UpdateCardInfoByApp]    Script Date: 2021/4/21 18:32:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_UpdateCardInfoByApp2]  
@record_id int, 
@door_card_state int,
@alias varchar(100),
@remark varchar(200),
@zh_member_id int=-1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	update BT_col_CardManagement set col_State =@door_card_state,[col_CardName]=@alias,[col_Remark]=@remark where col_id=@record_id
	if(isnull(@zh_member_id,0)>0)
		BEGIN
				UPDATE[dbo].[ZH_Members] SET [alias]=@alias,[memo]=@remark WHERE [id]=@zh_member_id
				declare @app_bind_guid uniqueidentifier
				SELECT @app_bind_guid=[app_bind_guid] FROM [dbo].[ZH_Members] WHERE [ID]=@zh_member_id
				if(isnull(@app_bind_guid,'00000000-0000-0000-0000-000000000000')!='00000000-0000-0000-0000-000000000000')
					begin
							UPDATE [dbo].[BT_APP_BindOwner] SET [app_alias]=@alias,[remark]=@remark WHERE [app_bind_guid]=@app_bind_guid
					end

		END
END		


GO

