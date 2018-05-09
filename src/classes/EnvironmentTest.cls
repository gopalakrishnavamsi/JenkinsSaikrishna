@IsTest(isParallel = true)
private class EnvironmentTest {

	@IsTest
	static void test_constructor() {
		Environment e1 = new Environment(Environment.Target.Production, new Url('http://fake.com'));
		System.assertEquals(Environment.Target.Production, e1.environment);
		System.assertEquals('https://www.docusign.net/', e1.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e1.trialPlanId);

		Environment e2 = new Environment(Environment.Target.Demo, null);
		System.assertEquals(Environment.Target.Demo, e2.environment);
		System.assertEquals('https://demo.docusign.net/', e2.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e2.trialPlanId);

		Environment e3 = new Environment(Environment.Target.Stage, new Url('https://demo.docusign.net'));
		System.assertEquals(Environment.Target.Stage, e3.environment);
		System.assertEquals('https://stage.docusign.net/', e3.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e3.trialPlanId);

		Environment e4 = new Environment(Environment.Target.Other, new Url('https://other.docusignhq.com'));
		System.assertEquals(Environment.Target.Other, e4.environment);
		System.assertEquals('https://other.docusignhq.com/', e4.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e4.trialPlanId);

		Environment e5 = new Environment(new Url('https://na3.docusign.net'));
		System.assertEquals(Environment.Target.Production, e5.environment);
		System.assertEquals('https://na3.docusign.net/', e5.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e5.trialPlanId);

		Environment e6 = new Environment(new Url('https://other.docusign.net'));
		System.assertEquals(Environment.Target.Other, e6.environment);
		System.assertEquals('https://other.docusign.net/', e6.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e6.trialPlanId);

		Environment e7 = new Environment(new Url('https://au.docusign.net'));
		System.assertEquals(Environment.Target.Production, e7.environment);
		System.assertEquals('https://au.docusign.net/', e7.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e7.trialPlanId);

		Environment e8 = new Environment(new Url('https://ca.docusign.net'));
		System.assertEquals(Environment.Target.Production, e8.environment);
		System.assertEquals('https://ca.docusign.net/', e8.baseUrl.toExternalForm());
		System.assertEquals(Environment.trial30DayPlanId, e8.trialPlanId);
	}

