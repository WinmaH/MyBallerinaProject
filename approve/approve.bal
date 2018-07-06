import ballerina/config;
import ballerina/log;
import wso2/gsheets4;
import wso2/gmail;
import wso2/twilio;
import ballerina/io;
import ballerina/time;


documentation{
    get access credetials from the config file
}

string accessToken = config:getAsString("ACCESS_TOKEN");
string clientId = config:getAsString("CLIENT_ID");
string clientSecret = config:getAsString("CLIENT_SECRET");
string refreshToken = config:getAsString("REFRESH_TOKEN");
string spreadsheetId = config:getAsString("SPREADSHEET_ID");
string sheetName = config:getAsString("SHEET_NAME");
string sheetName2 = config:getAsString("SHEET_NAME2");
string senderEmail = config:getAsString("SENDER");
string userId = config:getAsString("USER_ID");
string accountSID = config:getAsString("ACCOUNTSID");
string authToken = config:getAsString("AUTHTOKEN");

documentation{
    Google Sheets client endpoint declaration with http client configurations.
}
endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

documentation{
    Gmail client endpoint declaration
}
endpoint gmail:Client gmailClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

documentation{
    Twilio client endpoint declaration
}
endpoint twilio:Client twilioEP {
    accountSId:accountSID,
    authToken:authToken

};



function main(string... args) {
    trigger();
}


function trigger() {

    //Retrieve the customer details from spreadsheet.
    string[][] values = getCustomerDetailsFromGSheet();
    //variable to keep a count of the recodes
    int count = 0;
	//variable to keep the count of accepted recodes
    int approved_count = 0;
	//variable to keep the count of rejected recodes
    int rejected_count = 0;

    //declare 2D arrays keep the accepted and rejected customer details
    string[][] new_values_approved=[["LoanNumber","CustomerName","CustomerEmail","ApplyDate","ApproveDate"]];
    string[][] new_values_rejected=[["LoanNumber","CustomerName","CustomerEmail","ApplyDate","ApproveDate"]];



    foreach value in values {
        //header lines are excluded
        if (count > 0) {
            //get the customer details
            string LoanNumber = value[0];
            string CustomerName = value[1];
            string CustomerEmail = value[2];
            string ApplyDate = value[3];
            string CutomerMobile=value[5];
            string CutomerAddress=value[7];
            string Mode = value[8];
            string Accept=value[9];

            string subject="";
            string sms_content="";
            string email_content="";

			//if the requests are approved user details are stored in the approved sheet
            if(Accept=="A"){
                approved_count=approved_count+1;
				//if the user prefers email send an approval notification via mail
                if(Mode=="Mail"){
                    subject = "Approval of the Loan Request" + LoanNumber;
                    email_content=createEmail(CustomerName,LoanNumber,ApplyDate,CutomerMobile,CutomerAddress,"Congratulations","Accepted");
                    sendMail(CustomerEmail, subject,email_content);
                }
				//if the user prefers sms send an rejection notification via an sms
                if(Mode=="SMS"){
                    sms_content="Hi "+CustomerName+" ! "+"This sms is sent to you to verify that your loan request has got approved ! :-)  :-) "+"\n"+"sent by winma@wso2.com";
                    sendSMS("+"+CutomerMobile,sms_content);
                }
                time:Time time = time:currentTime();
                string today = time.format("yyyy-MM-dd");
                new_values_approved[approved_count]=[LoanNumber,CustomerName,CustomerEmail,ApplyDate,today];

            }
			//if the requests are rejected user details are stored in the rejected sheet
            if(Accept=="R"){
                rejected_count=rejected_count+1;

				//if the user prefers email send a rejection notification via nail
                if(Mode=="Mail"){
                    subject = "Rejection of the Loan Request" + LoanNumber;
                    email_content=createEmail(CustomerName,LoanNumber,ApplyDate,CutomerMobile,CutomerAddress,"Sorry","Rejected");
                    sendMail(CustomerEmail, subject,email_content);
                }
				//if the user prefers sms send a rejection notification via an sms
                if(Mode=="SMS"){
                    sms_content="Hi "+CustomerName+" ! "+"This sms is sent to you to verify that your loan request has got Rejected!:-(  :-( "+"\n"+"sent by winma@wso2.com";
                    sendSMS("+"+CutomerMobile,sms_content);
                }
                time:Time time = time:currentTime();
                string today = time.format("yyyy-MM-dd");
                new_values_rejected[rejected_count]=[LoanNumber,CustomerName,CustomerEmail,ApplyDate,today];
            }
        }
        count = count + 1;
    }
	//write the accepted and rejected user details on seperate sheets
    writeOnTheSpreadSheet(new_values_approved,approved_count+1,"Approved");
    writeOnTheSpreadSheet(new_values_rejected,rejected_count+1,"Rejected");
}


