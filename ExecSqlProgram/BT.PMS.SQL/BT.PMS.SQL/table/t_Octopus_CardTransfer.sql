
IF Not exists(SELECT * FROM sys.objects WHERE object_id=OBJECT_ID(N't_Octopus_CardTransfer') and type=N'U')
	begin 
		CREATE TABLE [dbo].[t_Octopus_CardTransfer](
			[NewCardNO] [nvarchar](16) NULL,
			[OldCardNO] [nvarchar](16) NULL,
			[EmployeeID] [nvarchar](32) NULL,
			[CreatedTime] [datetime] NULL
		) ON [PRIMARY]
	end


