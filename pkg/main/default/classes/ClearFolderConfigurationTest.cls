@IsTest
private class ClearFolderConfigurationTest {
    @IsTest
    static void test_clearFolderConfiguration_success() {
        System.runAs(UserMock.createDocuSignAdministrator()) {
            insert new List<AgreementConfiguration__c> {
                new AgreementConfiguration__c(FolderId__c = 'Folder A', SourceObject__c = 'Source A'),
                new AgreementConfiguration__c(FolderId__c = 'Folder B', SourceObject__c = 'Source B'),
                new AgreementConfiguration__c(FolderId__c = 'Folder C', SourceObject__c = 'Source C'),
                new AgreementConfiguration__c(FolderId__c = 'Folder D', SourceObject__c = 'Source D'),
                new AgreementConfiguration__c(FolderId__c = 'Folder E', SourceObject__c = 'Source E')
            };
            System.assertEquals(5, Collection.size([SELECT Id FROM AgreementConfiguration__c]));

            Test.startTest();
            Database.executeBatch(new ClearFolderConfiguration());
            Test.stopTest();

            // Verify all folder configuration records have been cleared
            System.assertEquals(0, Collection.size([SELECT Id FROM AgreementConfiguration__c]));
        }
    }    
}

