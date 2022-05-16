			IF NOT EXISTS (select name from syscolumns where id=object_id(N'jtsf') AND NAME='ismanage')  		alter table jtsf add ismanage int
			
			