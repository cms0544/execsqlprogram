IF NOT EXISTS (select * from BT_HostDeviceBrandConnectType where [ConnectType]=160001 )
	begin
			INSERT INTO [dbo].[BT_HostDeviceBrandConnectType]
					   ([ConnectType]
					   ,[BrandID]
					   ,[ConnectTypeName]
					   ,[IsDeleted])
				 VALUES
					   (160001
					   ,16
					   ,N'WG-COM'
					   ,0)
	end

--IF NOT EXISTS (select * from BT_HostDeviceBrandConnectType where [ConnectType]=160002 )
--	begin
--			INSERT INTO [dbo].[BT_HostDeviceBrandConnectType]
--					   ([ConnectType]
--					   ,[BrandID]
--					   ,[ConnectTypeName]
--					   ,[IsDeleted])
--				 VALUES
--					   (160002
--					   ,16
--					   ,N'Standard-COM'
--					   ,0)
--	end

--IF NOT EXISTS (select * from BT_HostDeviceBrandConnectType where [ConnectType]=160003)
--	begin
--			INSERT INTO [dbo].[BT_HostDeviceBrandConnectType]
--					   ([ConnectType]
--					   ,[BrandID]
--					   ,[ConnectTypeName]
--					   ,[IsDeleted])
--				 VALUES
--					   (160003
--					   ,16
--					   ,N'Standard-TCP'
--					   ,0)
--	end