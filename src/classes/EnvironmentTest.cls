@IsTest
private class EnvironmentTest {

	static testMethod void test_constructor() {
		Environment e1 = new Environment(Environment.Target.Production, new URL('http://fake.com'));
		System.assertEquals(Environment.Target.Production, e1.environment);
		System.assertEquals('https://www.docusign.net/', e1.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e1.trialPlanId);

		Environment e2 = new Environment(Environment.Target.Demo, null);
		System.assertEquals(Environment.Target.Demo, e2.environment);
		System.assertEquals('https://demo.docusign.net/', e2.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e2.trialPlanId);

		Environment e3 = new Environment(Environment.Target.Stage, new URL('https://demo.docusign.net'));
		System.assertEquals(Environment.Target.Stage, e3.environment);
		System.assertEquals('https://stage.docusign.net/', e3.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e3.trialPlanId);

		Environment e4 = new Environment(Environment.Target.Other, new URL('https://other.docusignhq.com'));
		System.assertEquals(Environment.Target.Other, e4.environment);
		System.assertEquals('https://other.docusignhq.com/', e4.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e4.trialPlanId);

		Environment e5 = new Environment(new URL('https://na3.docusign.net'));
		System.assertEquals(Environment.Target.Production, e5.environment);
		System.assertEquals('https://na3.docusign.net/', e5.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e5.trialPlanId);

		Environment e6 = new Environment(new URL('https://other.docusign.net'));
		System.assertEquals(Environment.Target.Other, e6.environment);
		System.assertEquals('https://other.docusign.net/', e6.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e6.trialPlanId);

		Environment e7 = new Environment(new URL('https://au.docusign.net'));
		System.assertEquals(Environment.Target.Production, e7.environment);
		System.assertEquals('https://au.docusign.net/', e7.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e7.trialPlanId);

		Environment e8 = new Environment(new URL('https://ca.docusign.net'));
		System.assertEquals(Environment.Target.Production, e8.environment);
		System.assertEquals('https://ca.docusign.net/', e8.baseURL.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e8.trialPlanId);
	}

