public with sharing class ESignatureProductAPI extends ESignatureAPI {

	private final String accessToken;
	private Map<String, String> defaultHeaders;

	@TestVisible
	private ESignatureProductAPI(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		super(baseUrl, 'v2', accountId);

		this.accessToken = accessToken;
	}

	public static ESignatureProductAPI getInstance(
		final Url baseUrl,
		final UUID accountId,
		final String accessToken) {

		if (baseUrl == null || UUID.isEmpty(accountId)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		return new ESignatureProductAPI(baseUrl, accountId, accessToken);
	}

	override protected Map<String, String> getDefaultHeaders() {
		if (this.defaultHeaders == null) {
			this.defaultHeaders = new Map<String, String> {
				'Accept' => 'application/json',
				'Authorization' => 'Bearer '
					+ (String.isBlank(this.accessToken) ? AuthService.getAccessToken() : this.accessToken)
			};
		}
		return this.defaultHeaders;
	}

	// Serialization object for account billing plan
	@TestVisible
	private class PlanId {
		public String planId;
	}

	@TestVisible
	private class BillingPlans {
		public PlanId billingPlan;
	}

	@TestVisible
	// HACK: Workaround for API-900. Need to call another API to get the correct planId :(
	private Account addPlanId(final Account account, final Integer timeout) {
		final RestAPI.Response response = this.get(
			'billing_plan',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read account billing plan: ' + response.error);
			throw new APIException(response.error);
		}

		final BillingPlans billing = (BillingPlans)JSON.deserialize(response.body, BillingPlans.class);
		if (billing == null || billing.billingPlan == null || String.isBlank(billing.billingPlan.planId)) {
			this.log.error('API returned no plan ID.');
			return account;
		}

		return account.withPlanId(UUID.parse(billing.billingPlan.planId));
	}

	// Serialization objects for getAccount
	@TestVisible
	private class APIAccount {
		public String currentPlanId;
		public String planName;
		public String planStartDate;
		public String planEndDate;
		public String billingPeriodStartDate;
		public String billingPeriodEndDate;
		public String accountName;
		public String accountIdGuid;
		public String externalAccountId;
		public String connectPermission;
		public String suspensionStatus;
		public String suspensionDate;

		@TestVisible
		private Account.ConnectPermission getConnectPermission() {
			if (this.connectPermission == 'full') {
				return Account.ConnectPermission.Full;
			} else if (this.connectPermission == 'sendOnly') {
				return Account.ConnectPermission.SendOnly;
			} else {
				return Account.ConnectPermission.None;
			}
		}

		public Account toAccount() {
			Date psd = StringUtils.parseDate(this.planStartDate);
			Date sd = String.isBlank(this.suspensionDate) ? null : StringUtils.parseDate(this.suspensionDate);
			return new Account(
				UUID.parse(this.accountIdGuid),
				String.isBlank(this.externalAccountId) ? null : Long.valueOf(this.externalAccountId),
				this.accountName,
				String.isBlank(this.suspensionStatus) ? Product.STATUS_ACTIVE : this.suspensionStatus,
				new Account.Plan(
					UUID.parse(this.currentPlanId),
					this.planName,
					psd,
					StringUtils.parseDate(this.planEndDate)),
				new Account.Billing(
					sd == null ? StringUtils.parseDate(this.billingPeriodStartDate) : psd,
					sd == null ? StringUtils.parseDate(this.billingPeriodEndDate) : sd),
				this.getConnectPermission());
		}
	}

	@TestVisible
	private Account getAccount(final Integer timeout) {
		final RestAPI.Response response = this.get(
			'',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read account: ' + response.error);
			throw new APIException(response.error);
		}

		return this.addPlanId(
			((APIAccount)JSON.deserialize(response.body, APIAccount.class)).toAccount(),
			timeout);
	}

	// Serialization objects for getProduct
	@TestVisible
	private class ApiFeature {
		public String name;
		public String value;
	}

	@TestVisible
	private class ApiProduct {
		public List<ApiFeature> accountSettings;

		public ESignatureProduct toProduct(final Account acct) {
			Set<ESignatureProduct.Feature> features = new Set<ESignatureProduct.Feature>();
			if (Collection.isNotEmpty(this.accountSettings)) {
				for (ApiFeature accountSetting : this.accountSettings) {
					if (accountSetting.name == 'allowMergeFields' && accountSetting.value == 'true') {
						features.add(ESignatureProduct.Feature.MergeFields);
					} else if (accountSetting.name == 'allowSigningGroups' && accountSetting.value == 'true') {
						features.add(ESignatureProduct.Feature.SigningGroups);
					} else if (accountSetting.name == 'enableSMSAuthentication' && accountSetting.value == 'true') {
						features.add(ESignatureProduct.Feature.SmsAuthentication);
					} else if (accountSetting.name == 'allowServerTemplates' && accountSetting.value == 'true') {
						features.add(ESignatureProduct.Feature.Templates);
					} else if (accountSetting.name == 'allowBulkSend' && accountSetting.value == 'true') {
						features.add(ESignatureProduct.Feature.BulkSending);
					}
				}
			}
			if (acct != null && acct.connect == Account.ConnectPermission.Full) {
				features.add(ESignatureProduct.Feature.Connect);
			}
			return new ESignatureProduct(
				acct == null ? null : acct.status,
				acct != null && acct.isTrial,
				acct == null || acct.billing == null || !acct.isTrial ? null : acct.billing.endDate,
				features);
		}
	}

	public ESignatureProduct getProduct() {
		return this.getProduct(RestAPI.defaultTimeout);
	}

	public ESignatureProduct getProduct(final Integer timeout) {
		RestAPI.Response response = this.get('settings', timeout);
		if (response.hasError) {
			this.log.error('Failed to get eSignature product: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return ((ApiProduct)JSON.deserialize(response.body, ApiProduct.class))
			.toProduct(this.getAccount(timeout));
	}
}
