using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Windows.Forms;
using System.Collections;

namespace ExecSqlProgram
{

    public class ExecSql
    {
        public string ServerPath { set; get; }
        public string ServerUserName { set; get; }

        public string ServerUserPassword { set; get; }


        public string ServerDatabase { set; get; }

        public string filePath { set; get; }

        public string updatetime { set; get; }

        public SqlConnection conn;

        public ListView listview { set; get; }

        public bool isBackUp { set; get; }

        public string backUpPath { set; get; }

        public ArrayList listViewItems {set;get;}

        /// <summary>
        /// 执行sql
        /// </summary>
        /// <param name="ServerPath"></param>
        /// <param name="ServerUserName"></param>
        /// <param name="ServerUserPassword"></param>
        /// <param name="ServerDatabase"></param>
        /// <param name="filePath"></param>
        /// <param name="listview"></param>
        public ExecSql(string ServerPath,string ServerUserName,string ServerUserPassword,string ServerDatabase,string filePath,ListView listview,string updatetime,bool isBackUp,string backUpPath)
        {
            this.ServerPath = ServerPath;
            this.ServerUserName = ServerUserName;
            this.ServerUserPassword = ServerUserPassword;
            this.ServerDatabase = ServerDatabase;
            this.filePath = filePath;
            this.listview = listview;
            this.updatetime = updatetime;
            this.isBackUp = isBackUp;
            this.backUpPath = backUpPath;
        }

        public string ExecContent()
        {
            string result = "";
            try
            {
                conn = new SqlConnection();
                conn.ConnectionString = @"Data Source =" + ServerPath + "; User ID = " + ServerUserName + "; pwd =" + ServerUserPassword + "; database = " + ServerDatabase + "";
                conn.Open();
 
                FileInfo[] myFiles = new FileInfo[0];
                ForeachFile(this.filePath, ref myFiles);
                FileCompare fc = new FileCompare();
            
                Array.Sort(myFiles, fc);
                SqlCommand comm = new SqlCommand();
                SqlTransaction tran = null;
                comm.Connection = conn;
                FileStream fs = null;
                StreamReader sr = null;
                ArrayList sqlar = new ArrayList();
                if (this.backUpPath == "")
                {
                    this.backUpPath = Environment.CurrentDirectory + @"\BackUp";
                }
                if (!Directory.Exists(backUpPath))
                {
                    Directory.CreateDirectory(backUpPath);
                }
                if(listViewItems == null)
                {
                    listViewItems = new ArrayList();
                }
                else
                {
                    listViewItems.Clear();
                }
               
                
                string backsql = "BACKUP DATABASE " + this.ServerDatabase + " to DISK ='" + this.backUpPath + @"\" + string.Format("{0}_{1}.bak",ServerDatabase , DateTime.Now.ToString("yyyy_MM_dd HH_mm_ss")) + "'";
                if (isBackUp)
                {
                    //备份数据库
                    comm.CommandText = backsql;
                    comm.ExecuteNonQuery();
                }
                for (var i = 0; i < myFiles.Length; i++)
                {
                    try
                    {
                        tran = conn.BeginTransaction();
                        comm.Transaction = tran;
                        sqlar.Clear();
                        fs = myFiles[i].OpenRead();
                        sr = new StreamReader(fs);
                        var str = "";
                        var tempstr = "" ;
                        while (sr.Peek()>-1)
                        {
                             tempstr = sr.ReadLine();
                           
                            //if(tempstr == "")
                            //{
                            //    continue;
                            //}

                            if(tempstr.ToUpper().Trim() !="GO")
                            {
                                str += tempstr + "\n";
                            }
                            else
                            {
                                if (str != "")
                                {
                                    sqlar.Add(str);
                                    str = "";
                                }
                              
                            }
                          
                        }
                        if (str != "")
                        {
                            sqlar.Add(str);
                        }
                    
                        for(var j = 0; j <sqlar.Count;j++)
                        {
                            comm.CommandText = sqlar[j].ToString();
                            comm.ExecuteNonQuery();
                        }

                        tran.Commit();
                        ListViewItem item = new ListViewItem();
                        item.Text = myFiles[i].Name;
                        item.SubItems.Add("成功");
                        this.listview.Items.Add(item);
                        listViewItems.Add(item);
                        sr.Close();
                        fs.Close();
                    }
                    catch(Exception ex)
                    {
                        tran.Rollback();
                        ListViewItem item = new ListViewItem();
                        item.Text = myFiles[i].Name;
                        item.SubItems.Add("失败");
                        item.SubItems.Add(ex.Message);
                        item.ForeColor = System.Drawing.Color.Red;
                        this.listview.Items.Add(item);
                        listViewItems.Add(item);
                    }
                   
                }

            }
            catch (Exception ex)
            {
                result = ex.Message;
            }
            finally{
                conn.Close();
            }

            return result;
        }


        private void ForeachFile(string filePathByForeach, ref FileInfo[] fileinfo)
        {
            DirectoryInfo theFolder = new DirectoryInfo(filePathByForeach);
            DirectoryInfo[] dirInfo = theFolder.GetDirectories();//获取所在目录的文件夹
            FileInfo[] file = theFolder.GetFiles();//获取所在目录的文件
            var list = fileinfo.ToList();
            foreach (FileInfo fileItem in file) //遍历文件
            {
                if (this.updatetime != "")
                {
                    //最新更新时间不是空
                    if(fileItem.LastWriteTime >= DateTime.Parse(this.updatetime))
                    {
                        list.Add(fileItem);
                    }
                }
                else
                {
                    //默认为空是所有文件
                    list.Add(fileItem);
                }
                
            }
            fileinfo = list.ToArray();
            //遍历文件夹
            foreach (DirectoryInfo NextFolder in dirInfo)
            {
                ForeachFile(NextFolder.FullName, ref fileinfo);
            }
        }

    }


  
}
