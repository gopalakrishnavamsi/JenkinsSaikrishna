/**
 * Representation of a DocuSign environment.
 */
public class Environment {

	// TODO: Use environment-specific trial plan IDs. Support multiple if necessary.
	@TestVisible
	private static final UUID TRIAL_PLAN_ID = UUID.parse([
		SELECT TrialPlanId__c
		FROM Organization__mdt
		WHERE DeveloperName = 'SecureSettings'
		LIMIT 1
	].TrialPlanId__c);

	/**
	 * Possible DocuSign environment targets:
	 * <ul>
	 *     <li><code>Invalid</code>: invalid DocuSign environment</li>
	 *     <li><code>Stage</code>: DocuSign Stage environment</li>
	 *     <li><code>Demo</code>: DocuSign Demo environment</li>
	 *     <li><code>Production</code>: DocuSign Production environment</li>
	 *     <li><code>Other</code>: Other DocuSign environment. A valid DocuSign base URL must be supplied.</li>
	 * </ul>
	 */
	public enum Target {
		Invalid, Stage, Demo, Production, Other
	}

	private static final Map<String, Target> nameTarget = new Map<String, Target> {
		'production' => Target.Production,
		'prod' => Target.Production,
		'demo' => Target.Demo,
		'stage' => Target.Stage,
		'eu' => Target.Production,
		'au' => Target.Production,
		'ca' => Target.Production,
		'other' => Target.Other
	};
	private static final Map<String, Url> nameToBaseUrl = new Map<String, Url> {
		'stage' => new Url('https://stage.docusign.net/'),
		'demo' => new Url('https://demo.docusign.net/'),
		'prod' => new Url('https://www.docusign.net/'),
		'production' => new Url('https://www.docusign.net/'),
		'eu' => new Url('https://eu.docusign.net/'),
		'au' => new Url('https://au.docusign.net/'),
		'ca' => new Url('https://ca.docusign.net/')
	};
	private static final Map<Target, Url> envToBaseUrl = new Map<Target, Url> {
		Target.Stage => new Url('https://stage.docusign.net/'),
		Target.Demo => new Url('https://demo.docusign.net/'),
		Target.Production => new Url('https://www.docusign.net/')
	};
	private static final Map<String, Target> hostTarget = new Map<String, Target> {
		'stage.docusign.net' => Target.Stage,
		'demo.docusign.net' => Target.Demo,
		'www.docusign.net' => Target.Production,
		'na2.docusign.net' => Target.Production,
		'na3.docusign.net' => Target.Production,
		'eu.docusign.net' => Target.Production,
		'au.docusign.net' => Target.Production,
		'ca.docusign.net' => Target.Production
	};
	private static final List<String> domainWhitelist = new List<String> {
		'.docusign.net',
		'.docusignhq.com'
	};

	/**
	 * Constant for an invalid DocuSign environment.
	 */
	public static final Environment invalid = new Environment(Target.Invalid, null);
	/**
	 * Constant for the DocuSign production environment.
	 */
	public static final Environment production = new Environment(Target.Production, envToBaseUrl.get(Target.Production));
	/**
	 * Constant for the DocuSign demo environment.
	 */
	public static final Environment demo = new Environment(Target.Demo, envToBaseUrl.get(Target.Demo));

	/**
	 * The environment target.
	 */
	public Target environment { get; private set; }
	/**
	 * The API base URL.
	 */
	public transient Url baseUrl { get; private set; }
	/**
	 * Read-only property indicating whether or not the environment is valid.
	 */
	public Boolean isValid {
		get {
			return this.environment != Target.Invalid;
		}
	}
	/**
	 * The trial account plan ID for the environment.
	 */
	public UUID trialPlanId { get; private set; }
	private final String baseUrlString;

