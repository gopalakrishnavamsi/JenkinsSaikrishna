@IsTest
public class AccountSoapAPIMock implements WebServiceMock {

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
			result.DefaultConnectConfigurationId = 1234;
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
			result.Success = true;
			result.ConnectUserName = UUID.randomUUID() + '@unit.test';
			result.ConnectConfig = '<Config/>';
			response_x.GetConnectCredentialsResult = result;
			response.put('response_x', response_x);
		} else if (requestName == 'SetConnectCredentials') {
			AccountSoapAPI.SetConnectCredentialsResponse_element response_x = new AccountSoapAPI.SetConnectCredentialsResponse_element();
			AccountSoapAPI.SetConnectCredentialsResult_element result = new AccountSoapAPI.SetConnectCredentialsResult_element();
			result.Success = true;
			result.ConnectTestResult = 'Success';
			response_x.SetConnectCredentialsResult = result;
			response.put('response_x', response_x);
		}
	}
}