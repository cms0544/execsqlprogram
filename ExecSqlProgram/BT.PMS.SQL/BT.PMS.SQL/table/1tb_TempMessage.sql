-- Author:		<Colin>
-- Create date: <2021-04-20>
-- Description:	<右下角彈窗表，管理員添加是否提醒彈窗字段> 


--drop table tb_TempMessage
--go
if(not exists(select xtype from sysobjects where id = OBJECT_ID('tb_TempMessage') and xtype = 'U'))
   begin
create table tb_TempMessage(
ID int identity(1,1),
UserID nvarchar(200),
UserName nvarchar(500),
picurl nvarchar(500),
companyname nvarchar(500),
temperature decimal(18,1),
place nvarchar(500),
TypeID int,
Status int,
InTime datetime,
SendTime datetime,
sys_EventTime datetime
)
 end
go
IF NOT EXISTS (select name from syscolumns where id=object_id(N'YH') AND NAME='ismessage')
  begin
	alter table  YH  add ismessage int
  end
