IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='alias')      
ALTER TABLE zh_owner ADD alias nvarchar(max) 


IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='yzdzdw') 
alter table zh_owner add yzdzdw varchar(max)

IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='yzdzds') 
alter table zh_owner add yzdzds varchar(max)

IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='yzdzjd') 
alter table zh_owner add yzdzjd varchar(max)

IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='yzdzdq')
alter table zh_owner add yzdzdq varchar(max)


IF NOT EXISTS (select name from syscolumns where id=object_id(N'zh_owner') AND NAME='email')
alter table zh_owner add email varchar(max)

