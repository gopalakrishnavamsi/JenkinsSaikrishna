@IsTest
private class MetadataServiceTest {

	@IsTest
	static void test_getCommonObjects_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.getCommonObjects();
				throw new AssertException('Expected getCommonObjects to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getCommonObjects_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			System.assert(Collection.isNotEmpty(MetadataService.getCommonObjects()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getObjects_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.getObjects();
				throw new AssertException('Expected getObjects to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getObjects_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			System.assert(Collection.isNotEmpty(MetadataService.getObjects()));
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getFields_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.getFields((SObjectType)null);
				throw new AssertException('Expected getFields to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
		}
	}

	@IsTest
	static void test_getFields_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<MergeField> result = MetadataService.getFields(Opportunity.getSObjectType());
			Test.stopTest();

			System.assert(Collection.isNotEmpty(result));
			// TODO: Verify merge fields. Difficult as we cannot control the schema entirely.
		}
	}

	@IsTest
	static void test_getErrorMessage() {
		MetadataAPI.SaveResult result = null;
		System.assertEquals(Label.SalesforceApiErrorUnexpectedResponse, MetadataService.getErrorMessage(result));
		result = new MetadataAPI.SaveResult();
		System.assertEquals(Label.SalesforceApiErrorUnexpectedResponse, MetadataService.getErrorMessage(result));
		MetadataAPI.Error e1 = new MetadataAPI.Error();
		e1.message = 'test1';
		MetadataAPI.Error e2 = new MetadataAPI.Error();
		e2.message = 'test2';
		MetadataAPI.Error e3 = new MetadataAPI.Error();
		e3.message = 'test3';
		result.errors = new List<MetadataAPI.Error> { e1, e2, e3 };
		System.assertEquals('test1\ntest2\ntest3', MetadataService.getErrorMessage(result));

		MetadataAPI.Error e4 = new MetadataAPI.Error();
		e4.statusCode = 'DUPLICATE_VALUE';
		MetadataAPI.SaveResult r4 = new MetadataAPI.SaveResult();
		r4.success = false;
		r4.errors = new List<MetadataAPI.Error> { e4 };
		System.assertEquals(Label.DuplicateButton, MetadataService.getErrorMessage(r4));

		MetadataAPI.Error e5 = new MetadataAPI.Error();
		e5.statusCode = 'DUPLICATE_DEVELOPER_NAME';
		MetadataAPI.SaveResult r5 = new MetadataAPI.SaveResult();
		r5.success = false;
		r5.errors = new List<MetadataAPI.Error> { e5 };
		System.assertEquals(Label.DuplicateButton, MetadataService.getErrorMessage(r5));
	}

	@IsTest
	static void test_validateResults() {
		MetadataAPI.SaveResult r1 = new MetadataAPI.SaveResult();
		r1.success = true;
		MetadataAPI.Error e1 = new MetadataAPI.Error();
		e1.statusCode = 'CODE_1';
		e1.message = 'msg1';
		MetadataAPI.Error e2 = new MetadataAPI.Error();
		e2.statusCode = 'DUPLICATE_VALUE';
		e2.message = 'msg2';
		MetadataAPI.Error e3 = new MetadataAPI.Error();
		e3.statusCode = 'CODE_3';
		e3.message = 'msg3';
		MetadataAPI.SaveResult r2 = new MetadataAPI.SaveResult();
		r2.success = false;
		r2.errors = new List<MetadataAPI.Error> { e1, e2, e3 };
		List<String> errors = new List<String> {
			e1.message,
			Label.DuplicateButton,
			e3.message
		};
		String msg = String.format(Label.UpdateMetadataFailure_1, new List<String> {
			Collection.mkString(errors, '\n')
		});

		Test.startTest();
		try {
			MetadataService.validateResults(new List<MetadataAPI.SaveResult> { r1, r2 });
			throw new AssertException('Expected validateResults to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(msg, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_newRemoteSite_undefined_argument() {
		try {
			MetadataService.newRemoteSite(null, 'Type', 'Description', new Url('https://unit.test.docusign.net'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Demo, null, 'Description', new Url('https://unit.test.docusign.net'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Demo, '  ', 'Description', new Url('https://unit.test.docusign.net'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Demo, 'Type', 'Description', null);
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
	}

	@IsTest
	static void test_newRemoteSite_invalid_environment() {
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Invalid, 'Type', 'Description', new Url('https://unit.test.docusign.net'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Production, 'Type', 'Description', new Url('https://example.com'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		try {
			MetadataService.newRemoteSite(DocuSign.Environment.Other, 'Type', 'Description', new Url('https://example.com'));
			throw new AssertException('Expected newRemoteSite to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
	}

	@IsTest
	static void test_newRemoteSite_success() {
		MetadataService.RemoteSite result = MetadataService.newRemoteSite(DocuSign.Environment.Production, 'Type', 'Description', new Url('https://unit.test.docusign.com'));
		System.assertNotEquals(null, result);
		System.assertEquals('Production_Type', result.name);
		System.assertEquals(Application.namespacePrefix + 'Production_Type', result.fullName);
		System.assertEquals('Description', result.description);
		System.assertNotEquals(null, result.url);
		System.assertEquals('https://unit.test.docusign.com', result.url.toExternalForm());

		result = MetadataService.newRemoteSite(DocuSign.Environment.Other, 'Type', 'Description', new Url('https://unit.test.docusign.com'));
		System.assertNotEquals(null, result);
		System.assertEquals('unit_Type', result.name);
		System.assertEquals(Application.namespacePrefix + 'unit_Type', result.fullName);
		System.assertEquals('Description', result.description);
		System.assertNotEquals(null, result.url);
		System.assertEquals('https://unit.test.docusign.com', result.url.toExternalForm());
	}

	@IsTest
	static void test_createRemoteSites_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.createRemoteSites(null);
				throw new AssertException('Expected createRemoteSites to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createRemoteSites_invalid_arguments() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				MetadataService.createRemoteSites(null);
				throw new AssertException('Expected createRemoteSites to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				MetadataService.createRemoteSites(new List<MetadataService.RemoteSite>());
				throw new AssertException('Expected createRemoteSites to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_createRemoteSites_error() {
		MetadataAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			MetadataService.RemoteSite rs = MetadataService.newRemoteSite(DocuSign.Environment.Demo, 'test', 'rs1 desc', new Url('https://rs1.docusign.com'));

			Test.startTest();
			try {
				MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> { rs });
				throw new AssertException('Expected createRemoteSites to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(String.format(Label.UpdateMetadataFailure_1, new List<String> { 'Test failure' }),
					ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class RemoteSiteNotFoundMock implements WebServiceMock {

		private final WebServiceMock baseMock;
		private final Set<String> foundNames = new Set<String>();

		public RemoteSiteNotFoundMock() {
			this.baseMock = new MetadataAPIMock(true);
		}

		public void doInvoke(
			final Object stub,
			final Object request,
			final Map<String, Object> response,
			final String endpoint,
			final String soapAction,
			final String requestName,
			final String responseNS,
			final String responseName,
			final String responseType) {

			if (request instanceof MetadataAPI.readMetadata_element
				&& ((MetadataAPI.readMetadata_element)request).type_x == 'RemoteSiteSetting') {

				MetadataAPI.ReadRemoteSiteSettingResult result = new MetadataAPI.ReadRemoteSiteSettingResult();
				result.records = new List<MetadataAPI.RemoteSiteSetting>();
				// "Find" the names for subsequent requests
				for (String fullName : ((MetadataAPI.readMetadata_element)request).fullNames) {
					if (foundNames.contains(fullName)) {
						MetadataAPI.RemoteSiteSetting rs = new MetadataAPI.RemoteSiteSetting();
						rs.fullName = fullName;
						rs.description = 'desc';
						rs.url = 'https://unit.test';
						rs.isActive = true;
						rs.disableProtocolSecurity = false;
						result.records.add(rs);
					} else {
						foundNames.add(fullName);
					}
				}
				MetadataAPI.readRemoteSiteSettingResponse_element resp = new MetadataAPI.readRemoteSiteSettingResponse_element();
				resp.result = result;
				response.put('response_x', resp);
			} else {
				baseMock.doInvoke(stub, request, response, endpoint, soapAction, requestName, responseNS, responseName,
					responseType);
			}
		}
	}

	@IsTest
	static void test_createRemoteSites_success() {
		Test.setMock(WebServiceMock.class, new RemoteSiteNotFoundMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			MetadataService.RemoteSite rs1 = MetadataService.newRemoteSite(DocuSign.Environment.Other, 'Type1',
				'RS1 desc', new Url('https://rs1.docusign.com'));
			MetadataService.RemoteSite rs2 = MetadataService.newRemoteSite(DocuSign.Environment.Other, 'Type1',
				'RS2 desc', new Url('https://rs2.docusign.com'));
			MetadataService.RemoteSite rs3 = MetadataService.newRemoteSite(DocuSign.Environment.Other, 'Type2',
				'RS3 desc', new Url('https://rs3.docusign.com'));

			Test.startTest();
			List<String> result1 = MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> { rs1 });
			List<String> result2 = MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> { rs1 });
			List<String> result3 = MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> { rs1, rs2, rs3 });
			Test.stopTest();

			System.assertEquals(new List<String> { rs1.name }, result1);
			System.assertEquals(new List<String>(), result2);
			System.assertEquals(new List<String> { rs2.name, rs3.name }, result3);
		}
	}

	@IsTest
	static void test_getLayouts_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.getLayouts(null);
				throw new AssertException('Expected getLayouts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLayouts_invalid_arguments() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				MetadataService.getLayouts(null);
				throw new AssertException('Expected getLayouts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			List<Layout> result = MetadataService.getLayouts(Contact.getSObjectType());
			Test.stopTest();

			System.assertEquals(1, Collection.size(result));
		}
	}

	@IsTest
	static void test_buildInputs() {
		System.assertEquals('[]', MetadataService.buildInputs(null, null));
		System.assertEquals('[sId = Lead.Id]', MetadataService.buildInputs(Lead.getSObjectType(), null));
		System.assertEquals('[sId = 1234]', MetadataService.buildInputs(Lead.getSObjectType(),
			new Map<String, String> { 'sId' => '1234' }));
		System.assertEquals('[sId = Lead.Id, p1 = abc]', MetadataService.buildInputs(Lead.getSObjectType(),
			new Map<String, String> { 'p1' => 'abc' }));
	}

	@IsTest
	static void test_createWebLink_invalid_arguments() {
		try {
			MetadataService.createWebLink(null, null, null, null, null);
			throw new AssertException('Expected createWebLink to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
	}

	@IsTest
	static void test_createWebLink_success() {
		MetadataAPIMock.success();

		String fullName = UUID.randomUUID().toString();
		String buttonLabel = UUID.randomUUID().toString();
		Map<String, String> params = new Map<String, String> {
			'a' => UUID.randomUUID().toString(),
			'b' => UUID.randomUUID().toString(),
			'c' => UUID.randomUUID().toString()
		};

		Test.startTest();
		MetadataAPI.WebLink result = MetadataService.createWebLink(
			Lead.SObjectType,
			fullName,
			buttonLabel,
			Page.ReturnFromDocuSign,
			params);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals('Lead.' + fullName, result.fullName);
		System.assertEquals(buttonLabel, result.masterLabel);
		System.assert(String.isNotBlank(result.url));
		System.assert(result.url.contains(new Url(Url.getOrgDomainUrl(), Page.ReturnFromDocuSign.getUrl()).getPath()));
		System.assert(result.url.contains('sId = Lead.Id'));
		System.assert(result.url.contains('a = ' + params.get('a')));
		System.assert(result.url.contains('b = ' + params.get('b')));
		System.assert(result.url.contains('c = ' + params.get('c')));
	}

	@IsTest
	static void test_createWebLink_failure() {
		MetadataAPIMock.failure();
		Test.startTest();
		try {
			MetadataService.createWebLink(
				Lead.SObjectType,
				'a',
				'b',
				Page.ReturnFromDocuSign,
				null);
			throw new AssertException('Expected createWebLink to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(String.format(Label.UpdateMetadataFailure_1, new List<String> { 'Test failure' }),
				ex.getMessage());
		}
		Test.stopTest();
	}

	private class LayoutNotFoundMock implements WebServiceMock {

		private final WebServiceMock baseMock;

		public LayoutNotFoundMock() {
			baseMock = new MetadataAPIMock(true);
		}

		public void doInvoke(
			final Object stub,
			final Object request,
			final Map<String, Object> response,
			final String endpoint,
			final String soapAction,
			final String requestName,
			final String responseNS,
			final String responseName,
			final String responseType) {

			Boolean responded = false;
			if (request instanceof MetadataAPI.readMetadata_element) {
				MetadataAPI.readMetadata_element req = (MetadataAPI.readMetadata_element)request;
				if (req.type_x == 'Layout') {
					MetadataAPI.ReadLayoutResult result = new MetadataAPI.ReadLayoutResult();
					result.records = new List<MetadataAPI.Layout>();
					MetadataAPI.readLayoutResponse_element resp = new MetadataAPI.readLayoutResponse_element();
					resp.result = result;
					response.put('response_x', resp);
					responded = true;
				}
			}

			if (!responded) {
				baseMock.doInvoke(stub, request, response, endpoint, soapAction, requestName, responseNS, responseName,
					responseType);
			}
		}
	}

	@IsTest
	static void test_readLayouts_not_found() {
		Test.setMock(WebServiceMock.class, new LayoutNotFoundMock());

		Test.startTest();
		try {
			MetadataService.readLayouts(new List<String> { 'l1' });
			throw new AssertException('Expected readLayouts to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.LayoutsNotFound, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_readLayouts_success() {
		MetadataAPIMock.success();

		Test.startTest();
		Map<String, MetadataAPI.Layout> result = MetadataService.readLayouts(new List<String> { 'l1' });
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(1, result.size());
	}

	@IsTest
	static void test_getCustomButtons() {
		System.assertEquals(
			new List<String> { 'button3', 'button1', 'button2' },
			MetadataService.getCustomButtons(true, 'button3', new List<String> {
				'button1', 'button2'
			}));
		System.assertEquals(
			new List<String> { 'button3', 'button1', 'button2' },
			MetadataService.getCustomButtons(true, 'button3', new List<String> {
				'button1', 'button2', 'button3'
			}));
		System.assertEquals(
			new List<String> { 'button1', 'button2' },
			MetadataService.getCustomButtons(false, 'button3', new List<String> {
				'button1', 'button2'
			}));
		System.assertEquals(
			new List<String> { 'button1', 'button2' },
			MetadataService.getCustomButtons(false, 'button3', new List<String> {
				'button1', 'button2', 'button3'
			}));
	}

	@IsTest
	static void test_getPlatformActionListItems() {
		MetadataAPI.PlatformActionListItem pali1 = new MetadataAPI.PlatformActionListItem();
		pali1.sortOrder = 0;
		pali1.actionName = 'button1';
		pali1.actionType = 'CustomButton';
		MetadataAPI.PlatformActionListItem pali2 = new MetadataAPI.PlatformActionListItem();
		pali2.sortOrder = 1;
		pali2.actionName = 'button2';
		pali2.actionType = 'CustomButton';
		MetadataAPI.PlatformActionListItem pali3 = new MetadataAPI.PlatformActionListItem();
		pali3.sortOrder = 2;
		pali3.actionName = 'button3';
		pali3.actionType = 'Opportunity-CustomButton';

		Test.startTest();
		List<MetadataAPI.PlatformActionListItem> result1 = MetadataService.getPlatformActionListItems(
			Opportunity.getSObjectType(),
			true,
			'button3',
			new List<MetadataAPI.PlatformActionListItem> { pali1, pali2 });
		List<MetadataAPI.PlatformActionListItem> result2 = MetadataService.getPlatformActionListItems(
			Opportunity.getSObjectType(),
			true,
			'button3',
			new List<MetadataAPI.PlatformActionListItem> { pali1, pali2, pali3 });
		List<MetadataAPI.PlatformActionListItem> result3 = MetadataService.getPlatformActionListItems(
			Opportunity.getSObjectType(),
			false,
			'button3',
			new List<MetadataAPI.PlatformActionListItem> { pali1, pali2 });
		List<MetadataAPI.PlatformActionListItem> result4 = MetadataService.getPlatformActionListItems(
			Opportunity.getSObjectType(),
			false,
			'button3',
			new List<MetadataAPI.PlatformActionListItem> { pali1, pali2, pali3 });
		Test.stopTest();

		System.assertEquals(3, result1.size());
		System.assertEquals(0, result1[0].sortOrder);
		System.assertEquals('button3', result1[0].actionName);
		System.assertEquals('CustomButton', result1[0].actionType);
		System.assertEquals(3, result2.size());
		System.assertEquals(0, result1[0].sortOrder);
		System.assertEquals('button3', result1[0].actionName);
		System.assertEquals('CustomButton', result1[0].actionType);
		System.assertEquals(2, result3.size());
		System.assertEquals(2, result4.size());
	}

	@IsTest
	static void test_mergeLayout_not_found() {
		try {
			MetadataService.mergeLayout(null, null, new MetadataAPI.Layout());
			throw new AssertException('Expected mergeLayout to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.LayoutsNotFound, ex.getMessage());
		}
		try {
			MetadataService.mergeLayout(null, new Layout(null, null, null, null, null), null);
			throw new AssertException('Expected mergeLayout to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.LayoutsNotFound, ex.getMessage());
		}
	}

	@IsTest
	static void test_mergeLayout_no_change() {
		Layout newLayout = new Layout(
			Contact.getSObjectType(),
			UserInfo.getUserId(),
			'ns',
			'n',
			new List<Layout.Action> {
				new Layout.Action(Layout.ACTION_TYPE_SEND, Layout.ACTION_NAME_SEND)
			});
		MetadataAPI.Layout currentLayout = new MetadataAPI.Layout();
		currentLayout.customButtons = new List<String> { Layout.ACTION_NAME_SEND };
		currentLayout.platformActionList = new MetadataAPI.PlatformActionList();
		MetadataAPI.PlatformActionListItem pali = new MetadataAPI.PlatformActionListItem();
		pali.actionName = Layout.ACTION_NAME_SEND;
		currentLayout.platformActionList.platformActionListItems = new List<MetadataAPI.PlatformActionListItem> { pali };

		Test.startTest();
		MetadataAPI.Layout result = MetadataService.mergeLayout(Lead.getSObjectType(), newLayout, currentLayout);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new List<String> { Layout.ACTION_NAME_SEND }, result.customButtons);
		System.assertNotEquals(null, result.platformActionList);
		System.assertEquals(1, Collection.size(result.platformActionList.platformActionListItems));
		System.assertNotEquals(null, result.platformActionList.platformActionListItems[0]);
		System.assertEquals(Layout.ACTION_NAME_SEND, result.platformActionList.platformActionListItems[0].actionName);
	}

	@IsTest
	static void test_mergeLayout_add_send() {
		Layout newLayout = new Layout(
			Contact.getSObjectType(),
			UserInfo.getUserId(),
			'ns',
			'n',
			new List<Layout.Action> {
				new Layout.Action(Layout.ACTION_TYPE_SEND, Layout.ACTION_NAME_SEND)
			});
		MetadataAPI.Layout currentLayout = new MetadataAPI.Layout();
		currentLayout.customButtons = null;
		currentLayout.platformActionList = new MetadataAPI.PlatformActionList();
		MetadataAPI.PlatformActionListItem pali = new MetadataAPI.PlatformActionListItem();
		pali.actionName = Layout.ACTION_NAME_SEND;
		currentLayout.platformActionList.platformActionListItems = new List<MetadataAPI.PlatformActionListItem> { pali };

		Test.startTest();
		MetadataAPI.Layout result = MetadataService.mergeLayout(Contact.getSObjectType(), newLayout, currentLayout);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(new List<String> { Layout.ACTION_NAME_SEND }, result.customButtons);
		System.assertNotEquals(null, result.platformActionList);
		System.assertEquals(1, Collection.size(result.platformActionList.platformActionListItems));
		System.assertNotEquals(null, result.platformActionList.platformActionListItems[0]);
		System.assertEquals(Layout.ACTION_NAME_SEND, result.platformActionList.platformActionListItems[0].actionName);
	}

	@IsTest
	static void test_mergeLayout_remove_send() {
		Layout newLayout = new Layout(
			Contact.getSObjectType(),
			UserInfo.getUserId(),
			'ns',
			'n',
			null);
		MetadataAPI.Layout currentLayout = new MetadataAPI.Layout();
		currentLayout.customButtons = new List<String> { Layout.ACTION_NAME_SEND };
		currentLayout.platformActionList = new MetadataAPI.PlatformActionList();
		MetadataAPI.PlatformActionListItem pali = new MetadataAPI.PlatformActionListItem();
		pali.actionName = Layout.ACTION_NAME_SEND;
		currentLayout.platformActionList.platformActionListItems = new List<MetadataAPI.PlatformActionListItem> { pali };

		Test.startTest();
		MetadataAPI.Layout result = MetadataService.mergeLayout(Contact.getSObjectType(), newLayout, currentLayout);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(0, Collection.size(result.customButtons));
		System.assertNotEquals(null, result.platformActionList);
		System.assertEquals(0, Collection.size(result.platformActionList.platformActionListItems));
	}

	private class WebLinkNotFoundMock implements WebServiceMock {

		private final WebServiceMock baseMock;

		public WebLinkNotFoundMock() {
			baseMock = new MetadataAPIMock(true);
		}

		public void doInvoke(
			final Object stub,
			final Object request,
			final Map<String, Object> response,
			final String endpoint,
			final String soapAction,
			final String requestName,
			final String responseNS,
			final String responseName,
			final String responseType) {

			Boolean responded = false;
			if (request instanceof MetadataAPI.readMetadata_element) {
				MetadataAPI.readMetadata_element req = (MetadataAPI.readMetadata_element)request;
				if (req.type_x == 'WebLink') {
					MetadataAPI.ReadWebLinkResult result = new MetadataAPI.ReadWebLinkResult();
					result.records = new List<MetadataAPI.WebLink>();
					MetadataAPI.readWebLinkResponse_element resp = new MetadataAPI.readWebLinkResponse_element();
					resp.result = result;
					response.put('response_x', resp);
					responded = true;
				}
			}

			if (!responded) {
				baseMock.doInvoke(stub, request, response, endpoint, soapAction, requestName, responseNS, responseName,
					responseType);
			}
		}
	}

	@IsTest
	static void test_getWebLink_not_found() {
		Test.setMock(WebServiceMock.class, new WebLinkNotFoundMock());

		Test.startTest();
		MetadataAPI.WebLink result = MetadataService.getWebLink(Lead.getSObjectType(), 'TestAction');
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@IsTest
	static void test_getWebLink_already_exists() {
		MetadataAPIMock.success();

		Test.startTest();
		MetadataAPI.WebLink result = MetadataService.getWebLink(Lead.getSObjectType(), 'TestAction');
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@IsTest
	static void test_getSendAction() {
		MetadataAPIMock.success();

		Test.startTest();
		MetadataAPI.WebLink result1 = MetadataService.getSendAction(Contact.getSObjectType());
		MetadataAPI.WebLink result2 = MetadataService.getSendAction(Lead.getSObjectType());
		MetadataAPI.WebLink result3 = MetadataService.getSendAction(Contact.getSObjectType());
		MetadataAPI.WebLink result4 = MetadataService.getSendAction(Lead.getSObjectType());
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assert(result1 === result3);
		System.assert(result2 === result4);
		System.assert(result1 !== result2);
	}

	@IsTest
	static void test_updateLayouts_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				MetadataService.updateLayouts(Contact.getSObjectType(), null);
				throw new AssertException('Expected updateLayouts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_invalid_argument() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Layout l = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n',
				new List<Layout.Action>());

			Test.startTest();
			try {
				MetadataService.updateLayouts(null, new List<Layout> { l });
				throw new AssertException('Expected updateLayouts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				MetadataService.updateLayouts(Contact.getSObjectType(), null);
				throw new AssertException('Expected updateLayouts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				MetadataService.updateLayouts(Contact.getSObjectType(), new List<Layout>());
				throw new AssertException('Expected updateLayouts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_invalid_layout() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				MetadataService.updateLayouts(Lead.getSObjectType(), new List<Layout> { null });
				throw new AssertException('Expected updateLayouts to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidLayout, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_updateLayouts_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Layout l1 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n1',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_SEND,
						Layout.ACTION_NAME_SEND)
				});
			Layout l2 = new Layout(
				Contact.getSObjectType(),
				UserInfo.getOrganizationId(),
				'ns',
				'n2',
				new List<Layout.Action> {
					new Layout.Action(
						Layout.ACTION_TYPE_SEND,
						Layout.ACTION_NAME_SEND)
				});

			Test.startTest();
			List<Layout> result = MetadataService.updateLayouts(
				Contact.getSObjectType(),
				new List<Layout> { l1, l2 });
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
		}
	}

	@IsTest
	static void test_fixActionName() {
		System.assertEquals(null, MetadataService.fixActionName(null, null));
		System.assertEquals('test', MetadataService.fixActionName(null, 'test'));
		System.assertEquals('test', MetadataService.fixActionName(Lead.getSObjectType(), 'test'));
		System.assertEquals('test', MetadataService.fixActionName(Lead.getSObjectType(), 'Lead-test'));
		System.assertEquals('test', MetadataService.fixActionName(Envelope__c.getSObjectType(), 'test'));
		System.assertEquals('test', MetadataService.fixActionName(Envelope__c.getSObjectType(), Application.namespacePrefix + 'Envelope__test'));
	}

	@IsTest
	static void test_getPossibleActionNames() {
		System.assertEquals(new Set<String>(), MetadataService.getPossibleActionNames(null, null));
		System.assertEquals(new Set<String>(), MetadataService.getPossibleActionNames(null, ''));
		System.assertEquals(new Set<String>(), MetadataService.getPossibleActionNames(null, '\t'));
		System.assertEquals(new Set<String> { 'test' }, MetadataService.getPossibleActionNames(null, 'test'));
		System.assertEquals(new Set<String> { 'test', 'Lead-test' }, MetadataService.getPossibleActionNames(Lead.getSObjectType(), 'test'));
		System.assertEquals(new Set<String> { 'test', Application.namespacePrefix + 'Envelope__c-test', Application.namespacePrefix + 'Envelope__test' },
			MetadataService.getPossibleActionNames(Envelope__c.getSObjectType(), 'test'));
	}
}
