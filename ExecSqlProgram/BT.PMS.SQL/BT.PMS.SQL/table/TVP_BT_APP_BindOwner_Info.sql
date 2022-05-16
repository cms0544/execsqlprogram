begin try

IF exists(SELECT * FROM systypes WHERE [name]=N'TVP_BT_APP_BindOwner_Info')   DROP TYPE [dbo].[TVP_BT_APP_BindOwner_Info]
CREATE TYPE [dbo].[TVP_BT_APP_BindOwner_Info] AS TABLE(
	[user_uid] [uniqueidentifier] NOT NULL,
	[app_bind_guid] [uniqueidentifier] NOT NULL,
	[user_mobile] [varchar](20) NULL,
	[user_fullname] [varchar](100) NOT NULL
)

end try
begin catch
--出錯就不用理，因為TYPE被存儲過程使用后，就不能刪除，所以一般都是新創建一個。
end catch

GO