//create a new email containing the message that the approval has suceeded
function createEmail(string CustomerName, string LoanNumber, string ApplyDate,string CustomerMobile,string CustomerAddress, string Congrats, string accept) returns (string) {

    return "<style type=\"text/css\" media=\"screen\">
	body { padding:0 !important; margin:0 !important; display:block !important; background:#1e1e1e; -webkit-text-size-adjust:none }
	a { color:#a88123; text-decoration:none }
	p { padding:0 !important; margin:0 !important }
	</style>

	<style media=\"only screen and (max-device-width: 480px), only screen and (max-width: 480px)\" type=\"text/css\">
	; }
	td[class='content-spacing'] { width: 15px !important; }
	div[class='h2'] { font-size: 44px !important; line-height: 48px !important; }
	}
	</style>

	</head>
	<body class=\"body\" style=\"padding:0 !important; margin:0 !important; display:block !important; background:#1e1e1e; -webkit-text-size-adjust:none\">
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#1e1e1e\">
	<tr>
	<td align=\"center\" valign=\"top\">

	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
	<tr>
	<td>
	<!-- Head -->
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#d2973b\">
	<tr>
	<td>

	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
	<tr>
	<td>


	<div class=\"h2\" style=\"color:#ffffff; font-family:Georgia, serif; min-width:auto !important; font-size:60px; line-height:64px; text-align:center\">
	<em>"+Congrats+"</em>
	</div>

	</tr>
	</table>
	</td>
	</tr>
	</table>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#ffffff\">
	<tr>
	<td>

	<div class=\"h3-1-center\" style=\"color:#1e1e1e; font-family:Georgia, serif; min-width:auto !important; font-size:20px; line-height:26px; text-align:center\">Your Loan Request Has Been "+accept+"

	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
	<tr>
	<th class=\"column-top\" style=\"font-size:0pt; line-height:0pt; padding:0; margin:0; font-weight:normal; vertical-align:top; Margin:0\" valign=\"top\" width=\"270\">
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
	<tr>
	<td>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#f4f4f4\">
	<tr>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	<td>


	<div class=\"text-1\" style=\"color:#d2973b; font-family:Arial, sans-serif; min-width:auto !important; font-size:14px; line-height:20px; text-align:left\">
	<strong>CUSTOMER DETAILS:</strong>

	</div>
	</td>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	</tr>
	</table>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#fafafa\">
	<tr>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	<td>

	<div class=\"text\" style=\"color:#1e1e1e; font-family:Arial, sans-serif; min-width:auto !important; font-size:14px; line-height:20px; text-align:left\">
	<strong>"+CustomerName+"</strong><br />
	"+CustomerAddress+"
	<br />
	"+"+"+CustomerMobile+"
	</div>

	</td>
	</tr>
	</table>
	</td>
	</tr>
	</table>
	</th>

	<th class=\"column-top\" style=\"font-size:0pt; line-height:0pt; padding:0; margin:0; font-weight:normal; vertical-align:top; Margin:0\" valign=\"top\" width=\"270\">
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
	<tr>
	<td>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#f4f4f4\">
	<tr>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	<td>

	<div class=\"text-1\" style=\"color:#d2973b; font-family:Arial, sans-serif; min-width:auto !important; font-size:14px; line-height:20px; text-align:left\">
	<strong>LOAN NUMBER:</strong> <span style=\"color: #1e1e1e;\">"+LoanNumber+"</span>
	</div>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" class=\"spacer\" style=\"font-size:0pt; line-height:0pt; text-align:center; width:100%; min-width:100%\"><tr><td height=\"10\" class=\"spacer\" style=\"font-size:0pt; line-height:0pt; text-align:center; width:100%; min-width:100%\">&nbsp;</td></tr></table>
	</td>
	</tr>
	</table>

	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#f4f4f4\">
	<tr>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	<td>

	<div class=\"text-1\" style=\"color:#d2973b; font-family:Arial, sans-serif; min-width:auto !important; font-size:14px; line-height:20px; text-align:left\">
	<strong>APPLIED DATE:</strong>
	</div>
	</td>

	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	</tr>
	</table>
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" bgcolor=\"#fafafa\">
	<tr>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	<td>

	<div class=\"text\" style=\"color:#1e1e1e; font-family:Arial, sans-serif; min-width:auto !important; font-size:14px; line-height:20px; text-align:left\">
	"+ApplyDate+"
	</div>

	</td>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	</tr>
	</table>
	</td>
	</tr>
	</table>
	</th>
	</tr>
	</table>

	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" class=\"spacer\" style=\"font-size:0pt; line-height:0pt; text-align:center; width:100%; min-width:100%\"><tr><td height\"35\" class=\"spacer\" style=\"font-size:0pt; line-height:0pt; text-align:center; width:100%; min-width:100%\">&nbsp;</td></tr></table>

	</td>
	<td class=\"content-spacing\" style=\"font-size:0pt; line-height:0pt; text-align:left\" width=\"20\"></td>
	</tr>
	</table>
	</td>
	</tr>
	</table>
	</td>
	</tr>
	</table>
	</td>
	</tr>
	</table>

	</body>
	</html>";

}

function sendMail(string customerEmail, string subject, string messageBody) {
    //Create html message
    gmail:MessageRequest message_req;
	//set the message recipient
    message_req.recipient = customerEmail;
	//set the message sender
    message_req.sender = senderEmail;
	//set the message subject
    message_req.subject = subject;
	//create the message subject
    message_req.messageBody = messageBody;
	//crate the email body using html format
    message_req.contentType = gmail:TEXT_HTML;
    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint message_req);
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

function getCustomerDetailsFromGSheet() returns (string[][]) {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");
    log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ;sheet name: "
            + sheetName);
    return values;
}

function writeOnTheSpreadSheet(string [][] new_values,int j,string sName){
	//write the values to new sheets
    string topLeftCell="A1";
    string bottomRightCell="E"+<string>j;
    gsheets4:Sheet new_sheet=check spreadsheetClient->addNewSheet(spreadsheetId,sName);
    boolean result=check spreadsheetClient->setSheetValues(spreadsheetId, sName,  topLeftCell, bottomRightCell, new_values);
	log:printInfo("Write the values to new sheet.........");
}

function sendSMS(string toMobile,string message){
	//send sms usting twilio
	string fromMobile=config:getAsString("MOBILENUMBER");
    var details = twilioEP->sendSms(fromMobile, toMobile, message);
    match details {
        twilio:SmsResponse smsResponse => io:println(smsResponse);
        twilio:TwilioError twilioError => io:println(twilioError);
    }
	log:printInfo("Sending an sms.........");
}
