if(exists(select 1 from sysobjects where id = object_id('V_DeviceUserEventInfo_top_Golf')))
   begin
     drop view V_DeviceUserEventInfo_top_Golf
   end
--USE [BT_PMS]
GO

/****** Object:  View [dbo].[V_DeviceUserEventInfo_top_Golf]    Script Date: 6/4/2021 5:13:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create VIEW [dbo].[V_DeviceUserEventInfo_top_Golf] 
AS
     select platenumber,time, type,enter as PassType, c.lotid as lotid,enter,autoadd
	 from　tb_DeviceUserEventInfo_top as a
	 inner join tb_LotPass as c on c.id = a.LotID
	 where (isnull(isMain,0) = 1 or enter !=1 )



GO


