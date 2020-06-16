@RestResource(UrlMapping = '/v1/org/*')
global with sharing class OrganizationService {

	@TestVisible
	private static final String KEY_DAILY_API_LIMIT = 'DailyApiRequests';
	@TestVisible
	private static final String KEY_EVENT_PERIOD_DAYS = 'eventPeriodDays';
	private static final Integer DEFAULT_EVENT_PERIOD_DAYS = 7;

	@TestVisible
	private class OrganizationEvents {
		public Integer days { get; private set; }
		public Integer errors { get; private set; }
		public Integer warnings { get; private set; }

		@TestVisible
		private OrganizationEvents(
			final Integer days,
			final Integer errors,
			final Integer warnings) {

			this.days = days;
			this.errors = errors;
			this.warnings = warnings;
		}
	}

	@TestVisible
	private class OrganizationLimit {
		public Integer current { get; private set; }
		public Integer maximum { get; private set; }

		@TestVisible
		private OrganizationLimit(
			final Integer current,
			final Integer maximum) {

			this.current = current;
			this.maximum = maximum;
		}
	}

	@TestVisible
	private class OrganizationInfo {
		public Id id { get; private set; }
		public String name { get; private set; }
		public String type { get; private set; }
		public Boolean isSandbox { get; private set; }
		public String packageVersion { get; private set; }
		public String accountId { get; private set; }
		public String environment { get; private set; }
		public Map<String, Object> properties { get; private set; }

		@TestVisible
		private OrganizationInfo(
			final Id id,
			final String name,
			final String type,
			final Boolean isSandbox,
			final String packageVersion,
			final String accountId,
			final String environment,
			final Map<String, Object> properties) {

			this.id = id;
			this.name = name;
			this.type = type;
			this.isSandbox = isSandbox;
			this.packageVersion = packageVersion;
			this.accountId = accountId;
			this.environment = environment;
			this.properties = properties;
		}
	}

	@TestVisible
	private static OrganizationLimit getDailyApiLimit() {
		OrganizationLimit dailyApiLimit = null;
		OrgLimit ol = OrgLimits.getMap().get(KEY_DAILY_API_LIMIT);
		if (ol != null) {
			dailyApiLimit = new OrganizationLimit(
				ol.getValue(),
				ol.getLimit());
		}
		return dailyApiLimit;
	}

	@TestVisible
	private static OrganizationEvents getEvents(final Integer eventPeriodDays) {
		Datetime since = Datetime.now().addDays(-eventPeriodDays);
		return new OrganizationEvents(
			eventPeriodDays,
		[SELECT COUNT() FROM Log__c WHERE Severity__c = 'ERROR' AND CreatedDate >= :since WITH SECURITY_ENFORCED],
		[SELECT COUNT() FROM Log__c WHERE Severity__c = 'WARN' AND CreatedDate >= :since WITH SECURITY_ENFORCED]);
	}

	@TestVisible
	private static OrganizationInfo buildOrganizationInfo(final Integer eventPeriodDays) {
		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
		return new OrganizationInfo(
			UserInfo.getOrganizationId(),
			UserInfo.getOrganizationName(),
			Salesforce.edition,
			Salesforce.isSandbox,
			String.valueOf(Application.version),
			settings.AccountId__c,
			settings.Environment__c,
			new Map<String, Object> {
				'dailyApiLimit' => getDailyApiLimit(),
				'events' => getEvents(eventPeriodDays)
			});
	}

	@HttpGet
	global static void getOrganizationInfo() { // Requires void return type to handle Map<String, Object> in response
		Permissions.verifyIsDocuSignAdministrator();

		RestRequest request = RestContext.request;
		QueryString requestParameters = new QueryString(request.params);
		OrganizationInfo orgInfo = buildOrganizationInfo(
			requestParameters.getInteger(KEY_EVENT_PERIOD_DAYS, DEFAULT_EVENT_PERIOD_DAYS));
		RestContext.response.headers.put('Content-Type', 'application/json');
		RestContext.response.responseBody = Blob.valueOf(JSON.serialize(orgInfo));
	}
}
