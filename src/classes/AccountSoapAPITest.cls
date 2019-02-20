@IsTest
public class AccountSoapAPITest {

	private static final Integer DEFAULT_CONNECT_ID = 1234;
	private static final String ERROR_CODE = 'UNIT_TEST';
	private static final String ERROR_MESSAGE = 'Unit test error';

	private class FailureMock implements WebServiceMock {
		public void doInvoke(
			Object stub,
			Object request,
			Map<String, Object> response,
			String endpoint,
			String soapAction,
			String requestName,
			String responseNS,
			String responseName,
			String responseType) {

			if (requestName == 'GetProvisioningInformation') {
				AccountSoapAPI.GetProvisioningInformationResponse_element response_x = new AccountSoapAPI.GetProvisioningInformationResponse_element();
				AccountSoapAPI.GetProvisioningInformationResult_element result = new AccountSoapAPI.GetProvisioningInformationResult_element();
				result.Success = true;
				result.DefaultConnectConfigurationId = DEFAULT_CONNECT_ID;
				result.DistributorCode = 'TestDistributorCode';
				result.DistributorPassword = 'TestDistributorPassword';
				result.PasswordRuleText = 'TestPasswordRulText';
				result.Pgp = 'TestPgp';
				result.PlanPromoText = 'TestPlanPromoText';
				response_x.GetProvisioningInformationResult = result;
				response.put('response_x', response_x);
			} else if (requestName == 'GetConnectCredentials') {
				AccountSoapAPI.GetConnectCredentialsResponse_element response_x = new AccountSoapAPI.GetConnectCredentialsResponse_element();
				AccountSoapAPI.GetConnectCredentialsResult_element result = new AccountSoapAPI.GetConnectCredentialsResult_element();
				result.Success = false;
				result.Error = new AccountSoapAPI.RequestError();
				result.Error.ErrorCode = ERROR_CODE;
				result.Error.Description = ERROR_MESSAGE;
				response_x.GetConnectCredentialsResult = result;
				response.put('response_x', response_x);
			} else if (requestName == 'SetConnectCredentials') {
				AccountSoapAPI.SetConnectCredentialsResponse_element response_x = new AccountSoapAPI.SetConnectCredentialsResponse_element();
				AccountSoapAPI.SetConnectCredentialsResult_element result = new AccountSoapAPI.SetConnectCredentialsResult_element();
				result.Success = false;
				result.Error = new AccountSoapAPI.RequestError();
				result.Error.ErrorCode = ERROR_CODE;
				result.Error.Description = ERROR_MESSAGE;
				response_x.SetConnectCredentialsResult = result;
				response.put('response_x', response_x);
			}
		}
	}

	@IsTest
	static void test_getInstance() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AccountSoapAPI.AccountManagementServiceSoap api1 = AccountSoapAPI.getInstance();
			AccountSoapAPI.AccountManagementServiceSoap api2 = AccountSoapAPI.getInstance();
			Test.stopTest();

			System.assertNotEquals(null, api1);
			System.assert(api1 === api2);
		}
	}

	@IsTest
	static void test_getDefaultConnectConfigurationId_success() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assertNotEquals(null, AccountSoapAPI.getInstance().getDefaultConnectConfigurationId());
			Test.stopTest();
		}
	}

	public class GetDefaultConnectConfigurationIdErrorMock implements WebServiceMock {
		public void doInvoke(
			Object stub,
			Object request,
			Map<String, Object> response,
			String endpoint,
			String soapAction,
			String requestName,
			String responseNS,
			String responseName,
			String responseType) {

			if (requestName == 'GetProvisioningInformation') {
				AccountSoapAPI.GetProvisioningInformationResponse_element response_x = new AccountSoapAPI.GetProvisioningInformationResponse_element();
				AccountSoapAPI.GetProvisioningInformationResult_element result = new AccountSoapAPI.GetProvisioningInformationResult_element();
				result.Success = false;
				result.Error = new AccountSoapAPI.RequestError();
				result.Error.ErrorCode = ERROR_CODE;
				result.Error.Description = ERROR_MESSAGE;
				response_x.GetProvisioningInformationResult = result;
				response.put('response_x', response_x);
			}
		}
	}

	@IsTest
	static void test_getDefaultConnectConfigurationId_failure() {
		Test.setMock(WebServiceMock.class, new GetDefaultConnectConfigurationIdErrorMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountSoapAPI.getInstance().getDefaultConnectConfigurationId();
				throw new AssertException('Expected getDefaultConnectConfigurationId to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(ERROR_MESSAGE, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_setConnectCredentials_success() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assertEquals('Success', AccountSoapAPI.getInstance().setConnectCredentials('u@unit.test',
				UUID.randomUUID().toString()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_setConnectCredentials_failure() {
		Test.setMock(WebServiceMock.class, new FailureMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountSoapAPI.getInstance().setConnectCredentials('u@unit.test', UUID.randomUUID().toString());
				throw new AssertException('Expected getDefaultConnectConfigurationId to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(ERROR_MESSAGE, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class SetConnectCredentialsUnauthorizedMock implements WebServiceMock {
		public void doInvoke(
			Object stub,
			Object request,
			Map<String, Object> response,
			String endpoint,
			String soapAction,
			String requestName,
			String responseNS,
			String responseName,
			String responseType) {

			if (requestName == 'GetProvisioningInformation') {
				AccountSoapAPI.GetProvisioningInformationResponse_element response_x = new AccountSoapAPI.GetProvisioningInformationResponse_element();
				AccountSoapAPI.GetProvisioningInformationResult_element result = new AccountSoapAPI.GetProvisioningInformationResult_element();
				result.Success = true;
				result.DefaultConnectConfigurationId = DEFAULT_CONNECT_ID;
				result.DistributorCode = 'TestDistributorCode';
				result.DistributorPassword = 'TestDistributorPassword';
				result.PasswordRuleText = 'TestPasswordRulText';
				result.Pgp = 'TestPgp';
				result.PlanPromoText = 'TestPlanPromoText';
				response_x.GetProvisioningInformationResult = result;
				response.put('response_x', response_x);
			} else if (requestName == 'SetConnectCredentials') {
				AccountSoapAPI.SetConnectCredentialsResponse_element response_x = new AccountSoapAPI.SetConnectCredentialsResponse_element();
				AccountSoapAPI.SetConnectCredentialsResult_element result = new AccountSoapAPI.SetConnectCredentialsResult_element();
				result.Success = false;
				result.Error = new AccountSoapAPI.RequestError();
				result.Error.ErrorCode = ERROR_CODE;
				result.Error.Description = 'Invalid Salesforce Credentials';
				response_x.SetConnectCredentialsResult = result;
				response.put('response_x', response_x);
			}
		}
	}

	@IsTest
	static void test_setConnectCredentials_unauthorized() {
		Test.setMock(WebServiceMock.class, new SetConnectCredentialsUnauthorizedMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountSoapAPI.getInstance().setConnectCredentials('u@unit.test', UUID.randomUUID().toString());
				throw new AssertException('Expected getDefaultConnectConfigurationId to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidUsernameOrPassword, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConnectUsername_success() {
		Test.setMock(WebServiceMock.class, new AccountSoapAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			System.assertNotEquals(null, AccountSoapAPI.getInstance().getConnectUsername(UUID.randomUUID()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getConnectUsername_failure() {
		Test.setMock(WebServiceMock.class, new FailureMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountSoapAPI.getInstance().getConnectUsername(UUID.randomUUID());
				throw new AssertException('Expected getConnectUsername to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(ERROR_MESSAGE, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}