	@TestVisible
	private Environment(final Target t, final Url url) {
		this.environment = Target.Invalid;
		if (t == Target.Other) {
			if (url != null) {
				if (url.getProtocol().equalsIgnoreCase('https')) { // Must be HTTPS
					// Matches valid host?
					this.environment = getTarget(url.getHost().trim().toLowerCase());
					if (this.isValid) {
						this.baseUrl = new Url(url.getProtocol() + '://' + url.getAuthority() + '/');
					}
				}
			}
		} else if (t != null && t != Target.Invalid) {
			this.environment = t;
			this.baseUrl = envToBaseUrl.get(t);
		}

		this.baseUrlString = this.baseUrl == null ? '' : this.baseUrl.toExternalForm();
		this.trialPlanId = TRIAL_PLAN_ID;
	}

	@TestVisible
	private Environment(final Url url) {
		this.environment = Target.Invalid;

		if (url != null) {
			if (url.getProtocol().equalsIgnoreCase('https')) { // Must be HTTPS
				// Matches valid host?
				this.environment = getTarget(url.getHost().trim().toLowerCase());
			}
		}

		if (this.isValid) this.baseUrl = new Url(url.getProtocol() + '://' + url.getAuthority() + '/');

		this.baseUrlString = this.baseUrl == null ? '' : this.baseUrl.toExternalForm();
		this.trialPlanId = TRIAL_PLAN_ID;
	}

	/**
	 * Factory method to construct a DocuSign environment from a target.
	 *
	 * @param target The DocuSign environment.
	 * @param otherUrl The base URL if the environment is 'other'.
	 *
	 * @return The DocuSign environment corresponding to the target.
	 */
	public static Environment fromTarget(final Target t, final Url otherUrl) {
		return new Environment(t == null ? Target.Invalid : t, t == Target.Other ? otherUrl : null);
	}

	private static Target getTarget(final String host) {
		Target result = Target.Invalid;

		if (String.isNotBlank(host)) {
			Target t = hostTarget.get(host.trim().toLowerCase());
			if (t != null) result = t; else if (isValidHost(host)) result = Target.Other;
		}

		return result;
	}

	/**
	 * Tests whether a DocuSign environment is valid.
	 *
	 * @param e The DocuSign environment.
	 *
	 * @return <code>true</code> if the DocuSign environment is non-null and is valid, <code>false</code> otherwise.
	 */
	public static Boolean isValid(final Environment e) {
		return (e != null && e.isValid);
	}

	private static Boolean isValidHost(final String host) {
		Boolean result = false;

		if (String.isNotBlank(host)) {
			String h = host.trim().toLowerCase();

			for (String domain : domainWhitelist) {
				if (h.endsWith(domain)) {
					result = true;
					break;
				}
			}
		}

		return result;
	}

	/**
	 * Factory method to construct a DocuSign environment from a base URL.
	 *
	 * @param u The DocuSign base URL.
	 *
	 * @return The DocuSign environment corresponding to the base URL.
	 */
	public static Environment fromUrl(final Url u) {
		return new Environment(u);
	}

	/**
	 * Generates a hash code for the DocuSign environment based on the base URL.
	 *
	 * @return The DocuSign environment hash code.
	 */
	override public Integer hashCode() {
		return this.baseUrlString.hashCode();
	}

	/**
	 * Tests whether an object is equal to the DocuSign environment.
	 *
	 * @param obj The object to test.
	 *
	 * @return <code>true</code> if the object matches the environment, <code>false</code> otherwise.
	 */
	public Boolean equals(Object obj) {
		if (this === obj) return true;
		if (obj == null || !(obj instanceof Environment)) return false;
		Environment other = (Environment)obj;
		return (this.environment == other.environment && this.baseUrlString == other.baseUrlString);
	}

	/**
	 * Creates a string representation of the DocuSign environment.
	 *
	 * @return The string representation of the Docusign environment.
	 */
	override public String toString() {
		return this.isValid ? this.environment + ' => ' + this.baseUrlString : 'Invalid';
	}
}