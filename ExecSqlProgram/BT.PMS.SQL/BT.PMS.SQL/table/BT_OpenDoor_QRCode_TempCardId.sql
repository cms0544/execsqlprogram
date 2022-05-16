IF NOT EXISTS (select name from syscolumns where id=object_id(N'BT_OpenDoor_QRCode_TempCardId'))
	begin
			CREATE TABLE [dbo].[BT_OpenDoor_QRCode_TempCardId](
				[TempIndex] [bigint] NOT NULL,
				[CreatedTime] [datetime] NULL,
			PRIMARY KEY CLUSTERED 
			(
				[TempIndex] ASC
			))
	end



