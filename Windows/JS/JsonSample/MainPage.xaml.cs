using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using Microsoft.Phone.Shell;
using JsonSample.Resources;
using Newtonsoft.Json;

using System.Text;
using System.IO;



namespace JsonSample
{
    public partial class MainPage : PhoneApplicationPage
    {

        public MainPage()
        {
            InitializeComponent();
            

        }

        void webClient_DownloadStringCompleted(object sender, DownloadStringCompletedEventArgs e)
        {
           var rootObject = JsonConvert.DeserializeObject<RootObject>(e.Result);
           //tbl_result.Text = e.Result.ToString();
          // Use The rootObject
           tbl_result.Text = Convert.ToString(rootObject);
        }




        //This event of button placed in grid
        private void btn_Parse_Click(object sender, RoutedEventArgs e)
        {

            sendRequest();
            

        }



        void sendRequest()
            {
               Uri myUri = new Uri("http://www.aaask.co/login");
               HttpWebRequest myRequest = (HttpWebRequest)HttpWebRequest.Create(myUri);
               myRequest.ContentType = "application/json";
               myRequest.Method = "post";
               myRequest.BeginGetRequestStream(new AsyncCallback(GetRequestStreamCallback), myRequest);
            }

        void GetRequestStreamCallback(IAsyncResult callbackResult)
        {
            HttpWebRequest myRequest = (HttpWebRequest)callbackResult.AsyncState;

            // End the stream request operation
            Stream postStream = myRequest.EndGetRequestStream(callbackResult);
            

            // Create the post data
            //string postData = @"{""email"":""banzaitokyo@gmail.com"", ""password"":""kostroma""}";
            string email;
            string postData;
            Deployment.Current.Dispatcher.BeginInvoke(() =>
                    {
                        email = txtLogin.Text;
                        postData = "{\"email\":\""+ email +"\", \"password\":\"kostroma\"}";
                        
                        if (postData != null)
                        {
                            byte[] byteArray = Encoding.UTF8.GetBytes(postData);

                            // Add the post data to the web request
                            postStream.Write(byteArray, 0, byteArray.Length);
                            postStream.Close();

                            // Start the web request
                            myRequest.BeginGetResponse(new AsyncCallback(GetResponsetStreamCallback), myRequest);
                        }
                    });



         
        }

        void GetResponsetStreamCallback(IAsyncResult callbackResult)
        {

            string result = "";
            //try
            //{
                HttpWebRequest request = (HttpWebRequest)callbackResult.AsyncState;
                HttpWebResponse response = (HttpWebResponse)request.EndGetResponse(callbackResult);
                
                using (StreamReader httpWebStreamReader = new StreamReader(response.GetResponseStream()))
                {
                    result = httpWebStreamReader.ReadToEnd();
                    Deployment.Current.Dispatcher.BeginInvoke(() =>
                    {
                        //tbl_result.Text = result;
                        var rootObject = JsonConvert.DeserializeObject<RootObject>(result);
                        tbl_result.Text = rootObject.ToString();
                    });
                    
                }


                
                
            //}
            //catch (Exception e)
            //{
            //    tbl_result.Text = e.ToString();
            //}
            
        }


        
    }
}