@IsTest
public class DataSourceLookupControllerTest {

	@IsTest
	static void test_getDataSourceObjects_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			DataSourceLookupController.DataSourceConfiguration config = DataSourceLookupController.getDataSourceObjects();
			system.assert(config.commonObjects != null);
			system.assert(config.allOtherObjects != null);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getDataSourceObjects_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				DataSourceLookupController.getDataSourceObjects();
				throw new AssertException('Expected getDataSourceObjects to fail');
			} catch (AuraHandledException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}
}