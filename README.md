# Customer Request Approval/Rejection with Ballerina,Google Sheets,Gmail and Twilio

Google Sheets is an online spread sheet which can be used to manupilate data. Gmail and Twilio provides API for sending e-mail and text messages respectively.
This guides helps to integarate ballerina with Google sheets , Gmail and Twilio to manage customers' request approvals or rejections.

Let us consider a real world scenario of customers requesting loans from the banks.Let's suppose that the user request details are initially send to a Google Sheet.When the requests are approved or rejected the request data are sent to seperate Google Sheets. Then a notification is sent to the customer using an e-mail or an sms according to his preference.
You can use the Ballerina Google Spreadsheet connector to read the spreadsheet, iterate through the rows and pick up the product name, email address and name of each customer from the columns. Then, you can use the Gmail connector to simply add the name to the body of a html mail template and send the email to the relevant customer.
Ballerina Spreadsheet connector can be used to retrieve and write data from and to the Google Sheet.Gmail connector can be used to send e-mails to the customer.Twilio Connector can be used to send text messages.

![Image of Block Diagram](https://github.com/WinmaH/MyBallerinaProject/blob/master/BallerinaRequestManagement.png)

**Prerequisites**.
Ballerina Distribution
Ballerina IDE plugins (IntelliJ IDEA or VSCode)

Obtain credetials and tokens for both Google Sheets, Gmail,Twilio APIs..More Information on this can be retrived from [wso2/gsheets4](https://central.ballerina.io/wso2/gsheets4) and [wso2/twilio](https://central.ballerina.io/wso2/twilio).


ballerina.conf configuration file should be created with the above obtained tokens, credentials and other important parameters as follows.
```
ACCESS_TOKEN="access token"
CLIENT_ID="client id"
CLIENT_SECRET="client secret"
REFRESH_TOKEN="refresh token"
SPREADSHEET_ID="spreadsheet id you have extracted from the sheet url"
SHEET_NAME="sheet name of your Goolgle Sheet. For example in above example, SHEET_NAME="Stats"
SENDER="email address of the sender"
USER_ID="mail address of the authorized user. You can give this value as, me"
AUTHTOKEN="token received from the twilio"
ACCOUNTSID="ID received from the twilio"
```
**Developing the application**

Ballerina connectors have to be created

Google Sheets client endpoint can be created as follows
```
endpoint gsheets4:Client spreadsheetClient {
    clientConfig:{
        auth:{
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret
        }
    }
};
```
Gmail client endpoint can be created as follows
```
endpoint gmail:Client gmailClient {
    clientConfig:{
        auth:{
            accessToken:accessToken,
            refreshToken:refreshToken,
            clientId:clientId,
            clientSecret:clientSecret
        }   
    }
};
```

Twilio client can be created as follows
```
endpoint twilio:Client twilioEP {
    accountSId:accountSID,
    authToken:authToken

};
```
approve.bal file in this github repository provides details on how to access the Google Sheet to retrieve and write data, how to acess the Gmail to send a customized e-mail and how to access Twilio to send customized text messages.   

**Run the Project**
To run the project go to the project MyBallerinaProject and run the following command.
$ ballerina run approve.bal


