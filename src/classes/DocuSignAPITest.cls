@IsTest
public class DocuSignAPITest {

	public static final String CONSOLE_VIEW_Url = 'https://unit.test/view/console';
	public static final String RECIPIENT_VIEW_Url = 'https://unit.test/view/recipient';
	public static final String SENDER_VIEW_Url = 'https://unit.test/view/sender';
	public static final String CORRECT_VIEW_Url = 'https://unit.test/view/correct';

	// Basic API success mock
	public class SuccessMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('SUCCESS');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			final String method = request.getMethod();
			final String endpoint = request.getEndpoint();

			if (method == 'GET') {
				if (endpoint.endsWith('/service_information')) {
					response.setBody('{}');
				} else if (endpoint.contains('/login_information')) {
					response.setBody('{"loginAccounts": [{"name": "Account 1 (INVALID)","accountId": "11111111","accountIdGuid": "11111111-1111-1111-1111-111111111111","baseUrl": "https://www.docusign.net/restapi/v2/accounts/11111111","isDefault": "true","userName": "Account 1 User (INVALID)","userId": "11111111-1111-1111-1111-111111111111","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "true"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "false"},{"name": "apiAccountWideAccess","value": "false"},{"name": "allowRecipientLanguageSelection","value": "true"}]},{"name": "Account 2 (VALID)","accountId": "22222222","accountIdGuid": "22222222-2222-2222-2222-222222222222","baseUrl": "https://www.docusign.net/restapi/v2/accounts/22222222","isDefault": "false","userName": "Account 2 User (VALID)","userId": "22222222-2222-2222-2222-222222222222","email": "user@example.com","siteDescription": "","loginAccountSettings": [{"name": "usesAPI","value": "false"}],"loginUserSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendAPIRequests","value": "false"},{"name": "canSendEnvelope","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowRecipientLanguageSelection","value": "true"}]}],"apiPassword": "fake-password"}');
				} else if (endpoint.endsWith('/users/11111111-1111-1111-1111-111111111111/settings')) {
					// User settings invalid for DFS
					response.setBody('{"userSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendEnvelope","value": "true"},{"name": "apiAccountWideAccess","value": "false"},{"name": "allowSendOnBehalfOf","value": "false"}]}');
				} else if (endpoint.endsWith('/users/22222222-2222-2222-2222-222222222222/settings')) {
					// User settings valid for DFS
					response.setBody('{"userSettings": [{"name": "canManageAccount","value": "true"},{"name": "canSendEnvelope","value": "true"},{"name": "apiAccountWideAccess","value": "true"},{"name": "allowSendOnBehalfOf","value": "true"}]}');
				} else if (endpoint.endsWith('/users/33333333-3333-3333-3333-333333333333/settings')) {
					// No user settings
					response.setBody('{"userSettings": null}');
				} else if (endpoint.contains('/signing_groups')) {
					response.setBody('{"groups": [{"signingGroupId": "1","groupName": "SG1","groupType": "sharedSigningGroup","created": "7/11/2016 2:28:50 PM","createdBy": "Unit Test","modified": "7/11/2016 2:28:50 PM","modifiedBy": "Unit Test","users": [{"userName": "sg1.u1","email": "sg1.u1@unit.test"},{"userName": "sg1.u2","email": "sg1.u2@unit.test"}]},{"signingGroupId": "2","groupName": "SG2","groupType": "sharedSigningGroup","created": "7/12/2016 11:51:39 AM","createdBy": "Unit Test","modified": "7/12/2016 11:51:39 AM","modifiedBy": "Unit Test"},{"signingGroupId": "3","groupName": "SG3","groupType": "sharedSigningGroup","created": "7/12/2016 11:51:50 AM","createdBy": "Unit Test","modified": "7/12/2016 11:51:50 AM","modifiedBy": "Unit Test","users": [{"userName": "sg3.u1","email": "sg3.u1@unit.test"}]}]}');
				} else if (endpoint.endsWith('/templates?include=custom_fields%2Cshared_template_folders%2Cnotifications%2Crecipients&order_by=name&order=asc')) {
					response.setBody('{"envelopeTemplates": [{"templateId": "11111111-1111-1111-1111-111111111111","name":"Template 1","shared":"true","password":"","description":"","created":"2018-05-30T01:52:37.1900000Z","lastModified": "2017-01-12T17:28:01.2230000Z","pageCount": 1,"uri": "/templates/11111111-1111-1111-1111-111111111111","folderName": "Templates","folderId": "11111111-1111-1111-1111-111111111111","folderUri": "/folders/11111111-1111-1111-1111-111111111111","owner": {"userName": "Unit Test","userId": "11111111-1111-1111-1111-111111111111","email": "unit@test.com"},"emailSubject": "Template 1","emailBlurb": "","signingLocation": "Online","authoritativeCopy": "false","enforceSignerVisibility": "false","enableWetSign": "true","allowMarkup": "false","allowReassign": "true"},{"templateId": "22222222-2222-2222-2222-222222222222","name": "Template 2","shared": "true","password": "","description": "","lastModified": "2017-01-12T22:16:05.0800000Z","pageCount": 3,"uri": "/templates/22222222-2222-2222-2222-222222222222","folderName": "Templates","folderId": "11111111-1111-1111-1111-111111111111","folderUri": "/folders/11111111-1111-1111-1111-111111111111","owner": {"userName": "Unit Test","userId": "11111111-1111-1111-1111-111111111111","email": "unit@test.com"},"emailSubject": "Template 2","emailBlurb": "","signingLocation": "Online","authoritativeCopy": "false","enforceSignerVisibility": "false","enableWetSign": "true","allowMarkup": "false","allowReassign": "true"},{"templateId": "33333333-3333-3333-3333-333333333333","name": "Template 3","shared": "true","password": "","description": "","lastModified": "2017-01-12T18:27:34.5430000Z","pageCount": 1,"uri": "/templates/33333333-3333-3333-3333-333333333333","folderName": "Templates","folderId": "11111111-1111-1111-1111-111111111111","folderUri": "/folders/11111111-1111-1111-1111-111111111111","owner": {"userName": "Unit Test","userId": "11111111-1111-1111-1111-111111111111","email": "unit@test.com"},"emailSubject": "Template 3","emailBlurb": "","signingLocation": "Online","authoritativeCopy": "false","enforceSignerVisibility": "false","enableWetSign": "true","allowMarkup": "false","allowReassign": "true"},{"templateId": "44444444-4444-4444-4444-444444444444","name": "Template 4","shared": "true","password": "","description": "Template 4","lastModified": "2017-05-03T20:33:19.0870000Z","pageCount": 1,"uri": "/templates/44444444-4444-4444-4444-444444444444","folderName": "Templates","folderId": "11111111-1111-1111-1111-111111111111","folderUri": "/folders/11111111-1111-1111-1111-111111111111","owner": {"userName": "Unit Test","userId": "11111111-1111-1111-1111-111111111111","email": "unit@test.com"},"emailSubject": "Template 4","emailBlurb": "Template 4","signingLocation": "Online","authoritativeCopy": "false","enforceSignerVisibility": "false","enableWetSign": "true","allowMarkup": "false","allowReassign": "true"}],"resultSetSize": "4","startPosition": "0","endPosition": "3","totalSetSize": "4"}');
				} else if (endpoint.contains('/templates')) {
					response.setBody('{"envelopeTemplateDefinition":{"templateId":"11111111-1111-1111-1111-111111111111","name":"Unit test","shared":"true","password":"","description":"","lastModified":"2018-05-30T01:52:37.1900000Z"},"documents":[{"documentId":"1","uri":"/envelopes/11111111-1111-1111-1111-111111111111/documents/1","name":"unit-test.pdf","order":"1","pages":"1","display":"inline","includeInDownload":"true","signerMustAcknowledge":"no_interaction","templateLocked":"false","templateRequired":"false","documentGroup":"content"}],"emailSubject":"Unit test subject","emailBlurb":"Unit test message","signingLocation":"online","autoNavigation":"true","envelopeIdStamping":"true","enforceSignerVisibility":"false","customFields":{"textCustomFields":[{"fieldId":"10026622573","name":"textField1","show":"true","required":"false","value":"textValue1"},{"fieldId":"10026622710","name":"textField2","show":"false","required":"false","value":"textValue2"}],"listCustomFields":[{"listItems":["listField2Item1","listField2Item2","listField2Item3"],"fieldId":"10026622954","name":"listField2","show":"true","required":"true","value":"listValue2"}]},"autoNavigation":"true","envelopeIdStamping":"true","notification":{"reminders":{"reminderEnabled":"true","reminderDelay":"10","reminderFrequency":"5"},"expirations":{"expireEnabled":"true","expireAfter":"11","expireWarn":"6"}},"enableWetSign":"true","allowMarkup":"false","allowReassign":"true","recipients":{"signers":[{"defaultRecipient":"false","tabs":{"signHereTabs":[{"stampType":"signature","name":"SignHere","tabLabel":"Signature ef6475cb-4361-473e-aee1-c6a05a9ef758","scaleValue":1,"optional":"false","documentId":"1","recipientId":"71237107","pageNumber":"1","xPosition":"280","yPosition":"165","tabId":"98d801f6-e8c5-41d0-a036-8e20f56869a1","templateLocked":"false","templateRequired":"false"}]},"signInEachLocation":"false","agentCanEditEmail":"false","agentCanEditName":"false","name":"SG1","email":"","signingGroupId":"11512","signingGroupName":"SG1","signingGroupUsers":[{"userName":"Fred Wade","userId":"006e21ab-f0ff-4225-9cb6-6c8f0a8e6d75","email":"fred.wade.dfs.dev@gmail.com","uri":"/users/006e21ab-f0ff-4225-9cb6-6c8f0a8e6d75"}],"recipientId":"71237107","accessCode":"","requireIdLookup":"false","routingOrder":"7","note":"","roleName":"SIGNER","deliveryMethod":"email","templateLocked":"true","templateRequired":"true","emailNotification":{"supportedLanguage":"fr","emailSubject":"fr subject","emailBody":"fr message"},"inheritEmailNotificationConfiguration":"false"}],"agents":[{"name":"","email":"","recipientId":"30320907","accessCode":"","requireIdLookup":"false","routingOrder":"5","note":"","roleName":"AGENT","templateLocked":"false","templateRequired":"false","emailNotification":{"supportedLanguage":"bg","emailSubject":"bg subject","emailBody":"bg message"},"inheritEmailNotificationConfiguration":"false"}],"editors":[{"name":"","email":"","recipientId":"56417782","accessCode":"","requireIdLookup":"false","routingOrder":"6","note":"","roleName":"EDITOR","templateLocked":"false","templateRequired":"false","inheritEmailNotificationConfiguration":"false"}],"intermediaries":[{"name":"","email":"","recipientId":"65335900","accessCode":"1234","requireIdLookup":"false","routingOrder":"1","note":"","roleName":"INTERMEDIARY","templateLocked":"false","templateRequired":"false","inheritEmailNotificationConfiguration":"false"}],"carbonCopies":[{"name":"","email":"","recipientId":"99506488","accessCode":"","requireIdLookup":"true","idCheckConfigurationName":"Phone Auth $","phoneAuthentication":{"recipMayProvideNumber":"false","validateRecipProvidedNumber":"false","recordVoicePrint":"false","senderProvidedNumbers":["+1 415-555-5555"]},"routingOrder":"3","note":"","roleName":"CARBON_COPY","templateLocked":"false","templateRequired":"false","inheritEmailNotificationConfiguration":"false"}],"certifiedDeliveries":[{"name":"","email":"","recipientId":"50289856","accessCode":"","requireIdLookup":"false","routingOrder":"4","note":"unit test","roleName":"CERTIFIED_DELIVERY","templateLocked":"false","templateRequired":"false","inheritEmailNotificationConfiguration":"false"}],"inPersonSigners":[{"hostName":"","hostEmail":"h1@unit.test","signerName":"In-Person Signer","signerEmail":"","tabs":{"signHereTabs":[{"stampType":"signature","name":"SignHere","tabLabel":"Signature ca3176c6-6727-4719-b1a9-558a88f1d77b","scaleValue":1,"optional":"false","documentId":"1","recipientId":"72817924","pageNumber":"1","xPosition":"289","yPosition":"85","tabId":"749feca3-2060-4fba-9e10-644c34b0f4c3","templateLocked":"false","templateRequired":"false"}]},"recipientId":"72817924","accessCode":"","requireIdLookup":"false","routingOrder":"2","note":"","roleName":"IN_PERSON_SIGNER","templateLocked":"false","templateRequired":"false","inheritEmailNotificationConfiguration":"false"}],"seals":[],"recipientCount":"7"}}');
				} else if (endpoint.endsWith('/custom_fields')) {
					response.setBody('{"listCustomFields": [{"name": "listField1","required": "true","show": "true","value": "listValue1","listItems": ["listField1Item1","listField1Item2"]},{"name": "listField2","required": "true","show": "true","value": "listValue2","listItems": ["listField2Item1","listField2Item2","listField2Item3"]}],"textCustomFields": [{"name": "textField1","required": "false","show": "true","value": "textValue1"}]}');
				} else if (endpoint.endsWith('/recipients?include_tabs=false')) {
					response.setBody('{"signers": [{"creationReason": "sender","isBulkRecipient": "false","name": "Signer Dude","email": "signer2@test.com","recipientId": "2","recipientIdGuid": "11111111-1111-1111-1111-111111111111","requireIdLookup": "true","idCheckConfigurationName": "SMS Auth $","smsAuthentication": {"senderProvidedNumbers": ["+15555555555"]},"userId": "11111111-1111-1111-1111-111111111111","routingOrder": "2","roleName": "Signer 2","status": "created"},{"creationReason": "sender","isBulkRecipient": "false","name": "Signer Dude","email": "signer3@test.com","recipientId": "3","recipientIdGuid": "22222222-2222-2222-2222-222222222222","requireIdLookup": "true","idCheckConfigurationName": "SMS Auth $","smsAuthentication": {"senderProvidedNumbers": ["+15555555555"]},"userId": "11111111-1111-1111-1111-111111111111","routingOrder": "3","roleName": "Signer 3","status": "created"}],"agents": [{"name": "Agent 1","email": "agent@test.com","recipientId": "6","routingOrder": "6","status": "created"}],"editors": [{"name": "Editor 1","email": "editor@test.com","recipientId": "7","routingOrder": "7","status": "created"}],"intermediaries": [{"name": "Intermediary 1","email": "intermediary@test.com","recipientId": "8","routingOrder": "8","status": "created"}],"carbonCopies": [{"name": "Carbon Copy 1","email": "carbon.copy@test.com","recipientId": "4","routingOrder": "4","status": "created"}],"certifiedDeliveries": [{"name": "Certified Delivery 1","email": "certified.delivery@test.com","recipientId": "5","routingOrder": "5","status": "created"}],"inPersonSigners": [{"hostName": "Hosty McHosterston","hostEmail": "host@test.com","signerName": "Signy McSignerston","signerEmail": "signer@test.com","recipientId": "1","routingOrder": "1","roleName": "Signer 1","status": "delivered"}],"recipientCount": "8","currentRoutingOrder": "1"}');
				} else if (endpoint.contains('/recipient_names')) {
					response.setBody('{"recipientNames":["name1", "name2"]}');
				} else if (endpoint.endsWith('/settings')) {
					response.setBody('{"accountSettings": [{"name": "adoptSigConfig","value": "true"},{"name": "allowAccessCodeFormat","value": "false"},{"name": "allowAccountManagementGranular","value": "false"},{"name": "allowBulkSend","value": "true"},{"name": "allowCDWithdraw","value": "false"},{"name": "allowConnectSendFinishLater","value": "false"},{"name": "allowConsumerDisclosureOverride","value": "false"},{"name": "allowDataDownload","value": "true"},{"name": "allowDocumentDisclosures","value": "false"},{"name": "allowEHankoStamps","value": "false"},{"name": "allowENoteEOriginal","value": "false"},{"name": "allowEnvelopeCorrect","value": "true"},{"name": "allowEnvelopePublishReporting","value": "true"},{"name": "allowExpressSignerCertificate","value": "false"},{"name": "allowExternalSignaturePad","value": "false"},{"name": "allowInPerson","value": "true"},{"name": "allowMarkup","value": "false"},{"name": "allowMemberTimezone","value": "true"},{"name": "allowMergeFields","value": "true"},{"name": "allowMultipleSignerAttachments","value": "false"},{"name": "allowOfflineSigning","value": "true"},{"name": "allowOpenTrustSignerCertificate","value": "false"},{"name": "allowOrganizations","value": "false"},{"name": "allowPaymentProcessing","value": "true"},{"name": "allowPhoneAuthentication","value": "true"},{"name": "allowPhoneAuthOverride","value": "false"},{"name": "allowPrivateSigningGroups","value": "false"},{"name": "allowReminders","value": "true"},{"name": "allowSafeBioPharmaSignerCertificate","value": "false"},{"name": "allowServerTemplates","value": "true"},{"name": "allowSharedTabs","value": "true"},{"name": "allowSignatureStamps","value": "false"},{"name": "allowSignDocumentFromHomePage","value": "true"},{"name": "allowSignerReassign","value": "true"},{"name": "allowSignerReassignOverride","value": "true"},{"name": "allowSigningGroups","value": "true"},{"name": "allowSupplementalDocuments","value": "false"},{"name": "allowTabOrder","value": "false"},{"name": "allowWorkspaceComments","value": "true"},{"name": "allowWorkspaceCreate","value": "false"},{"name": "allowWorkspaceMemberCreate","value": "false"},{"name": "attachCompletedEnvelope","value": "true"},{"name": "authenticationCheck","value": "initial_access"},{"name": "autoNavRule","value": "required_fields"},{"name": "autoProvisionSignerAccount","value": "false"},{"name": "bulkSend","value": "true"},{"name": "canSelfBrandSend","value": "true"},{"name": "canSelfBrandSign","value": "true"},{"name": "captureVoiceRecording","value": "false"},{"name": "conditionalFieldsEnabled","value": "true"},{"name": "consumerDisclosureFrequency","value": "once"},{"name": "dataFieldRegexEnabled","value": "false"},{"name": "dataFieldSizeEnabled","value": true},{"name": "dataPopulationScope","value": "document"},{"name": "disableMobilePushNotifications","value": "true"},{"name": "disableMobileSending","value": "false"},{"name": "disableMultipleSessions","value": "false"},{"name": "disableUploadSignature","value": "false"},{"name": "disableUserSharing","value": "false"},{"name": "documentConversionRestrictions","value": "no_restrictions"},{"name": "enableAccessCodeGenerator","value": "false"},{"name": "enableAdvancedPayments","value": "false"},{"name": "enableAutoNav","value": "false"},{"name": "enableCalculatedFields","value": "true"},{"name": "enableDSPro","value": "false"},{"name": "enableEnvelopeStampingByAccountAdmin","value": "false"},{"name": "enablePaymentProcessing","value": "false"},{"name": "enablePowerForm","value": "true"},{"name": "enablePowerFormDirect","value": "true"},{"name": "enableRecipientDomainValidation","value": "false"},{"name": "enableRequireSignOnPaper","value": "false"},{"name": "enableReservedDomain","value": "false"},{"name": "enableSendToAgent","value": "true"},{"name": "enableSendToIntermediary","value": "true"},{"name": "enableSendToManage","value": "true"},{"name": "enableSequentialSigningAPI","value": "true"},{"name": "enableSequentialSigningUI","value": "true"},{"name": "enableSignerAttachments","value": "true"},{"name": "enableSigningExtensionComments","value": "false"},{"name": "enableSigningExtensionConversations","value": "false"},{"name": "enableSignOnPaper","value": "true"},{"name": "enableSignOnPaperOverride","value": "false"},{"name": "enableSignWithNotary","value": "false"},{"name": "enableSMSAuthentication","value": "true"},{"name": "enableTransactionPoint","value": "true"},{"name": "enableVaulting","value": "false"},{"name": "enableWorkspaces","value": "true"},{"name": "envelopeIntegrationAllowed","value": "full"},{"name": "envelopeIntegrationEnabled","value": "true"},{"name": "envelopeStampingDefaultValue","value": "false"},{"name": "externalSignaturePadType","value": "none"},{"name": "faxOutEnabled","value": "false"},{"name": "hideAccountAddressInCoC","value": "false"},{"name": "idCheckExpire","value": "always"},{"name": "idCheckExpireDays","value": "0"},{"name": "idCheckRequired","value": "optional"},{"name": "inSessionEnabled","value": "true"},{"name": "inSessionSuppressEmails","value": "true"},{"name": "maximumSigningGroups","value": "50"},{"name": "maximumUsersPerSigningGroup","value": "50"},{"name": "mobileSessionTimeout","value": "0"},{"name": "phoneAuthRecipientMayProvidePhoneNumber","value": "false"},{"name": "pkiSignDownloadedPDFDocs","value": "yes_sign"},{"name": "recipientsCanSignOffline","value": "true"},{"name": "requireDeclineReason","value": "false"},{"name": "requireSignerCertificateType","value": "none"},{"name": "savingCustomTabsEnabled","value": "true"},{"name": "selfSignedRecipientEmailDocument","value": "include_pdf"},{"name": "selfSignedRecipientEmailDocumentUserOverride","value": "false"},{"name": "senderMustAuthenticateSigning","value": "false"},{"name": "sendToCertifiedDeliveryEnabled","value": "true"},{"name": "sessionTimeout","value": "20"},{"name": "setRecipEmailLang","value": "true"},{"name": "setRecipSignLang","value": "true"},{"name": "sharedCustomTabsEnabled","value": "true"},{"name": "signatureProviders","value": "universalsignaturepen_default"},{"name": "signDateFormat","value": "M/d/yyyy"},{"name": "signerAttachCertificateToEnvelopePDF","value": "false"},{"name": "signerAttachConcat","value": "false"},{"name": "signerCanCreateAccount","value": "true"},{"name": "signerCanSignOnMobile","value": "true"},{"name": "signerInSessionUseEnvelopeCompleteEmail","value": "false"},{"name": "signerLoginRequirements","value": "login_not_required"},{"name": "signerMustHaveAccount","value": "false"},{"name": "signerMustLoginToSign","value": "false"},{"name": "signerShowSecureFieldInitialValues","value": "false"},{"name": "signTimeShowAmPm","value": "false"},{"name": "skipAuthCompletedEnvelopes","value": "false"},{"name": "supplementalDocumentsMustAccept","value": "false"},{"name": "supplementalDocumentsMustRead","value": "false"},{"name": "supplementalDocumentsMustView","value": "false"},{"name": "tabDataLabelEnabled","value": "false"},{"name": "tabLockingEnabled","value": "true"},{"name": "tabTextFormattingEnabled","value": "false"},{"name": "useAccountLevelEmail","value": "true"},{"name": "useConsumerDisclosure","value": "true"},{"name": "useConsumerDisclosureWithinAccount","value": "false"},{"name": "usesAPI","value": "false"},{"name": "useSignatureProviderPlatform","value": "false"}]}');
				} else if (endpoint.endsWith('/tab_definitions')) {
					response.setBody('{"tabs": [{"anchor": "Field 1 anchor","font": "default","bold": "false","italic": "false","underline": "false","fontColor": "default","fontSize": "default","items": ["one","two"],"customTabId": "11111111-1111-1111-1111-111111111111","initialValue": "","disableAutoSize": "false","concealValueOnDocument": "false","locked": "false","required": "false","shared": "false","tabLabel": "Field 1","maximumLength": "","name": "Field 1 name","type": "text","validationMessage": "","validationPattern": "","lastModified": "2017-03-13T11:43:33.882Z","lastModifiedByUserId": "","createdByUserId": "11111111-1111-1111-1111-111111111111","createdByDisplayName": "Unit test","editable": "true"},{"font": "tahoma","bold": "true","italic": "true","underline": "true","fontColor": "brightBlue","fontSize": "size24","customTabId": "22222222-2222-2222-2222-222222222222","initialValue": "Field 2 value","disableAutoSize": "true","concealValueOnDocument": "true","locked": "true","required": "true","shared": "true","tabLabel": "Field 2","maximumLength": "50","name": "Field 2 name","type": "email","validationMessage": "You fail","validationPattern": "w+","lastModifiedByUserId": "","createdByUserId": "11111111-1111-1111-1111-111111111111","createdByDisplayName": "Unit test","editable": "true","mergeField": {"configurationType": "salesforce","path": "Opportunity.Id","writeBack": "false","allowSenderToEdit": "false"}},{"font": "helvetica","bold": "true","italic": "false","underline": "false","fontColor": "gold","fontSize": "size11","customTabId": "33333333-3333-3333-3333-333333333333","initialValue": "","disableAutoSize": "false","concealValueOnDocument": "false","locked": "false","required": "false","shared": "false","tabLabel": "Field 3","maximumLength": "","name": "Field 3 name","type": "something","validationMessage": "","validationPattern": "","lastModifiedByUserId": "","createdByUserId": "11111111-1111-1111-1111-111111111111","createdByDisplayName": "Unit test","editable": "true","mergeField": {"configurationType": "salesforce","path": "Account.Name","writeBack": "true","allowSenderToEdit": "true"}}]}');
				} else if (endpoint.contains('/users/')) {
					response.setBody('{"userStatus": "Active"}');
				} else if (endpoint.endsWith('/billing_plan')) {
					response.setBody('{"billingPlan": {"planId": "704ae4d9-8fee-0550-b1d8-09890b16d8a0","planName": "Unit Test","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
				} else if (endpoint.contains('/envelopes')) {
					response.setBody('{"status":"completed","emailSubject":"Unit test subject","emailBlurb":"Unit test message","envelopeId":"11111111-1111-1111-1111-111111111111","createdDateTime":"2018-04-18T22:05:43.7670000Z","lastModifiedDateTime":"2018-04-18T22:05:51.0800000Z","deliveredDateTime":"2018-04-18T22:06:15.1370000Z","initialSentDateTime":"2018-04-18T22:05:51.6100000Z","sentDateTime":"2018-04-18T22:06:06.2770000Z","completedDateTime":"2018-04-18T22:06:22.5730000Z","statusChangedDateTime":"2018-04-18T22:06:22.5730000Z","recipients":{"signers":[{"signerName":"Signer","signerEmail":"signer@unit.test","recipientId":"1","recipientIdGuid":"11111111-1111-1111-1111-111111111111","userId":"11111111-1111-1111-1111-111111111111","routingOrder":"1","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"agents":[{"name":"Agent","email":"agent@unit.test","recipientId":"2","recipientIdGuid":"22222222-2222-2222-2222-222222222222","userId":"22222222-2222-2222-2222-222222222222","routingOrder":"2","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"editors":[{"name":"Editor","email":"editor@unit.test","recipientId":"3","recipientIdGuid":"33333333-3333-3333-3333-333333333333","userId":"33333333-3333-3333-3333-333333333333","routingOrder":"3","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"intermediaries":[{"name":"Intermediary","email":"intermediary@unit.test","recipientId":"4","recipientIdGuid":"44444444-4444-4444-4444-444444444444","userId":"44444444-4444-4444-4444-444444444444","routingOrder":"4","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"carbonCopies":[{"name":"Carbon Copy","email":"carbon.copy@unit.test","recipientId":"5","recipientIdGuid":"55555555-5555-5555-5555-555555555555","userId":"55555555-5555-5555-5555-555555555555","routingOrder":"5","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"certifiedDeliveries":[{"name":"Certified Delivery","email":"carbon.copy.1@unit.test","recipientId":"6","recipientIdGuid":"66666666-6666-6666-6666-666666666666","userId":"66666666-6666-6666-6666-666666666666","routingOrder":"6","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}],"inPersonSigners":[{"hostName":"Host","hostEmail":"host@unit.test","signerName":"In Person Signer","signerEmail":"in.person.signer@unit.test","recipientId":"7","recipientIdGuid":"77777777-7777-7777-7777-777777777777","userId":"77777777-7777-7777-7777-777777777777","routingOrder":"7","status":"completed","signedDateTime":"2018-04-18T22:06:05.0430000Z","deliveredDateTime":"2018-04-18T22:05:57.9470000Z"}]}}');
				} else { // GET account
					response.setBody('{"currentPlanId": "d1d8e549-4f0f-464a-a474-813b21c659da","planName": "DEVCENTER_DEMO_APRIL2013","planStartDate": "2017-01-05T17:54:37.1800000Z","planEndDate": "2018-01-05T17:54:37.1800000Z","billingPeriodStartDate": "2017-01-05T08:00:00.0000000Z","billingPeriodEndDate": "2017-02-05T08:00:00.0000000Z","billingPeriodEnvelopesSent": "4","billingPeriodEnvelopesAllowed": "unlimited","billingPeriodDaysRemaining": "0","canUpgrade": "false","canCancelRenewal": "false","envelopeSendingBlocked": "false","envelopeUnitPrice": "$0.00","suspensionStatus": "","accountName": "DocuSign","connectPermission": "full","docuSignLandingUrl": "http://www.docusign.com/products/sign_up/buy_now.php","distributorCode": "DEVCENTER_DEMO_APRIL2013","accountIdGuid": "67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode": "USD","forgottenPasswordQuestionsCount": "1","paymentMethod": "purchase_order","seatsAllowed": "unlimited","seatsInUse": "1","createdDate": "2017-01-05T17:54:36.7770000Z","isDowngrade": "false","billingProfile": "web","allowTransactionRooms": "false"}');
				}
			} else if (method == 'POST') {
				if (endpoint.endsWith('/oauth2/token')) {
					response.setBody('{"access_token":"unit.test"}');
				} else if (endpoint.endsWith('/oauth2/revoke')) {
					// Do nothing
				} else if (endpoint.endsWith('/views/sender')) {
					response.setBody('{"url":"' + SENDER_VIEW_Url + '"}');
				} else if (endpoint.endsWith('/views/recipient')) {
					response.setBody('{"url":"' + RECIPIENT_VIEW_Url + '"}');
				} else if (endpoint.endsWith('/views/console')) {
					response.setBody('{"url":"' + CONSOLE_VIEW_Url + '"}');
				} else if (endpoint.endsWith('/views/correct')) {
					response.setBody('{"url":"' + CORRECT_VIEW_Url + '"}');
				} else if (endpoint.endsWith('/tab_definitions')) {
					response.setBody('{"customTabId":"11111111-1111-1111-1111-111111111111"}');
				} else if (endpoint.endsWith('/users')) {
					response.setBody(request.getBody());
				} else if (endpoint.endsWith('/accounts')) {
					response.setBody('{"newAccounts":[{"accountId":"111111","accountIdGuid":"11111111-1111-1111-1111-111111111111","accountName":"UNIT TEST","userId":"22222222-2222-2222-2222-222222222222","apiPassword":"fake-password","baseUrl":"https://unit.test.docusign.net/restapi/v2/111111"}]}');
				} else if (endpoint.endsWith('/envelopes')) {
					response.setBody('{"envelopeId":"11111111-1111-1111-1111-111111111111"}');
				}
			} else if (method == 'PUT') {
				if (endpoint.endsWith('recipients?resend_envelope=true')) {
					response.setBody('{"recipientUpdateResults": [{"recipientId": "1","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "2","errorDetails": {"errorCode": "UNIT_TEST","message": "Unit test error 1"}},{"recipientId": "3","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "4","errorDetails": {"errorCode": "SUCCESS","message": null}},{"recipientId": "5","errorDetails": {"errorCode": "UNKNOWN_ENVELOPE_RECIPIENT","message": "Recipient not found"}},{"recipientId": "6","errorDetails": {"errorCode": "SUCCESS","message": null}}]}');
				} else if (endpoint.endsWith('/recipients')) {
					response.setBody('{}');
				} else if (endpoint.contains('/tab_definitions')) {
					response.setBody('{"customTabId":"22222222-2222-2222-2222-222222222222"}');
				} else { // update envelope (currently only void)
					response.setBody('{}');
				}
			} else if (method == 'DELETE') {
				if (endpoint.endsWith('/users')) {
					response.setBody(request.getBody());
				} else {
					response.setBody('{}');
				}
			}

			return response;
		}
	}

	// Basic API failure mock
	public class FailureMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			final String method = request.getMethod();
			final String endpoint = request.getEndpoint();
			response.setStatus('FAILURE');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"errorCode":"boo","message":"don\'t do that"}');
			if (method == 'GET') {
				if (endpoint.contains('/service_information')) {
					throw new CalloutException('fail');
				} else if (endpoint.contains('/login_information')) {
					response.setStatusCode(400);
					response.setBody('{"errorCode":"USER_AUTHENTICATION_FAILED","message":"dunno"}');
				} else if (endpoint.contains('11111111-1111-1111-1111-111111111111/signing_groups')) {
					response.setStatusCode(400);
					response.setBody('{"errorCode":"ACCOUNT_LACKS_PERMISSIONS","message":"just stop"}');
				} else if (endpoint.contains('/signing_groups')) {
					response.setStatusCode(400);
					response.setBody('{"errorCode":"WHATEVER","message":"just stop"}');
				} else if (endpoint.endsWith('/users/11111111-1111-1111-1111-111111111111/settings')) {
					response.setStatusCode(400);
				} else if (endpoint.endsWith('/templates?include=custom_fields%2Cshared_template_folders%2Cnotifications%2Crecipients&order_by=name&order=asc')) {
					response.setStatusCode(400);
				} else if (endpoint.contains('/templates')) {
					response.setStatusCode(404);
				} else if (endpoint.endsWith('/custom_fields')) {
					response.setStatusCode(422);
				} else if (endpoint.endsWith('/recipients?include_tabs=false')) {
					response.setStatusCode(415);
				} else if (endpoint.contains('/recipient_names')) {
					response.setStatusCode(400);
				} else { // Any others use 400 BAD_REQUEST
					response.setStatusCode(400);
				}
			} else if (method == 'POST') {
				if (endpoint.endsWith('/oauth2/token')) {
					response.setStatusCode(400);
				} else if (endpoint.endsWith('/oauth2/revoke')) {
					response.setStatusCode(500);
				} else if (endpoint.endsWith('/views/recipient')) {
					response.setStatusCode(404);
				} else if (endpoint.endsWith('/views/console')) {
					response.setStatusCode(422);
				} else { // Any others use 400 BAD_REQUEST
					response.setStatusCode(400);
				}
			} else if (method == 'PUT') {
				if (endpoint.endsWith('resend_envelope=true')) {
					response.setStatusCode(415);
				} else if (endpoint.endsWith('/recipients')) {
					response.setStatusCode(400);
				} else { // Any others use 400 BAD_REQUEST
					response.setStatusCode(400);
				}
			} else { // Any others use 400 BAD_REQUEST
				response.setStatusCode(400);
			}

			return response;
		}
	}

	// API Mock that returns 401 UNAUTHORIZED
	public class UnauthorizedMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			final HttpResponse response = new HttpResponse();
			response.setStatusCode(401);
			response.setStatus('UNAUTHORIZED');
			return response;
		}
	}

	@IsTest
	static void test_ErrorDetails() {
		DocuSignAPI.ErrorDetails ed1 = new DocuSignAPI.ErrorDetails();
		ed1.errorCode = 'SUCCESS';
		ed1.message = 'No error';
		DocuSignAPI.ErrorDetails ed2 = new DocuSignAPI.ErrorDetails();
		ed2.errorCode = 'INVALID_PASSWORD';
		ed2.message = 'Invalid password';
		DocuSignAPI.ErrorDetails ed3 = new DocuSignAPI.ErrorDetails();
		ed3.errorCode = 'AUTHORIZATION_INVALID_TOKEN';
		ed3.message = 'Authorization invalid token';
		DocuSignAPI.ErrorDetails ed4 = new DocuSignAPI.ErrorDetails();
		ed4.errorCode = 'USER_AUTHENTICATION_FAILED';
		ed4.message = 'User authentication failed';
		DocuSignAPI.ErrorDetails ed5 = new DocuSignAPI.ErrorDetails();
		ed5.errorCode = 'SOME_ERROR';
		ed5.message = 'Some error';

		Test.startTest();
		APIError e1 = ed1.toExternalForm();
		APIError e2 = ed2.toExternalForm();
		APIError e3 = ed3.toExternalForm();
		APIError e4 = ed4.toExternalForm();
		APIError e5 = ed5.toExternalForm();
		Test.stopTest();

		System.assertEquals(APIError.none, e1);

		System.assertNotEquals(null, e2);
		System.assert(e2 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e2.code);
		System.assertEquals('Invalid password', e2.description);
		System.assertEquals('INVALID_PASSWORD', ((DocuSignAPI.Error)e2).docuSignCode);

		System.assertNotEquals(null, e3);
		System.assert(e3 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e3.code);
		System.assertEquals('Authorization invalid token', e3.description);
		System.assertEquals('AUTHORIZATION_INVALID_TOKEN', ((DocuSignAPI.Error)e3).docuSignCode);

		System.assertNotEquals(null, e4);
		System.assert(e4 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, e4.code);
		System.assertEquals('User authentication failed', e4.description);
		System.assertEquals('USER_AUTHENTICATION_FAILED', ((DocuSignAPI.Error)e4).docuSignCode);

		System.assertNotEquals(null, e5);
		System.assert(e5 instanceof DocuSignAPI.Error);
		System.assertEquals(APIErrorCode.BAD_REQUEST, e5.code);
		System.assertEquals('Some error', e5.description);
		System.assertEquals('SOME_ERROR', ((DocuSignAPI.Error)e5).docuSignCode);
	}

	@IsTest
	static void test_constructor_default_creds() {
		System.runAs(TestUtils.createDocuSignAdministrator()) {
			TestUtils.createAccountConfiguration();
		}

		System.runAs(TestUtils.createDocuSignUser()) {
			Credentials credentials = Credentials.getInstance();
			System.assertNotEquals(null, credentials);
			System.assert(credentials.isValid);

			Test.startTest();
			DocuSignAPI c = DocuSignAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, c);
			DocuSignAPI.LegacyCredentials lc = (DocuSignAPI.LegacyCredentials)JSON.deserialize(c.legacyAuthHeader,
				DocuSignAPI.LegacyCredentials.class);
			System.assertEquals(credentials.username, lc.Username);
			System.assertEquals(credentials.password, lc.Password);
			System.assertEquals(Application.INTEGRATOR_KEY, lc.IntegratorKey);
			System.assertEquals(credentials.sendOnBehalfOf, lc.SendOnBehalfOf);
			System.assertEquals(new Map<String, String> {
				'Content-Type' => 'application/json',
				'Accept' => 'application/json',
				'X-DocuSign-Authentication' => c.legacyAuthHeader
			}, c.defaultHeaders);
			System.assertNotEquals(null, c.baseUrl);
			System.assertNotEquals(null, c.environment);
			System.assertEquals(Environment.Target.Other, c.environment.environment);
			System.assertEquals(credentials.environment.baseUrl.toExternalForm(), c.baseUrl.toExternalForm());
			System.assertEquals(Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c), RestAPI.defaultTimeout);
		}
	}

	@IsTest
	static void test_constructor_non_default_creds() {
		TestUtils.createAccountConfiguration();
		final Credentials creds = new Credentials(
			Environment.demo,
			UUID.randomUUID(),
			UUID.randomUUID().toString(),
			UUID.randomUUID().toString(),
			true,
			UUID.randomUUID().toString(),
			true);

		Test.startTest();
		final DocuSignAPI c = new DocuSignAPI(creds);
		Test.stopTest();

		System.assertNotEquals(null, c);
		DocuSignAPI.LegacyCredentials lc = (DocuSignAPI.LegacyCredentials)JSON.deserialize(c.legacyAuthHeader, DocuSignAPI.LegacyCredentials.class);
		System.assertEquals(creds.username, lc.Username);
		System.assertEquals(creds.password, lc.Password);
		System.assertEquals(Application.INTEGRATOR_KEY, lc.IntegratorKey);
		System.assertEquals(creds.sendOnBehalfOf, lc.SendOnBehalfOf);
		System.assertEquals(new Map<String, String> {
			'Content-Type' => 'application/json',
			'Accept' => 'application/json',
			'X-DocuSign-Authentication' => c.legacyAuthHeader
		}, c.defaultHeaders);
		System.assertNotEquals(null, c.baseUrl);
		System.assertEquals(
			creds.environment.baseUrl.toExternalForm(),
			c.baseUrl.toExternalForm());
		System.assertEquals(Environment.Target.Demo, c.environment.environment);
		System.assertEquals(
			Integer.valueOf(AccountSettings__c.getOrgDefaults().CalloutTimeout__c),
			RestAPI.defaultTimeout);
	}

	@IsTest
	static void test_constructor_failure() {
		Test.startTest();
		try {
			new DocuSignAPI(Credentials.getInstance(null, null, null));
			throw new AssertException('Expected DocuSignAPI constructor to throw exception when an account is not configured');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getBaseUrl_success() {
		System.runAs(TestUtils.createDocuSignUser()) {
			UUID accountID = TestUtils.createAccountConfiguration();
			DocuSignAPI client = DocuSignAPI.getInstance();

			Test.startTest();
			Url u = client.getBaseUrl();
			Test.stopTest();

			System.assertNotEquals(null, u);
			System.assertEquals(TestUtils.BASE_Url + 'restapi/v2/accounts/' + accountID + '/', u.toExternalForm());
		}
	}

	@IsTest
	static void test_getBaseUrl_failure() {
		Test.startTest();
		try {
			new DocuSignAPI(new Credentials(Environment.production, null, null, null, false, null, false))
				.getBaseUrl();
			throw new AssertException('Expected getBaseUrl to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getError_exception() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			DocuSignAPI client = DocuSignAPI.getInstance();
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			Test.startTest();
			APIError error = client.getError(response);
			Test.stopTest();

			System.assertNotEquals(null, error);
			System.assertEquals(400, error.code);
			System.assertEquals('BAD_REQUEST', error.description);
		}
	}

	@IsTest
	static void test_getError_unauthorized() {
		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();
			DocuSignAPI client = DocuSignAPI.getInstance();
			HttpResponse response = new HttpResponse();
			response.setStatusCode(401);
			response.setStatus('UNAUTHORIZED');
			UnauthorizedException ex;

			Test.startTest();
			try {
				client.getError(response);
				throw new AssertException('Expected getError to throw UnauthorizedException');
			} catch (UnauthorizedException ex1) {
				ex = ex1;
			}
			Test.stopTest();

			System.assertNotEquals(null, ex);
			System.assertEquals(Label.MustBeActivated, ex.getMessage());
			System.assertEquals(UserInfo.getUserId(), ex.userId);
			System.assertEquals(UnauthorizedException.AccessRequirement.DocuSignUser, ex.requirement);
		}
	}

	@IsTest
	static void test_ping_success() {
		Test.setMock(HttpCalloutMock.class, new SuccessMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assert(DocuSignAPI.getInstance().ping());
			Test.stopTest();
		}
	}

	@IsTest
	static void test_ping_failure() {
		Test.setMock(HttpCalloutMock.class, new FailureMock());

		System.runAs(TestUtils.createDocuSignUser()) {
			TestUtils.createAccountConfiguration();

			Test.startTest();
			System.assert(!DocuSignAPI.getInstance().ping());
			Test.stopTest();
		}
	}
}
