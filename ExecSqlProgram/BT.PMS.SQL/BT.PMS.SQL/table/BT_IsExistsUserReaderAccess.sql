

IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N'BT_IsExistsUserReaderAccess') and type=N'U')
	begin 
		CREATE TABLE [dbo].[BT_IsExistsUserReaderAccess](
			[id] [int] IDENTITY(1,1) NOT NULL,
			[sys_MemberID] [int] NULL,
		 CONSTRAINT [PK_BT_IsExistsUserReaderAccess] PRIMARY KEY CLUSTERED 
		(
			[id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
		) ON [PRIMARY]
		
	end
GO


