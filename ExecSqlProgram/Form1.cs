using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ExecSqlProgram
{
    public partial class Form1 : Form
    {
      
        IniFile iniFile ;

        ExecSql execsql;
        public Form1()
        {
            InitializeComponent();

            string iniPath = System.Environment.CurrentDirectory + @"\Settings.ini";
            iniFile = new IniFile(iniPath);

            txtServer.Text = iniFile.IniReadValue("db", "server" );
            txtUserName.Text = iniFile.IniReadValue("db", "username");
            txtPassword.Text = iniFile.IniReadValue("db", "password");
            txtDatabase.Text = iniFile.IniReadValue("db", "database" );
            txtFile.Text = iniFile.IniReadValue("filepath", "filepath" );
            txtBackUpPath.Text = iniFile.IniReadValue("db", "backuppath");
            string isCheckedStr = iniFile.IniReadValue("db", "isbackup");
            if(isCheckedStr == "1")
            {
                cbIsBackUp.Checked = true;
            }else
            {
                cbIsBackUp.Checked = false;
            }

            this.dtupdateTime.Format = DateTimePickerFormat.Custom;
            this.dtupdateTime.CustomFormat = " ";//双引号之间是一个空格
            dtupdateTime.Text = iniFile.IniReadValue("updatetime", "updatetime");

        }

        private void button1_Click(object sender, EventArgs e)
        {
            folderBrowserDialog1 = new FolderBrowserDialog();
            folderBrowserDialog1.Description = "请选择文件夹";
            if(folderBrowserDialog1.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                var SelectedPath = folderBrowserDialog1.SelectedPath;
                if (SelectedPath == "")
                {
                    MessageBox.Show("请选择文件夹路径");
                    return;
                }
                txtFile.Text = SelectedPath;
            }
        }

        private void txtFile_TextChanged(object sender, EventArgs e)
        {

        }

        private void listView1_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void button2_Click(object sender, EventArgs e)
        {
            if(txtServer.Text == "")
            {
                MessageBox.Show("请输入服务名");
                return;
            }

            if (txtUserName.Text == "")
            {
                MessageBox.Show("请输入用户名");
                return;
            }

            if (txtPassword.Text == "")
            {
                MessageBox.Show("请输入密码");
                return;
            }


            if (txtFile.Text == "")
            {
                MessageBox.Show("请输入文件路径");
                return;
            }
            listView1.Items.Clear();

            execsql = new ExecSql(txtServer.Text, txtUserName.Text, txtPassword.Text, txtDatabase.Text, txtFile.Text, listView1,dtupdateTime.Text,cbIsBackUp.Checked,txtBackUpPath.Text);
            cboCondition.SelectedValue = -1;
            string result = execsql.ExecContent();
            if(result != "")
            {
                MessageBox.Show(result);
                return;
            }
        }



        private void button3_Click(object sender, EventArgs e)
        {
            try
            {
                iniFile.IniWriteValue("db", "server", txtServer.Text);
                iniFile.IniWriteValue("db", "username", txtUserName.Text);
                iniFile.IniWriteValue("db", "password", txtPassword.Text);
                iniFile.IniWriteValue("db", "database", txtDatabase.Text);
                iniFile.IniWriteValue("db", "backuppath", txtBackUpPath.Text);
                iniFile.IniWriteValue("db", "isbackup", cbIsBackUp.Checked==true?"1":"0");
                iniFile.IniWriteValue("filepath", "filepath", txtFile.Text);
                iniFile.IniWriteValue("updatetime", "updatetime",this.dtupdateTime.Text);
                MessageBox.Show("保存成功");

            }
            catch(Exception ex)
            {

            }
           
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("Value");
            dt.Columns.Add("Text");

            DataRow dr1 = dt.NewRow();
            dr1["Text"] = "全部";
            dr1["Value"] = "-1";
            dt.Rows.Add(dr1);

            DataRow dr2 = dt.NewRow();
            dr2["Text"] = "成功";
            dr2["Value"] = "1";
            dt.Rows.Add(dr2);

            DataRow dr3 = dt.NewRow();
            dr3["Text"] = "失败";
            dr3["Value"] = "0";
            dt.Rows.Add(dr3);

            cboCondition.DataSource = dt;
            cboCondition.DisplayMember = "Text";
            cboCondition.ValueMember = "Value";

            cboCondition.SelectedValue = -1;
        }

        private void dateTimePicker1_ValueChanged(object sender, EventArgs e)
        {
            this.dtupdateTime.CustomFormat = "yyyy-MM-dd HH:mm:ss";
        }
        /// <summary>
        /// listview 可以复制里面的值
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void listView1_KeyDown(object sender, KeyEventArgs e)
        {
            if(e.Control && e.KeyCode == Keys.C)
            {
                if(listView1.SelectedItems.Count > 0)
                {
                    if(listView1.SelectedItems[0].Text != "")
                    {
                        Clipboard.SetDataObject(listView1.SelectedItems[0].Text);
                    }
                }
            }
        }

        private void btnBackUpPath_Click(object sender, EventArgs e)
        {
            folderBrowserDialog1 = new FolderBrowserDialog();
            folderBrowserDialog1.Description = "请选择文件夹";
            if (folderBrowserDialog1.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                var SelectedPath = folderBrowserDialog1.SelectedPath;
                if (SelectedPath == "")
                {
                    MessageBox.Show("请选择文件夹路径");
                    return;
                }
                txtBackUpPath.Text = SelectedPath;
            }
        }

        private void cboCondition_SelectedIndexChanged(object sender, EventArgs e)
        {
            #region 筛选
            listView1.Items.Clear();
            if (execsql!=null && execsql.listViewItems != null)
            {
                if (cboCondition.SelectedValue.ToString() != "-1")
                {



                    string selecttxt = "成功";
                    if (cboCondition.SelectedValue.ToString() == "1")
                    {
                        selecttxt = "成功";
                    }
                    else
                    {
                        selecttxt = "失败";
                    }
                    foreach (ListViewItem item in execsql.listViewItems)
                    {

                        if (item.SubItems[1].Text == selecttxt)
                        {
                            listView1.Items.Add(item);
                        }
                    }



                }
                else
                {
                    foreach (ListViewItem item in execsql.listViewItems)
                    {
                        listView1.Items.Add(item);
                    }
                }
            }
           

            #endregion 筛选
           
          
        }
    }
}