	@IsTest
	static void test_constructor_invalid() {
		// require HTTPS
		Environment e1 = new Environment(Environment.Target.Other, new Url('http://www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e1.environment);
		System.assertEquals(null, e1.baseUrl);

		Environment e2 = new Environment(new Url('http://www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e2.environment);
		System.assertEquals(null, e2.baseUrl);

		// Non-whitelisted domain
		Environment e3 = new Environment(Environment.Target.Other, new Url('https://www.evil.com'));
		System.assertEquals(Environment.Target.Invalid, e3.environment);
		System.assertEquals(null, e3.baseUrl);

		Environment e4 = new Environment(new Url('https://www.evil.com'));
		System.assertEquals(Environment.Target.Invalid, e4.environment);
		System.assertEquals(null, e4.baseUrl);

		// Non-whitelisted domain that looks like whitelisted one
		Environment e5 = new Environment(Environment.Target.Other, new Url('https://www.evil-docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e5.environment);
		System.assertEquals(null, e5.baseUrl);

		Environment e6 = new Environment(new Url('https://www.evil-docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e6.environment);
		System.assertEquals(null, e6.baseUrl);

		Environment e7 = new Environment(Environment.Target.Other, new Url('https://some.evil.site/?www.docusign.net'));
		System.assertEquals(Environment.Target.Invalid, e7.environment);
		System.assertEquals(null, e7.baseUrl);

		Environment e8 = new Environment(new Url('https://some.evil.site?www.docusign.net'));
		System.assertEquals(e8.environment, Environment.Target.Invalid);
		System.assertEquals(e8.baseUrl, null);
	}

	@IsTest
	static void test_equality() {
		System.assertEquals(
			new Environment(Environment.Target.Production, null),
			new Environment(Environment.Target.Production, null));
		System.assertEquals(Environment.Invalid, Environment.Invalid);
		System.assertNotEquals(new Environment(Environment.Target.Production, null), null);
		System.assertNotEquals(
			new Environment(Environment.Target.Demo, null),
			new Environment(Environment.Target.Stage, null));
		System.assertEquals(
			new Environment(Environment.Target.Other, new Url('https://other.docusign.net')),
			new Environment(Environment.Target.Other, new Url('https://other.docusign.net')));
		System.assertNotEquals(
			new Environment(Environment.Target.Other, new Url('https://other1.docusign.net')),
			new Environment(Environment.Target.Other, new Url('https://other2.docusign.net')));
	}

	@IsTest
	static void test_hashCode() {
		System.assertEquals(0, Environment.Invalid.hashCode());
		System.assertEquals(
			new Environment(Environment.Target.Production, new Url('https://whatever')).hashCode(),
			new Environment(Environment.Target.Production, null).hashCode());
		System.assertNotEquals(
			new Environment(Environment.Target.Other, new Url('https://other1.docusign.net')).hashCode(),
			new Environment(Environment.Target.Other, new Url('https://other2.docusign.net')).hashCode());
	}

	@IsTest
	static void test_toString() {
		System.assertEquals(
			'Production => https://www.docusign.net/',
			new Environment(new Url('https://www.docusign.net')).toString());
		System.assertEquals('Invalid', Environment.Invalid.toString());
	}

	@IsTest
	static void test_fromTarget() {
		Environment e1 = Environment.fromTarget(Environment.Target.Production, null);
		System.assertEquals(e1.environment, Environment.Target.Production);
		System.assertEquals(e1.baseUrl.toExternalForm(), 'https://www.docusign.net/');

		Environment e2 = Environment.fromTarget(Environment.Target.Demo, new Url('https://demo.fake.com/'));
		System.assertEquals(e2.environment, Environment.Target.Demo);
		System.assertEquals(e2.baseUrl.toExternalForm(), 'https://demo.docusign.net/');

		Environment e3 = Environment.fromTarget(Environment.Target.Stage, new Url('https://demo.docusign.net/'));
		System.assertEquals(e3.environment, Environment.Target.Stage);
		System.assertEquals(e3.baseUrl.toExternalForm(), 'https://stage.docusign.net/');

		Environment e4 = Environment.fromTarget(Environment.Target.Other, new Url('https://other.docusignhq.com/'));
		System.assertEquals(e4.environment, Environment.Target.Other);
		System.assertEquals(e4.baseUrl.toExternalForm(), 'https://other.docusignhq.com/');
	}

	@IsTest
	static void test_fromTarget_invalid() {
		Environment e1 = Environment.fromTarget(null, null);
		System.assert(!e1.isValid, 'Environment is valid with null target');

		Environment e2 = Environment.fromTarget(Environment.Target.Other, null);
		System.assert(!e2.isValid, 'Environment is valid with bad target');

		Environment e3 = Environment.fromTarget(Environment.Target.Other, new Url('https://evil-docusign.net'));
		System.assert(!e3.isValid, 'Environment is valid with bad URL');

		Environment e4 = Environment.fromTarget(Environment.Target.Other, new Url('https://some.evil.site?docusign.net'));
		System.assert(!e4.isValid, 'Environment is valid with bad URL');
	}

	@IsTest
	static void test_fromUrl() {
		Environment e1 = Environment.fromUrl(new Url('https://www.docusign.net/'));
		System.assertEquals(Environment.Target.Production, e1.environment);

		Environment e2 = Environment.fromUrl(new Url('https://demo.docusign.net/'));
		System.assertEquals(Environment.Target.Demo, e2.environment);

		Environment e3 = Environment.fromUrl(new Url('https://stage.docusign.net/'));
		System.assertEquals(Environment.Target.Stage, e3.environment);

		Environment e4 = Environment.fromUrl(new Url('https://other.docusign.net/'));
		System.assertEquals(Environment.Target.Other, e4.environment);
	}

	@IsTest
	static void test_fromUrl_invalid() {
		Environment e1 = Environment.fromUrl(null);
		System.assert(!e1.isValid, 'Environment is valid with null target');

		Environment e2 = Environment.fromUrl(new Url('https://bad.target'));
		System.assert(!e2.isValid, 'Environment is valid with bad URL');

		Environment e3 = Environment.fromUrl(new Url('https://evil-docusign.net'));
		System.assert(!e3.isValid, 'Environment is valid with bad URL');

		Environment e4 = Environment.fromUrl(new Url('https://some.evil.site?docusign.net'));
		System.assert(!e4.isValid, 'Environment is valid with bad URL');
	}

	@IsTest
	static void test_isValid() {
		System.assert(Environment.isValid(new Environment(Environment.Target.Production, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Demo, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Stage, null)),
			'Environment invalid');
		System.assert(Environment.isValid(new Environment(Environment.Target.Other, new Url('https://other.docusign.net'))),
			'Environment invalid');
		System.assert(!Environment.isValid(new Environment(Environment.Target.Other, null)),
			'Environment valid');
		System.assert(!Environment.isValid(new Environment(Environment.Target.Other, new Url('http://other.docusign.net'))),
			'Environment valid');
		System.assert(!Environment.isValid(Environment.Invalid),
			'Environment valid');
	}

	@IsTest
	static void test_static_environments() {
		System.assertEquals(Environment.invalid, Environment.invalid);
		System.assertEquals(Environment.demo, Environment.demo);
		System.assertEquals(Environment.production, Environment.production);
		System.assertNotEquals(Environment.production, Environment.demo);
		System.assertEquals(Environment.Target.Demo, Environment.demo.environment);
		System.assertEquals('https://demo.docusign.net/', Environment.demo.baseUrl.toExternalForm());
		System.assertEquals(Environment.Target.Production, Environment.production.environment);
		System.assertEquals('https://www.docusign.net/', Environment.production.baseUrl.toExternalForm());
	}
}
