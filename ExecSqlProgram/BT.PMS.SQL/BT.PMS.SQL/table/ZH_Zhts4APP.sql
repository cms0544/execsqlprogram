IF NOT EXISTS (select name from syscolumns where id=object_id(N'ZH_Zhts4APP'))
	begin
		CREATE TABLE [dbo].[ZH_Zhts4APP](
			[ZH_Zhts_id] [int] NOT NULL,
			[bt_app_user_uid] [uniqueidentifier] NOT NULL, 
		 CONSTRAINT [PK_ZH_Zhts4APP] PRIMARY KEY CLUSTERED 
		(
			[ZH_Zhts_id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		)  
	end
