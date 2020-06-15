public class DocuSign {

	public static final UUID TRIAL_PLAN_ID = UUID.parse([
		SELECT TrialPlanId__c
		FROM Environment__mdt
		WHERE DeveloperName = 'Production' // FIXME: Use dynamic environment selection
		LIMIT 1
	].TrialPlanId__c);

	/**
	 * Possible DocuSign environment targets:
	 * <ul>
	 *     <li><code>Invalid</code>: Invalid DocuSign environment</li>
	 *     <li><code>QA</code>: DocuSign QA environment</li>
	 *     <li><code>Stage</code>: DocuSign Stage environment</li>
	 *     <li><code>Demo</code>: DocuSign Demo environment</li>
	 *     <li><code>Production</code>: DocuSign Production environment</li>
	 *     <li><code>HQTEST0</code>: DocuSign HQTEST0 environment.
	 *     <li><code>HQTEST1</code>: DocuSign HQTEST1 environment.
	 *     <li><code>HQTEST2</code>: DocuSign HQTEST2 environment.
	 *     <li><code>HQTEST3</code>: DocuSign HQTEST3 environment.
	 *     <li><code>Other</code>: Other DocuSign environment. A valid DocuSign base URL must be supplied.</li>
	 * </ul>
	 */
	public enum Environment {
		Invalid, QA, Stage, Demo, Production, HQTEST0, HQTEST1, HQTEST2, HQTEST3, Other
	}

	private static final List<String> allowedDomainsList = new List<String> {
		'.docusign.com',
		'.docusign.net',
		'.docusignhq.com',
		'.springcm.com'
	};

	/**
 	 * Verifies that a DocuSign host is valid. The host must be in the allowed list.
 	 *
 	 * @param host The host to validate.
 	 *
 	 * @return <code>True<code> if the host is a valid DocuSign host, <code>false</code> otherwise.
 	 */
	public static Boolean isValidHost(final String host) {
		Boolean result = false;
		if (String.isNotBlank(host)) {
			String h = host.trim().toLowerCase();
			for (String domain : allowedDomainsList) {
				if (h.endsWith(domain)) {
					result = true;
					break;
				}
			}
		}
		return result;
	}

	/**
 	 * Verifies that a DocuSign URL is valid. It must use HTTPS and the host must be in the allowed list.
 	 *
 	 * @param url The URL to validate.
 	 *
 	 * @return <code>True<code> if the URL is a valid DocuSign base URL, <code>false</code> otherwise.
 	 */
	public static Boolean isValidUrl(final Url url) {
		return url != null
			&& url.getProtocol().equalsIgnoreCase('https')
			&& isValidHost(url.getHost());
	}

	/**
	 * Retrieves the DocuSign environment for a given host.
	 *
	 * @param host The target host.
	 *
	 * @return The DocuSign environment if one is mapped to <code>host</code>, <code>Environment.Invalid</code> for
	 * invalid DocuSign hosts, or <code>Environment.Other</code> for any other valid DocuSign host.
	 */
	public static Environment getEnvironment(final String host) {
		Environment result = Environment.Invalid;
		if (isValidHost(host)) {
			Environment__mdt env = (Environment__mdt)Collection.head([
				SELECT DeveloperName
				FROM Environment__mdt
				WHERE AccountBaseUrl__c LIKE :('https://' + host + '%')
				LIMIT 1
			]);
			result = env == null || String.isBlank(env.DeveloperName)
				? Environment.Other : parseEnvironment(env.DeveloperName);
		}
		return result;
	}

	/**
	 * Retrieves the DocuSign environment for a given URL.
	 *
	 * @param url The target url.
	 *
	 * @return The DocuSign environment if one is mapped to <code>url</code>, <code>Environment.Invalid</code> for
	 * invalid DocuSign url, or <code>Environment.Other</code> for any other valid DocuSign url.
	 */
	public static Environment getEnvironment(final Url url) {
		return getEnvironment(url == null ? (String)null : url.getHost());
	}

	/**
	 * Parses a DocuSign environment from a string.
	 *
	 * @param s The input string.
	 *
	 * @return The parsed DocuSign environment.
	 */
	public static Environment parseEnvironment(final String s) {
		if (String.isBlank(s)) return Environment.Invalid;

		switch on s.toLowerCase() {
			when 'prod', 'production' {
				return Environment.Production;
			} when 'demo' {
				return Environment.Demo;
			} when 'stage' {
				return Environment.Stage;
			} when 'qa' {
				return Environment.QA;
			} when 'hqtest0' {
				return Environment.HQTEST0;
			} when 'hqtest1' {
				return Environment.HQTEST1;
			} when 'hqtest2' {
				return Environment.HQTEST2;
			} when 'hqtest3' {
				return Environment.HQTEST3;
			} when 'other' {
				return Environment.Other;
			} when else {
				return Environment.Invalid;
			}
		}
	}

	/**
	 * Checks whether a given DocuSign environment is valid.
	 *
	 * @param env The environment to test.
	 * @param otherUrl The URL to test if the environment is undefined or <code>Other</code>.
	 *
	 * @return <code>True</code> if the environment is valid, <code>false</code> otherwise.
	 */
	public static Boolean isValidEnvironment(final Environment env, final Url otherUrl) {
		if (otherUrl != null) return isValidUrl(otherUrl);

		return (env != null && env != Environment.Invalid && env != Environment.Other);
	}
}
