
IF exists(SELECT * FROM sysobjects WHERE id=object_id(N'sp_SaveAppImage') and xtype='P')  DROP PROCEDURE [dbo].[sp_SaveAppImage]
GO

CREATE proc [dbo].[sp_SaveAppImage]
(
	@ImageData nvarchar(max),
	@urlPath nvarchar(max)
)
AS

Insert into BT_App_ImageList(ImageData,urlPath,intime)
Values(@ImageData,@urlPath,getdate())

select @@IDENTITY