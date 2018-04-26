public class AccountSoapAPI {

	private static final String APP_TOKEN = 'DSFS_SOBO';

	public class GetProvisioningInformationResponse_element {
		public AccountSoapAPI.GetProvisioningInformationResult_element GetProvisioningInformationResult;
		private String[] GetProvisioningInformationResult_type_info = new String[] { 'GetProvisioningInformationResult', 'http://www.docusign.net/API/AccountManagement', 'GetProvisioningInformationResult_element', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'GetProvisioningInformationResult' };
	}
	public class GetProvisioningInformationResult_element {
		public String DistributorCode;
		public String DistributorPassword;
		public String Pgp;
		public String PlanPromoText;
		public Integer DefaultConnectConfigurationId;
		public String PasswordRuleText;
		public Boolean PurchaseOrderOrPromoAllowed;
		public Boolean Success;
		public AccountSoapAPI.RequestError Error;
		private String[] DistributorCode_type_info = new String[] { 'DistributorCode', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] DistributorPassword_type_info = new String[] { 'DistributorPassword', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] Pgp_type_info = new String[] { 'Pgp', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] PlanPromoText_type_info = new String[] { 'PlanPromoText', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] DefaultConnectConfigurationId_type_info = new String[] { 'DefaultConnectConfigurationId', 'http://www.w3.org/2001/XMLSchema', 'integer', '0', '1', 'false' };
		private String[] PasswordRuleText_type_info = new String[] { 'PasswordRuleText', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] PurchaseOrderOrPromoAllowed_type_info = new String[] { 'PurchaseOrderOrPromoAllowed', 'http://www.w3.org/2001/XMLSchema', 'boolean', '0', '1', 'false' };
		private String[] Success_type_info = new String[] { 'Success', 'http://www.w3.org/2001/XMLSchema', 'boolean', '1', '1', 'false' };
		private String[] Error_type_info = new String[] { 'Error', 'http://www.docusign.net/API/AccountManagement', 'RequestError', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'DistributorCode', 'DistributorPassword', 'Pgp', 'PlanPromoText', 'DefaultConnectConfigurationId', 'PasswordRuleText', 'PurchaseOrderOrPromoAllowed', 'Success', 'Error' };
	}
	public class SetConnectCredentialsResult_element {
		public String ConnectTestResult;
		public Boolean Success;
		public AccountSoapAPI.RequestError Error;
		private String[] ConnectTestResult_type_info = new String[] { 'ConnectTestResult', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] Success_type_info = new String[] { 'Success', 'http://www.w3.org/2001/XMLSchema', 'boolean', '1', '1', 'false' };
		private String[] Error_type_info = new String[] { 'Error', 'http://www.docusign.net/API/AccountManagement', 'RequestError', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'ConnectTestResult', 'Success', 'Error' };
	}
	public class GetConnectCredentialsResponse_element {
		public AccountSoapAPI.GetConnectCredentialsResult_element GetConnectCredentialsResult;
		private String[] GetConnectCredentialsResult_type_info = new String[] { 'GetConnectCredentialsResult', 'http://www.docusign.net/API/AccountManagement', 'GetConnectCredentialsResult_element', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'GetConnectCredentialsResult' };
	}
	public class GetProvisioningInformation_element {
		public String AppToken;
		private String[] AppToken_type_info = new String[] { 'AppToken', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'AppToken' };
	}
	public class GetConnectCredentials_element {
		public String AccountId;
		private String[] AccountId_type_info = new String[] { 'AccountId', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'AccountId' };
	}
	public class RequestError {
		public String ErrorCode;
		public String Description;
		private String[] ErrorCode_type_info = new String[] { 'ErrorCode', 'http://www.docusign.net/API/AccountManagement', 'ErrorCode', '1', '1', 'false' };
		private String[] Description_type_info = new String[] { 'Description', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'ErrorCode', 'Description' };
	}
	public class SetConnectCredentialsResponse_element {
		public AccountSoapAPI.SetConnectCredentialsResult_element SetConnectCredentialsResult;
		private String[] SetConnectCredentialsResult_type_info = new String[] { 'SetConnectCredentialsResult', 'http://www.docusign.net/API/AccountManagement', 'SetConnectCredentialsResult_element', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'SetConnectCredentialsResult' };
	}
	public class GetConnectCredentialsResult_element {
		public String ConnectUserName;
		public String ConnectConfig;
		public Boolean Success;
		public AccountSoapAPI.RequestError Error;
		private String[] ConnectUserName_type_info = new String[] { 'ConnectUserName', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] ConnectConfig_type_info = new String[] { 'ConnectConfig', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] Success_type_info = new String[] { 'Success', 'http://www.w3.org/2001/XMLSchema', 'boolean', '1', '1', 'false' };
		private String[] Error_type_info = new String[] { 'Error', 'http://www.docusign.net/API/AccountManagement', 'RequestError', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'ConnectUserName', 'ConnectConfig', 'Success', 'Error' };
	}
	public class SetConnectCredentials_element {
		public String AccountId;
		public String ConnectUsername;
		public String ConnectPassword;
		public Integer ConnectConfigurationId;
		public String SalesforceEnvironment;
		private String[] AccountId_type_info = new String[] { 'AccountId', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] ConnectUsername_type_info = new String[] { 'ConnectUsername', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] ConnectPassword_type_info = new String[] { 'ConnectPassword', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] ConnectConfigurationId_type_info = new String[] { 'ConnectConfigurationId', 'http://www.w3.org/2001/XMLSchema', 'int', '1', '1', 'false' };
		private String[] SalesforceEnvironment_type_info = new String[] { 'SalesforceEnvironment', 'http://www.w3.org/2001/XMLSchema', 'string', '0', '1', 'false' };
		private String[] apex_schema_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'true', 'false' };
		private String[] field_order_type_info = new String[] { 'AccountId', 'ConnectUsername', 'ConnectPassword', 'ConnectConfigurationId', 'SalesforceEnvironment' };
	}

	public class AccountManagementServiceSoap {
		public String endpoint_x = 'https://www.docusign.net/api/3.0/AccountManagement.asmx';
		public Map<String, String> inputHttpHeaders_x;
		public Map<String, String> outputHttpHeaders_x;
		public String clientCertName_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		public Integer timeout_x;
		private String[] ns_map_type_info = new String[] { 'http://www.docusign.net/API/AccountManagement', 'AccountSoapAPI' };

		@TestVisible
		private Integer getDefaultConnectConfigurationId() {
			AccountSoapAPI.GetProvisioningInformation_element request_x = new AccountSoapAPI.GetProvisioningInformation_element();
			AccountSoapAPI.GetProvisioningInformationResponse_element response_x;
			request_x.AppToken = APP_TOKEN;
			Map<String, AccountSoapAPI.GetProvisioningInformationResponse_element> response_map_x =
				new Map<String, AccountSoapAPI.GetProvisioningInformationResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'http://www.docusign.net/API/AccountManagement/GetProvisioningInformation',
					'http://www.docusign.net/API/AccountManagement',
					'GetProvisioningInformation',
					'http://www.docusign.net/API/AccountManagement',
					'GetProvisioningInformationResponse',
					'AccountSoapAPI.GetProvisioningInformationResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			GetProvisioningInformationResult_element result = response_x.GetProvisioningInformationResult;
			if (!result.Success) {
				throw new DocuSignException(result.Error.Description);
			}
			return Integer.valueOf(result.DefaultConnectConfigurationId);
		}

		public String getConnectUsername(final UUID accountId) {
			AccountSoapAPI.GetConnectCredentials_element request_x = new AccountSoapAPI.GetConnectCredentials_element();
			AccountSoapAPI.GetConnectCredentialsResponse_element response_x;
			request_x.AccountId = UUID.toString(accountId);
			Map<String, AccountSoapAPI.GetConnectCredentialsResponse_element> response_map_x = new Map<String, AccountSoapAPI.GetConnectCredentialsResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'http://www.docusign.net/API/AccountManagement/GetConnectCredentials',
					'http://www.docusign.net/API/AccountManagement',
					'GetConnectCredentials',
					'http://www.docusign.net/API/AccountManagement',
					'GetConnectCredentialsResponse',
					'AccountSoapAPI.GetConnectCredentialsResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			GetConnectCredentialsResult_element result = response_x.GetConnectCredentialsResult;
			if (!result.Success) {
				throw new DocuSignException(result.Error.Description);
			}
			return result.ConnectUserName;
		}

		public String setConnectCredentials(final String sfdcUsername, final String sfdcPassword) {
			AccountSoapAPI.SetConnectCredentials_element request_x = new AccountSoapAPI.SetConnectCredentials_element();
			AccountSoapAPI.SetConnectCredentialsResponse_element response_x;
			request_x.AccountId = UUID.toString(Credentials.getInstance().accountId);
			request_x.ConnectUsername = sfdcUsername;
			request_x.ConnectPassword = sfdcPassword;
			request_x.SalesforceEnvironment = new Url(Url.getSalesforceBaseUrl(), '/services/Soap/u/'
				+ Salesforce.API_VERSION).toExternalForm();
			request_x.ConnectConfigurationId = getDefaultConnectConfigurationId();
			Map<String, AccountSoapAPI.SetConnectCredentialsResponse_element> response_map_x =
				new Map<String, AccountSoapAPI.SetConnectCredentialsResponse_element>();
			response_map_x.put('response_x', response_x);
			WebServiceCallout.invoke(
				this,
				request_x,
				response_map_x,
				new String[] {
					endpoint_x,
					'http://www.docusign.net/API/AccountManagement/SetConnectCredentials',
					'http://www.docusign.net/API/AccountManagement',
					'SetConnectCredentials',
					'http://www.docusign.net/API/AccountManagement',
					'SetConnectCredentialsResponse',
					'AccountSoapAPI.SetConnectCredentialsResponse_element'
				}
			);
			response_x = response_map_x.get('response_x');
			SetConnectCredentialsResult_element result = response_x.SetConnectCredentialsResult;
			if (!result.Success) {
				if (result.Error.Description.contains('Invalid Salesforce Credentials')) {
					throw new UnauthorizedException(Label.InvalidUsernameOrPassword);
				} else {
					throw new DocuSignException(result.Error.Description);
				}
			}
			// TODO: Parse this result into something more meaningful and less fragile.
			return result.ConnectTestResult;
		}
	}

	private static AccountSoapAPI.AccountManagementServiceSoap self = null;

	public static AccountSoapAPI.AccountManagementServiceSoap getInstance() {
		if (self == null) {
			Credentials credentials = Credentials.getInstance();
			self = new AccountSoapAPI.AccountManagementServiceSoap();
			self.inputHttpHeaders_x = new Map<String, String> {
				'X-DocuSign-Authentication' => getCredentialsXml(credentials.username, credentials.password),
				'User-Agent' => Application.userAgent
			};
			self.endpoint_x = new Url(credentials.environment.baseUrl, 'api/3.0/accountmanagement.asmx').toExternalForm();
			self.timeout_x = RestAPI.defaultTimeout;
		}
		return self;
	}

	private static String getCredentialsXml(final String username, final String password) {
		XmlStreamWriter w = new XmlStreamWriter();
		w.writeStartElement(null, 'DocuSignCredentials', null);
		w.writeStartElement(null, 'Username', null);
		w.writeCharacters(username != null ? username : '');
		w.writeEndElement();
		w.writeStartElement(null, 'Password', null);
		w.writeCharacters(password != null ? password : '');
		w.writeEndElement();
		w.writeStartElement(null, 'IntegratorKey', null);
		w.writeCharacters(Application.INTEGRATOR_KEY);
		w.writeEndElement();
		w.writeEndElement();
		String xml = w.getXmlString();
		w.close();
		return xml;
	}
}