	static testMethod void test_constructor_invalid() {
		// require HTTPS
		Environment e1 = new Environment(Environment.Target.Other, new URL('http://www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e1.environment);
		System.assertEquals(null, e1.baseURL);

		Environment e2 = new Environment(new URL('http://www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e2.environment);
		System.assertEquals(null, e2.baseURL);

		// Non-whitelisted domain
		Environment e3 = new Environment(Environment.Target.Other, new URL('https://www.evil.com'));
		System.assertEquals(Environment.Target.Invalid, e3.environment);
		System.assertEquals(null, e3.baseURL);

		Environment e4 = new Environment(new URL('https://www.evil.com'));
		System.assertEquals(Environment.Target.Invalid, e4.environment);
		System.assertEquals(null, e4.baseURL);

		// Non-whitelisted domain that looks like whitelisted one
		Environment e5 = new Environment(Environment.Target.Other, new URL('https://www.evil-docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e5.environment);
		System.assertEquals(null, e5.baseURL);

		Environment e6 = new Environment(new URL('https://www.evil-docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e6.environment);
		System.assertEquals(null, e6.baseURL);

		Environment e7 = new Environment(Environment.Target.Other, new URL('https://some.evil.site/?www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e7.environment);
		System.assertEquals(null, e7.baseURL);

		Environment e8 = new Environment(new URL('https://some.evil.site?www.docusign.net'));
		System.assertEquals(e8.environment, Environment.Target.Invalid);
		System.assertEquals(e8.baseURL, null);
	}

	static testMethod void test_equality() {
		System.assertEquals(
			new Environment(Environment.Target.Production, null),
			new Environment(Environment.Target.Production, null));
		System.assertEquals(Environment.Invalid, Environment.Invalid);
		System.assertNotEquals(new Environment(Environment.Target.Production, null), null);
		System.assertNotEquals(
			new Environment(Environment.Target.Demo, null),
			new Environment(Environment.Target.Stage, null));
		System.assertEquals(
			new Environment(Environment.Target.Other, new URL('https://other.docusign.net')),
			new Environment(Environment.Target.Other, new URL('https://other.docusign.net')));
		System.assertNotEquals(
			new Environment(Environment.Target.Other, new URL('https://other1.docusign.net')),
			new Environment(Environment.Target.Other, new URL('https://other2.docusign.net')));
	}

	static testMethod void test_hashCode() {
		System.assertEquals(0, Environment.Invalid.hashCode());
		System.assertEquals(
			new Environment(Environment.Target.Production, new URL('https://whatever')).hashCode(),
			new Environment(Environment.Target.Production, null).hashCode());
		System.assertNotEquals(
			new Environment(Environment.Target.Other, new URL('https://other1.docusign.net')).hashCode(),
			new Environment(Environment.Target.Other, new URL('https://other2.docusign.net')).hashCode());
	}

	static testMethod void test_toString() {
		System.assertEquals(
			'Production => https://www.docusign.net/',
			new Environment(new URL('https://www.docusign.net')).toString());
		System.assertEquals('Invalid', Environment.Invalid.toString());
	}

	static testMethod void test_fromTarget() {
		Environment e1 = Environment.fromTarget('production', null);
		System.assertEquals(e1.environment, Environment.Target.Production);
		System.assertEquals(e1.baseURL.toExternalForm(), 'https://www.docusign.net/');

		Environment e2 = Environment.fromTarget('demo', 'https://demo.fake.com/');
		System.assertEquals(e2.environment, Environment.Target.Demo);
		System.assertEquals(e2.baseURL.toExternalForm(), 'https://demo.docusign.net/');

		Environment e3 = Environment.fromTarget('stage', 'https://demo.docusign.net/');
		System.assertEquals(e3.environment, Environment.Target.Stage);
		System.assertEquals(e3.baseURL.toExternalForm(), 'https://stage.docusign.net/');

		Environment e4 = Environment.fromTarget('other', 'https://other.docusignhq.com/');
		System.assertEquals(e4.environment, Environment.Target.Other);
		System.assertEquals(e4.baseURL.toExternalForm(), 'https://other.docusignhq.com/');
	}

	static testMethod void test_fromTarget_invalid() {
		Environment e1 = Environment.fromTarget(null, null);
		System.assert(!e1.isValid, 'Environment is valid with null target');

		Environment e2 = Environment.fromTarget('bad', null);
		System.assert(!e2.isValid, 'Environment is valid with bad target');

		Environment e3 = Environment.fromTarget('other', 'https://evil-docusign.net');
		System.assert(!e3.isValid, 'Environment is valid with bad URL');

		Environment e4 = Environment.fromTarget('other', 'https://some.evil.site?docusign.net');
		System.assert(!e4.isValid, 'Environment is valid with bad URL');

		try {
			Environment.fromTarget('other', 'blah');
			throw new AssertException('Environment.fromTarget did not throw expected exception for invalid URL');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
	}

	static testMethod void test_fromURL() {
		Environment e1 = Environment.fromURL(new URL('https://www.docusign.net/'));
		System.assertEquals(Environment.Target.Production, e1.environment);

		Environment e2 = Environment.fromURL(new URL('https://demo.docusign.net/'));
		System.assertEquals(Environment.Target.Demo, e2.environment);

		Environment e3 = Environment.fromURL(new URL('https://stage.docusign.net/'));
		System.assertEquals(Environment.Target.Stage, e3.environment);

		Environment e4 = Environment.fromURL(new URL('https://other.docusign.net/'));
		System.assertEquals(Environment.Target.Other, e4.environment);
	}

	static testMethod void test_fromURL_invalid() {
		Environment e1 = Environment.fromURL(null);
		System.assert(!e1.isValid, 'Environment is valid with null target');

		Environment e2 = Environment.fromURL(new URL('https://bad.target'));
		System.assert(!e2.isValid, 'Environment is valid with bad URL');

		Environment e3 = Environment.fromURL(new URL('https://evil-docusign.net'));
		System.assert(!e3.isValid, 'Environment is valid with bad URL');

		Environment e4 = Environment.fromURL(new URL('https://some.evil.site?docusign.net'));
		System.assert(!e4.isValid, 'Environment is valid with bad URL');
	}

	static testMethod void test_getBaseURL() {
		URL bu1 = Environment.getBaseURL('production');
		System.assertEquals('https://www.docusign.net/', bu1.toExternalForm());

		URL bu2 = Environment.getBaseURL('DEMO');
		System.assertEquals('https://demo.docusign.net/', bu2.toExternalForm());

		URL bu3 = Environment.getBaseURL('STagE');
		System.assertEquals('https://stage.docusign.net/', bu3.toExternalForm());

		URL bu4 = Environment.getBaseURL('other');
		System.assertEquals(null, bu4);

		URL bu5 = Environment.getBaseURL((String)null);
		System.assertEquals(null, bu5);

		URL bu6 = Environment.getBaseURL((Environment.Target)null);
		System.assertEquals(null, bu6);

		URL bu7 = Environment.getBaseURL(Environment.Target.Other);
		System.assertEquals(null, bu7);
	}

	static testMethod void test_isValid() {
		System.assert(Environment.isValid(new Environment(Environment.Target.Production, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Demo, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Stage, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Other, new URL('https://other.docusign.net'))),
			'Environment invalid');
		System.assert(!Environment.isValid(new Environment(Environment.Target.Other, null)),
			'Environment valid');
		System.assert(!Environment.isValid(new Environment(Environment.Target.Other, new URL('http://other.docusign.net'))),
			'Environment valid');
		System.assert(!Environment.isValid(Environment.Invalid),
			'Environment valid');
	}

	static testMethod void test_parseBaseURL() {
		System.assertEquals('https://www.docusign.net/', Environment.parseBaseURL(new URL('https://www.docusign.net/restapi/v2/blah')).toExternalForm());
		System.assertEquals('https://demo.docusign.net/', Environment.parseBaseURL(new URL('https://demo.docusign.net/restapi/v2/blah')).toExternalForm());
		System.assertEquals('https://other.docusignhq.com/', Environment.parseBaseURL(new URL('https://other.docusignhq.com/restapi/v2/blah')).toExternalForm());
		System.assertEquals(null, Environment.parseBaseURL(new URL('https://other.evil.com/restapi/v2/blah')));
		System.assertEquals(null, Environment.parseBaseURL(new URL('https://other.evil-docusign.net/restapi/v2/blah')));
		System.assertEquals(null, Environment.parseBaseURL(new URL('https://some.evil.site/?demo.docusign.net')));
		System.assertEquals(null, Environment.parseBaseURL(null));
	}

	static testMethod void test_parseTarget() {
		System.assertEquals(Environment.Target.Production, Environment.parseTarget('production'));
		System.assertEquals(Environment.Target.Demo, Environment.parseTarget('demo'));
		System.assertEquals(Environment.Target.Stage, Environment.parseTarget('STAGE'));
		System.assertEquals(Environment.Target.Test, Environment.parseTarget('Test'));
		System.assertEquals(Environment.Target.Other, Environment.parseTarget('oTheR'));

		System.assertEquals(Environment.Target.Invalid, Environment.parseTarget('invalid'));
		System.assertEquals(Environment.Target.Invalid, Environment.parseTarget('abcedefg'));
		System.assertEquals(Environment.Target.Invalid, Environment.parseTarget(null));
		System.assertEquals(Environment.Target.Invalid, Environment.parseTarget(''));
		System.assertEquals(Environment.Target.Invalid, Environment.parseTarget('\r'));
	}

	static testMethod void test_static_environments() {
		System.assertEquals(Environment.invalid, Environment.invalid);
		System.assertEquals(Environment.demo, Environment.demo);
		System.assertEquals(Environment.production, Environment.production);
		System.assertNotEquals(Environment.production, Environment.demo);
		System.assertEquals(Environment.Target.Demo, Environment.demo.environment);
		System.assertEquals('https://demo.docusign.net/', Environment.demo.baseURL.toExternalForm());
		System.assertEquals(Environment.Target.Production, Environment.production.environment);
		System.assertEquals('https://www.docusign.net/', Environment.production.baseURL.toExternalForm());
	}
}
