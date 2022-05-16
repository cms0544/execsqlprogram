IF exists(select table_name from information_schema.views where table_name ='V_CarPark_Used_Devcie_State') DROP VIEW [dbo].[V_CarPark_Used_Devcie_State] 
GO


CREATE VIEW [dbo].[V_CarPark_Used_Devcie_State] 
AS

 SELECT tb_FeePavilion.* 
       ,carParkDevice.[FeePavilionID]
       ,carParkDevice.[LotPassID]
       ,carParkDevice.[CreatedTime]
       ,carParkDevice.[UpdatedTime]
       ,carParkDevice.[DeviceInfo] as ReaderInfo--這裏顯示的更亭名和出入口名可能不對，如果WEB修改了，單機沒有重新保存，就得不到最新的。
           ,(tb_FeePavilion.[Name]+IIF(carParkDevice.[LotPassID]>-1,' - '+tb_LotPass.PassName,'')+ 
                   CASE carParkDevice.CarParkDeviceType --0 八達通，1 EftPaymentReader，2 Printer，3 ReaderLCD
                                 WHEN 0 THEN ' - 八達通'
                                 WHEN 1 THEN ' - EFT卡機'
                                 WHEN 2 THEN ' - 列印機'
                                 WHEN 3 THEN ' - LCD'
                                 ELSE '未知設備類型'                 
                        END) AS [ReaderInfo2]
       ,carParkDeviceState.[OnlineState]--根據這個字段來判斷是否在線
       ,carParkDeviceState.[OnlineStateUpdatedTime]--這個是最後更新的時間
      --,cast(case when carParkDeviceState.[OnlineState]!=1 OR DATEDIFF(day,carParkDeviceState.[OnlineStateUpdatedTime],GETDATE())>1 THEN 0  ELSE 1 END as bit) as IsOnline--用這個來判斷
           ,CASE WHEN carParkDevice.CarParkDeviceType IN(0,1) THEN cast(case when carParkDeviceState.[OnlineState]!=1 OR DATEDIFF(day,carParkDeviceState.[OnlineStateUpdatedTime],GETDATE())>1 THEN 0  ELSE 1 END as bit)
                         ELSE carParkDeviceState.[OnlineState]         
                END AS IsOnline
		,carParkDevice.CarParkDeviceType
 FROM [dbo].[tb_FeePavilion] WITH(nolock)
 INNER JOIN [dbo].[BT_CarPark_Used_Devcie] carParkDevice WITH(nolock) ON tb_FeePavilion.ID=carParkDevice.FeePavilionID 
 LEFT JOIN [dbo].[tb_LotPass] WITH(nolock)     ON carParkDevice.LotPassID=tb_LotPass.ID               
 LEFT JOIN [dbo].[BT_CarPark_Used_Devcie_State] carParkDeviceState WITH(nolock) ON        carParkDevice.CarParkDeviceType=carParkDeviceState.CarParkDeviceType 
                                                                                     AND  carParkDevice.FeePavilionID=carParkDeviceState.FeePavilionID 
                                                                                     AND  carParkDevice.[LotPassID]=carParkDeviceState.[LotPassID]
 WHERE (carParkDevice.[LotPassID]=-1 OR  (carParkDevice.[LotPassID]>-1 AND carParkDevice.[LotPassID]=tb_LotPass.ID))

 
GO


