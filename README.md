# Customer Request Approval/Rejection with Ballerina,Google Sheets,Gmail and Twilio

Google Sheets is an online spread sheet which can be used to manupilate data. Gmail and Twilio provides API for sending e-mail and text messages respectively.
This guides helps to integarate ballerina with Google sheets , Gmail and Twilio to manage customers' request approvals or rejections.

Let us consider a real world scenario of customers requesting loans from the banks.Let's suppose that the user request details are initially send to a Google Sheet.When the requests are approved or rejected the request data are sent to seperate Google Sheets. Then a notification is sent to the customer using an e-mail or an sms according to his preference.
You can use the Ballerina Google Spreadsheet connector to read the spreadsheet, iterate through the rows and pick up the product name, email address and name of each customer from the columns. Then, you can use the Gmail connector to simply add the name to the body of a html mail template and send the email to the relevant customer.
Ballerina Spreadsheet connector can be used to retrieve and write data from and to the Google Sheet.Gmail connector can be used to send e-mails to the customer.Twilio Connector can be used to send sms.

Prerequisites
Ballerina Distribution
Ballerina IDE plugins (IntelliJ IDEA and VSCode)

Obtain credetials and tokens for both Google Sheets, Gmail,Twilio APIs.

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
Developing the application
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





Note that, in the implementation, each of the above endpoint configuration parameters are read from the ballerina.conf file.
After creating the endpoints, let's implement the API calls inside the functions getCustomerDetailsFromGSheet and sendMail.
Let's look at how to get the sheet data about customer product downloads as follows.
function getCustomerDetailsFromGSheet () returns (string[][]|boolean) {
    //Read all the values from the sheet.
    string[][] values;
    var spreadsheetRes =  spreadsheetClient->getSheetValues(spreadsheetId, sheetName, EMPTY_STRING, EMPTY_STRING);
    match spreadsheetRes {
        string[][] vals => {
            log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ; sheet name: "
                    + sheetName);
            return vals;
        }
        gsheets4:SpreadsheetError e => return false;
    }
}
The Spreadsheet connector's getSheetValues function is called from Spreadsheet endpoint by passing the spreadsheet id and the sheet name. The sheet values are returned as a two dimensional string array if the request is successful. If unsuccessful, it returns a SpreadsheetError.
Next, let's look at how to send an email using the Gmail client endpoint.
function sendMail(string customerEmail, string subject, string messageBody) {
    //Create HTML message

    gmail:MessageRequest messageRequest;
    messageRequest.recipient = customerEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = subject;
    messageRequest.messageBody = messageBody;
    messageRequest.contentType = gmail:TEXT_HTML;
    
    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + customerEmail + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
        }
        gmail:GmailError e => log:printInfo(e.message);
    }
}
First, a new MessageRequest type is created and assigned the fields for sending an email. The content type of the message request is set as TEXT_HTML. Then, Gmail connector's sendMessage function is called by passing the MessageRequest and userId.
The response from sendMessage is either a string tuple with the message ID and thread ID (if the message was sent successfully) or a GmailError (if the message was unsuccessful). The match operation can be used to handle the response if an error occurs.
The main function in notification_sender.bal calls sendNotification function. Inside sendNotification, the customer details are taken from the sheet by first calling getCustomerDetailsFromGSheet. Then, the rows in the returned sheet are subsequently iterated. During each iteration, cell values in the first three columns are extracted for each row, except for the first row with column headers, and during each iteration, a custom HTML mail is created and sent for each customer.
function sendNotification() returns boolean {
    //Retrieve the customer details from spreadsheet.
    var customerDetails = getCustomerDetailsFromGSheet();
    match customerDetails {
        string[][] values => {
            int i =0;
            //Iterate through each customer details and send customized email.
            foreach value in values {
                //Skip the first row as it contains header values.
                if(i > 0) {
                    string productName = value[0];
                    string customerName = value[1];
                    string customerEmail = value[2];
                    string subject = "Thank You for Downloading " + productName;
                    boolean isSuccess = sendMail(customerEmail, subject,
                        untaint getCustomEmailTemplate(customerName, productName));
                    if (!isSuccess) {
                        return false;
                    }
                }
                i = i +1;
            }
        }
        boolean isSuccess => return isSuccess;
    }
    return true;
}
Testing
Try it out
Run this sample by entering the following command in a terminal.
$ ballerina run notification-sender
Each of the customers in your Google Sheet would receive a new customized email with the subject: Thank You for Downloading {ProductName}.
The following is a sample email body.
    Hi Peter 
    
    Thank you for downloading the product ESB!

    If you still have questions regarding ESB, please contact us and we will get in touch with you right away!

Let's now look at sample log statements we get when running the sample for this scenario.
INFO  [wso2.notification-sender] - Retrieved customer details from spreadsheet id:1mzEKVRtL3ZGV0finbcd1vfa16Ed7Qaa6wBjsf31D_yU ; sheet name: Stats 
INFO  [wso2.notification-sender] - Sent email to tom@mail.com with message Id: 163014e0e41c1b11 and thread Id:163014e0e41c1b11 
INFO  [wso2.notification-sender] - Sent email to jack@mail.com with message Id: 163014e1167c20c4 and thread Id:163014e1167c20c4 
INFO  [wso2.notification-sender] - Sent email to peter@mail.com with message Id: 163014e15d7476a0 and thread Id:163014e15d7476a0 
INFO  [wso2.notification-sender] - Gmail-Google Sheets Integration -> Email sending process successfully completed! 
Writing unit tests
In Ballerina, the unit test cases should be in the same package inside a folder named as 'tests'. When writing the test functions the below convention should be followed.
Test functions should be annotated with @test:Config. See the below example. 
   @test:Config
   function testSendNotification() {
This guide contains the unit test case for the sendNotification function.
To run the unit test, go to the sample root directory and run the following command.
$ ballerina test notification-sender
Refer to the notification-sender/tests/notification_sender_test.bal for the implementation of the test file.
Deployment
Deploying locally
You can deploy the services that you developed above in your local environment. You can create the Ballerina executable archives (.balx) first as follows.
Building
$ ballerina build notification-sender
After the build is successful, there will be a .balx file inside the target directory. That executable can be executed as follows.
Running
$ ballerina run target/notification-sender.balx
