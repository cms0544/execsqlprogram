IF NOT EXISTS (select * from BT_HostDeviceBrand where [BrandID]=16)
	begin
			INSERT INTO [dbo].[BT_HostDeviceBrand]
					   ([BrandID]
					   ,[BrandName]
					   ,[Hidden])
				 VALUES
					   (16
					   ,N'Octopus'
					   ,0)
	end

	 