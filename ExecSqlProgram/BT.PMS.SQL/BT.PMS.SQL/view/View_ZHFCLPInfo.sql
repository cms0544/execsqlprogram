if(exists(select 1 from sysobjects where id = OBJECT_ID('View_ZHFCLPInfo') and xtype = 'V'))
 begin
    drop view View_ZHFCLPInfo
 end
/****** Object:  View [dbo].[View_ZHFCLPInfo]    Script Date: 2021/8/3 9:34:47 ******/
go
create VIEW [dbo].[View_ZHFCLPInfo]
AS
SELECT   dbo.ZH_Fc.ZFID, dbo.ZH_Fc.OWNERID, dbo.ZH_Owner.CODE AS OwnerCode, dbo.ZH_Fc.OWNERNAME, 
                dbo.FC_Cell.cellid, dbo.FC_Cell.code AS cellcode, dbo.FC_Cell.name AS cellname, dbo.FC_Dy.dyid, 
                dbo.FC_Dy.code AS DyCode, dbo.FC_Dy.name AS DyName, dbo.FC_Lg.lgid, dbo.FC_Lg.code AS lgCode, 
                dbo.FC_Lg.name AS lgName, dbo.FC_Lp.lpid, dbo.FC_Lp.code AS lpCode, dbo.FC_Lp.name AS lpName,
				dbo.ZH_Owner.LXDH,dbo.ZH_Owner.alias
FROM      dbo.ZH_Fc INNER JOIN
                dbo.ZH_Owner ON dbo.ZH_Fc.OWNERID = dbo.ZH_Owner.ID INNER JOIN
                dbo.FC_Cell ON dbo.ZH_Fc.CELLID = dbo.FC_Cell.cellid INNER JOIN
                dbo.FC_Dy ON dbo.FC_Cell.ssdyid = dbo.FC_Dy.dyid INNER JOIN
                dbo.FC_Lg ON dbo.FC_Dy.sslgid = dbo.FC_Lg.lgid INNER JOIN
                dbo.FC_Lp ON dbo.FC_Lg.sslpid = dbo.FC_Lp.lpid

GO


