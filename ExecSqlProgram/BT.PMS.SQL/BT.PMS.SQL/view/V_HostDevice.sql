/****** Object:  View [dbo].[V_HostDevice]    Script Date: 2021/4/8 11:16:29 ******/
IF exists(select table_name from information_schema.views where table_name ='V_HostDevice') DROP VIEW [dbo].[V_HostDevice];
GO

/****** Object:  View [dbo].[V_HostDevice]    Script Date: 2021/4/8 11:16:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_HostDevice] 
AS

SELECT [HostDeviceID]

      ,FC_LP.lpid as xq_id--小區ID
      ,FC_LP.name as xq_name--小區名稱

      ,FC_LG.lgid as ly_id--樓宇ID
      ,FC_LG.name as ly_name--樓宇名稱



      ,[HostName]
      ,[HostIP]
      ,[HostPort]
      ,[HostCamera]
      ,[HostConnectType]
      ,[HostLoginUser]
      ,[HostLoginPassword]
      ,[Intranet_HostIP]
      ,[Intranet_HostPort]
      ,HD.[BrandID]
      ,[HasVSM]
      ,[HasVidosoft]
      ,[HasCams]
      ,[HasRemoteManagement]
      ,[HasStayingStatistics]
      ,[HasFaceStatistics]
      ,[HasHeatMap]
      ,[CreatedTime]
      ,[UpdatedTime]
      ,[Deleted]
      ,[HasITimex]
	  ,[IsCardMachine]
	  ,HDB.[BrandName]
	  ,ISNULL(HD.HasVTO,0) AS [IsVTO] --CAST(IIF(ISNULL([HasITimex],0)=1 AND isnull([IsCardMachine],0)=0,1,0) as bit) AS [IsVTO]
	  ,HD.HasVTO
	  ,HD.IsControlRoomVTO
	  ,CAST(IIF(ISNULL(HD.HasQRCode,0)=1 OR (HD.[BrandID]=14 AND ISNULL(HD.HasVTO,0)=1),1,0) as bit) AS HasQRCode
	  ,ISNULL(NeedTemperature,0) AS NeedTemperature
	  ,ISNULL(HasFace,0) AS HasFace
	  ,ISNULL(IsOctDevice,0) AS IsOctDevice
	  ,ISNULL(IsClubHouse,0) AS IsClubHouse
	  ,ISNULL(DoorID,1) AS DoorID
	  ,ISNULL(InOutType,1) AS InOutType
	  ,ISNULL(ReaderLOGO,'') AS ReaderLOGO
	  ,ISNULL(AreaID,1) AS AreaID
	  ,ISNULL(MainReaderID,HostDeviceID) AS MainReaderID
	  ,ISNULL(ReaderID,HostDeviceID) AS ReaderID
	  ,ISNULL(IsMainDevice,1) AS IsMainDevice
	  ,ISNULL(Com,1) AS Com
	  ,ISNULL(Rate,19200) AS Rate
	  ,ISNULL(DeviceType,'') AS DeviceType
	  ,ISNULL(HD.HasQRCodeReader,0) AS HasQRCodeReader	

  FROM [dbo].[BT_HostDevice] HD
  INNER JOIN FC_LG ON FC_LG.lgid=HD.[FC_lgid]
  INNER JOIN FC_LP ON FC_LP.lpid=FC_LG.sslpid
  LEFT JOIN  [dbo].[BT_HostDeviceBrand] HDB ON HDB.BrandID=HD.BrandID

 WHERE ISNULL(HD.[Deleted],0)=0
 





GO


