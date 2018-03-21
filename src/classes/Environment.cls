/**
* Centralized logic for validating DocuSign environments.
* FIXME: Test hosts appear to be down. Remove or replace?
*/
public class Environment {

	@TestVisible // 30-day plan (PROD)
	private static final UUID trial30DayPlanId = UUID.fromString('83db741d-13af-470f-8beb-0ad0fba6e4a3');
	@TestVisible // 2-day plan (PROD)
	private static final UUID trial2DayPlanId = UUID.fromString('98c3e733-e3d3-4b39-89c6-961ed4125b6f');

	public enum Target {
		Invalid, Test, Stage, Demo, Production, Other
	}

	private static final Map<String, Target> nameTarget = new Map<String, Target> {
		'production' => Target.Production,
		'prod' => Target.Production,
		'demo' => Target.Demo,
		'stage' => Target.Stage,
		'test' => Target.Test,
		'test1' => Target.Test,
		'test2' => Target.Test,
		'eu' => Target.Production,
		'other' => Target.Other
	};
	private static final Map<String, URL> nameToBaseURL = new Map<String, URL> {
		'test' => new URL('https://test.docusign.net/'),
		'test1' => new URL('https://test1.docusign.net/'),
		'test2' => new URL('https://test2.docusign.net/'),
		'stage' => new URL('https://stage.docusign.net/'),
		'demo' => new URL('https://demo.docusign.net/'),
		'prod' => new URL('https://www.docusign.net/'),
		'production' => new URL('https://www.docusign.net/'),
		'eu' => new URL('https://eu.docusign.net/')
	};
	private static final Map<Target, URL> envToBaseURL = new Map<Target, URL> {
		Target.Test => new URL('https://test.docusign.net/'),
		Target.Stage => new URL('https://stage.docusign.net/'),
		Target.Demo => new URL('https://demo.docusign.net/'),
		Target.Production => new URL('https://www.docusign.net/')
	};
	private static final Map<String, Target> hostTarget = new Map<String, Target> {
		'stage.docusign.net' => Target.Stage,
		'demo.docusign.net' => Target.Demo,
		'www.docusign.net' => Target.Production,
		'na1.docusign.net' => Target.Production,
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

	public static final Environment invalid = new Environment(Target.Invalid, null);
	public static final Environment production = new Environment(Target.Production, envToBaseURL.get(Target.Production));
	public static final Environment demo = new Environment(Target.Demo, envToBaseURL.get(Target.Demo));

	public Target environment { get; private set; }
	public transient URL baseURL { get; private set; }
	public Boolean isValid { get {return this.environment != Target.Invalid;} }
	public UUID trialPlanId { get; private set; }
	private final String baseURLString;

	@TestVisible
	private Environment(final Target t, final URL url) {
		this.environment = Target.Invalid;
		if (t == Target.Other) {
			if (url != null) {
				if (url.getProtocol().equalsIgnoreCase('https')) { // Must be HTTPS
					// Matches valid host?
					this.environment = getTarget(url.getHost().toLowerCase());
					if (this.isValid) {
						this.baseURL = new URL(url.getProtocol() + '://' + url.getAuthority() + '/');
					}
				}
			}
		} else if (t != Target.Invalid) {
			this.environment = t;
			this.baseURL = envToBaseURL.get(t);
		}

		this.baseURLString = this.baseURL == null ? '' : this.baseURL.toExternalForm();
		// TODO: Use environment-specific trial plan IDs. Support multiple if necessary.
		this.trialPlanId = trial30DayPlanId;
	}

	@TestVisible
	private Environment(final URL url) {
		this.environment = Target.Invalid;

		if (url != null) {
			if (url.getProtocol().equalsIgnoreCase('https')) { // Must be HTTPS
				// Matches valid host?
				this.environment = getTarget(url.getHost().toLowerCase());
			}
		}

		if (this.isValid) this.baseURL = new URL(url.getProtocol() + '://' + url.getAuthority() + '/');

		this.baseURLString = this.baseURL == null ? '' : this.baseURL.toExternalForm();
		// TODO: Use environment-specific trial plan IDs. Support multiple if necessary.
		this.trialPlanId = trial30DayPlanId;
	}

	private static URL parseURL(String s) {
		try {
			return new URL(s);
		} catch (Exception ex) {
			throw new DocuSignException(Label.InvalidEnvironment, ex);
		}
	}

	public static Environment fromTarget(final String target, final String otherURL) {
		URL u = null;
		Target t = parseTarget(target);

		if (t == Environment.Target.Other && String.isNotBlank(otherURL)) {
			u = parseURL(otherURL);
		}

		return new Environment(t, u);
	}

	public static URL getBaseURL(final String t) {
		URL baseURL = null;

		if (String.isNotBlank(t)) {
			baseURL = nameToBaseURL.get(t.toLowerCase());
		}

		return baseURL;
	}

	public static URL getBaseURL(final Target t) {
		URL baseURL = null;

		if (t != null) {
			baseURL = envToBaseURL.get(t);
		}

		return baseURL;
	}

	private static Target getTarget(final String host) {
		Target result = Target.Invalid;

		if (String.isNotBlank(host)) {
			Target t = hostTarget.get(host.toLowerCase());
			if (t != null) result = t; else if (isValidHost(host)) result = Target.Other;
		}

		return result;
	}

	public static Boolean isValid(final Environment e) {
		return (e != null && e.isValid);
	}

	private static Boolean isValidHost(final String host) {
		Boolean result = false;

		if (String.isNotBlank(host)) {
			String h = host.toLowerCase();

			for (String domain : domainWhitelist) {
				if (h.endsWith(domain)) {
					result = true;
					break;
				}
			}
		}

		return result;
	}

	public static URL parseBaseURL(final URL u) {
		URL result = null;

		if (u != null) {
			Environment e = new Environment(u);
			if (e.isValid) {
				result = e.baseURL;
			}
		}

		return result;
	}

	public static Environment fromURL(final URL u) {
		return new Environment(u);
	}

	@TestVisible
	private static Target parseTarget(final String s) {
		Target result = Target.Invalid;

		if (String.isNotBlank(s)) {
			Target t = nameTarget.get(s.toLowerCase());
			result = t == null ? Target.Invalid : t;
		}

		return result;
	}

	override public Integer hashCode() {
		return this.baseURLString.hashCode();
	}

	public Boolean equals(Object obj) {
		if (this === obj) return true;
		if (obj == null || !(obj instanceof Environment)) return false;
		Environment other = (Environment)obj;
		return (this.environment == other.environment && this.baseURLString == other.baseURLString);
	}

	override public String toString() {
		return this.isValid ? this.environment + ' => ' + this.baseURLString : 'Invalid';
	}
}
